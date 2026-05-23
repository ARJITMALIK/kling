import 'dart:math';
import 'package:flutter/material.dart';
import '../config/constants.dart';

/// Base entity class for all game objects (troops, towers, projectiles).
abstract class Entity {
  double x;
  double y;
  int hp;
  final int maxHp;
  final int playerId; // 1 = player, 2 = opponent
  bool isDead = false;

  Entity({
    required this.x,
    required this.y,
    required this.hp,
    required this.maxHp,
    required this.playerId,
  });

  /// Update entity state each tick
  void update(double dt, List<Entity> allEntities);

  /// Draw entity on canvas
  void render(Canvas canvas, Size arenaSize);

  double distanceTo(Entity other) {
    return sqrt(pow(x - other.x, 2) + pow(y - other.y, 2));
  }

  bool get isPlayer => playerId == 1;
  bool get isOpponent => playerId == 2;
  bool isEnemy(Entity other) => playerId != other.playerId;
  double get hpPercent => maxHp > 0 ? hp / maxHp : 0;

  void takeDamage(int damage) {
    hp = (hp - damage).clamp(0, maxHp);
    if (hp <= 0) {
      isDead = true;
    }
  }

  /// Draw a health bar above the entity
  void drawHealthBar(Canvas canvas, double width, double yOffset) {
    final barWidth = width;
    final barHeight = 4.0;
    final barX = x - barWidth / 2;
    final barY = y - yOffset;

    // Background
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(barX, barY, barWidth, barHeight),
        const Radius.circular(2),
      ),
      Paint()..color = Colors.black.withValues(alpha: 0.5),
    );

    // Fill
    final fillWidth = barWidth * hpPercent;
    final fillColor = isPlayer
        ? const Color(0xFF4A90D9)
        : const Color(0xFFD94A4A);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(barX, barY, fillWidth, barHeight),
        const Radius.circular(2),
      ),
      Paint()..color = fillColor,
    );
  }
}
