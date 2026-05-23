import 'dart:math';
import 'package:flutter/material.dart';
import '../config/constants.dart';
import '../models/game/tower_data.dart';
import 'entity.dart';
import 'troop_entity.dart';

class TowerEntity extends Entity {
  final TowerData data;
  final TowerType type;
  bool isActivated;
  double _attackCooldown = 0;
  static const double attackInterval = 1.2;
  Entity? target;

  TowerEntity({
    required super.x,
    required super.y,
    required super.playerId,
    required this.data,
    required this.type,
    this.isActivated = true,
  }) : super(
          hp: data.hp,
          maxHp: data.hp,
        );

  /// King tower is only active after being hit or both princess towers destroyed
  bool get canAttack => isActivated && !isDead;

  @override
  void update(double dt, List<Entity> allEntities) {
    if (isDead) return;
    if (!canAttack) return;

    _attackCooldown = (_attackCooldown - dt).clamp(0, attackInterval);

    // Find nearest enemy troop
    _findTarget(allEntities);

    if (target != null && !target!.isDead && _attackCooldown <= 0) {
      final dist = distanceTo(target!);
      final range = data.range * 20; // Convert to pixels
      if (dist <= range) {
        target!.takeDamage(data.dps);
        _attackCooldown = attackInterval;
      }
    }
  }

  void _findTarget(List<Entity> allEntities) {
    if (target != null && target!.isDead) target = null;

    Entity? nearest;
    double nearestDist = double.infinity;
    for (final e in allEntities) {
      if (e.isDead || !isEnemy(e)) continue;
      if (e is! TroopEntity) continue; // Towers only attack troops
      final d = distanceTo(e);
      final range = data.range * 20;
      if (d <= range && d < nearestDist) {
        nearestDist = d;
        nearest = e;
      }
    }
    target = nearest;
  }

  @override
  void takeDamage(int damage) {
    super.takeDamage(damage);
    // King tower activates when hit
    if (type == TowerType.king && !isActivated) {
      isActivated = true;
    }
  }

  @override
  void render(Canvas canvas, Size arenaSize) {
    if (isDead) {
      _renderDestroyed(canvas, arenaSize);
      return;
    }

    final scaleX = arenaSize.width / GameConstants.arenaWidth;
    final scaleY = arenaSize.height / GameConstants.arenaHeight;
    final px = x * scaleX;
    final py = y * scaleY;

    final isKing = type == TowerType.king;
    final size = isKing ? 28.0 * scaleX : 22.0 * scaleX;

    // Tower base
    final basePaint = Paint()
      ..color = isPlayer
          ? const Color(0xFF2563EB).withValues(alpha: 0.8)
          : const Color(0xFFDC2626).withValues(alpha: 0.8);

    final rect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(px, py), width: size * 2, height: size * 2),
      Radius.circular(size * 0.3),
    );
    canvas.drawRRect(rect, basePaint);

    // Border glow
    final borderPaint = Paint()
      ..color = isPlayer
          ? const Color(0xFF60A5FA).withValues(alpha: 0.6)
          : const Color(0xFFF87171).withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRRect(rect, borderPaint);

    // Crown emoji for king, shield for princess
    final emoji = isKing ? '👑' : '🏰';
    final textPainter = TextPainter(
      text: TextSpan(
        text: emoji,
        style: TextStyle(fontSize: 18 * scaleX),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      Offset(px - textPainter.width / 2, py - textPainter.height / 2),
    );

    // HP text
    final hpPainter = TextPainter(
      text: TextSpan(
        text: '$hp',
        style: TextStyle(
          color: Colors.white,
          fontSize: 9 * scaleX,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    hpPainter.paint(
      canvas,
      Offset(px - hpPainter.width / 2, py + size + 4),
    );

    // Health bar
    drawHealthBar(canvas, size * 2, size + 2);

    // Attack indicator (line to target)
    if (target != null && !target!.isDead && _attackCooldown > attackInterval * 0.7) {
      final tx = target!.x * scaleX;
      final ty = target!.y * scaleY;
      final attackPaint = Paint()
        ..color = (isPlayer ? const Color(0xFF60A5FA) : const Color(0xFFF87171))
            .withValues(alpha: 0.4)
        ..strokeWidth = 1.5;
      canvas.drawLine(Offset(px, py), Offset(tx, ty), attackPaint);
    }
  }

  void _renderDestroyed(Canvas canvas, Size arenaSize) {
    final scaleX = arenaSize.width / GameConstants.arenaWidth;
    final scaleY = arenaSize.height / GameConstants.arenaHeight;
    final px = x * scaleX;
    final py = y * scaleY;
    final size = type == TowerType.king ? 28.0 * scaleX : 22.0 * scaleX;

    // Rubble
    final rubblePaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.3);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(px, py), width: size * 2, height: size * 1.2),
        Radius.circular(size * 0.2),
      ),
      rubblePaint,
    );

    final textPainter = TextPainter(
      text: TextSpan(
        text: '💥',
        style: TextStyle(fontSize: 14 * scaleX),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      Offset(px - textPainter.width / 2, py - textPainter.height / 2),
    );
  }

  // ─── Factory methods for creating towers at correct positions ───

  static List<TowerEntity> createPlayerTowers() {
    final center = GameConstants.arenaWidth / 2;
    return [
      TowerEntity(
        x: center,
        y: GameConstants.playerKingTowerY,
        playerId: 1,
        data: TowerData.kingTower,
        type: TowerType.king,
        isActivated: false, // King tower starts inactive
      ),
      TowerEntity(
        x: center - GameConstants.princessTowerOffset,
        y: GameConstants.princessTowerPlayerY,
        playerId: 1,
        data: TowerData.princessTower,
        type: TowerType.princess,
      ),
      TowerEntity(
        x: center + GameConstants.princessTowerOffset,
        y: GameConstants.princessTowerPlayerY,
        playerId: 1,
        data: TowerData.princessTower,
        type: TowerType.princess,
      ),
    ];
  }

  static List<TowerEntity> createEnemyTowers() {
    final center = GameConstants.arenaWidth / 2;
    return [
      TowerEntity(
        x: center,
        y: GameConstants.kingTowerY,
        playerId: 2,
        data: TowerData.kingTower,
        type: TowerType.king,
        isActivated: false,
      ),
      TowerEntity(
        x: center - GameConstants.princessTowerOffset,
        y: GameConstants.princessTowerEnemyY,
        playerId: 2,
        data: TowerData.princessTower,
        type: TowerType.princess,
      ),
      TowerEntity(
        x: center + GameConstants.princessTowerOffset,
        y: GameConstants.princessTowerEnemyY,
        playerId: 2,
        data: TowerData.princessTower,
        type: TowerType.princess,
      ),
    ];
  }
}
