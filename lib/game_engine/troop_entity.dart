import 'dart:math';
import 'package:flutter/material.dart';
import '../config/constants.dart';
import '../models/game/troop_data.dart';
import 'entity.dart';
import 'tower_entity.dart';

class TroopEntity extends Entity {
  final TroopData data;
  Entity? target;
  double _attackCooldown = 0;
  static const double attackInterval = 1.0; // 1 second between attacks

  TroopEntity({
    required super.x,
    required super.y,
    required super.playerId,
    required this.data,
  }) : super(
          hp: data.hp,
          maxHp: data.hp,
        );

  @override
  void update(double dt, List<Entity> allEntities) {
    if (isDead) return;

    _attackCooldown = (_attackCooldown - dt).clamp(0, attackInterval);

    // Find target
    _findTarget(allEntities);

    if (target != null && !target!.isDead) {
      final dist = distanceTo(target!);
      final range = data.range * 20; // Convert to pixels

      if (dist <= range) {
        // Attack
        _attack(dt, allEntities);
      } else {
        // Move toward target
        _moveToward(target!, dt);
      }
    } else {
      // No target, move toward enemy side
      _moveForward(dt);
    }
  }

  void _findTarget(List<Entity> allEntities) {
    // If current target is dead, clear it
    if (target != null && target!.isDead) {
      target = null;
    }

    if (target != null) return;

    // Healer targets friendly troops
    if (data.targetType == TroopTargetType.healer) {
      Entity? nearest;
      double nearestDist = double.infinity;
      for (final e in allEntities) {
        if (e.isDead || e == this) continue;
        if (e.playerId == playerId && e is TroopEntity && e.hp < e.maxHp) {
          final d = distanceTo(e);
          if (d < nearestDist) {
            nearestDist = d;
            nearest = e;
          }
        }
      }
      target = nearest;
      return;
    }

    // Find nearest enemy
    Entity? nearest;
    double nearestDist = double.infinity;
    for (final e in allEntities) {
      if (e.isDead || !isEnemy(e)) continue;
      final d = distanceTo(e);
      if (d < nearestDist) {
        nearestDist = d;
        nearest = e;
      }
    }
    target = nearest;
  }

  void _moveToward(Entity target, double dt) {
    final dx = target.x - x;
    final dy = target.y - y;
    final dist = sqrt(dx * dx + dy * dy);
    if (dist < 1) return;

    final speed = data.speedValue * 30 * dt;
    x += (dx / dist) * speed;
    y += (dy / dist) * speed;
  }

  void _moveForward(double dt) {
    final speed = data.speedValue * 30 * dt;
    if (isPlayer) {
      y -= speed; // Move up toward enemy
    } else {
      y += speed; // Move down toward player
    }
  }

  void _attack(double dt, List<Entity> allEntities) {
    if (_attackCooldown > 0) return;
    _attackCooldown = attackInterval;

    if (data.targetType == TroopTargetType.healer) {
      // Heal
      if (target != null && !target!.isDead) {
        target!.hp = (target!.hp + 40).clamp(0, target!.maxHp);
      }
    } else if (data.targetType == TroopTargetType.splash) {
      // Area damage
      final range = data.range * 20;
      for (final e in allEntities) {
        if (e.isDead || !isEnemy(e)) continue;
        if (distanceTo(e) <= range) {
          e.takeDamage(data.dps);
        }
      }
    } else {
      // Single target damage
      target?.takeDamage(data.dps);
    }
  }

  @override
  void render(Canvas canvas, Size arenaSize) {
    if (isDead) return;

    final scaleX = arenaSize.width / GameConstants.arenaWidth;
    final scaleY = arenaSize.height / GameConstants.arenaHeight;
    final px = x * scaleX;
    final py = y * scaleY;
    final radius = 12.0 * scaleX;

    // Body circle
    final bodyPaint = Paint()..color = data.color.withValues(alpha: 0.9);
    canvas.drawCircle(Offset(px, py), radius, bodyPaint);

    // Border
    final borderPaint = Paint()
      ..color = isPlayer ? const Color(0xFF4A90D9) : const Color(0xFFD94A4A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(Offset(px, py), radius, borderPaint);

    // Emoji text
    final textPainter = TextPainter(
      text: TextSpan(
        text: data.emoji,
        style: TextStyle(fontSize: 14 * scaleX),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      Offset(px - textPainter.width / 2, py - textPainter.height / 2),
    );

    // Health bar
    drawHealthBar(canvas, 24 * scaleX, (radius + 6) * scaleY / scaleX);
  }
}
