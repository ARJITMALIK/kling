import 'package:flutter/material.dart';
import '../config/constants.dart';
import '../config/theme.dart';
import 'entity.dart';
import 'tower_entity.dart';
import 'troop_entity.dart';
import 'game_loop.dart';

/// Custom painter that renders the entire game arena.
class GameRenderer extends CustomPainter {
  final GameLoop gameLoop;

  GameRenderer({required this.gameLoop});

  @override
  void paint(Canvas canvas, Size size) {
    _drawArena(canvas, size);
    _drawBridges(canvas, size);
    _drawDeployZone(canvas, size);

    // Render all entities
    for (final tower in gameLoop.playerTowers) {
      tower.render(canvas, size);
    }
    for (final tower in gameLoop.enemyTowers) {
      tower.render(canvas, size);
    }
    for (final troop in gameLoop.troops) {
      troop.render(canvas, size);
    }
  }

  void _drawArena(Canvas canvas, Size size) {
    final scaleX = size.width / GameConstants.arenaWidth;
    final scaleY = size.height / GameConstants.arenaHeight;

    // Background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = const Color(0xFF1A3A2A),
    );

    // Enemy half (darker)
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height / 2),
      Paint()..color = const Color(0xFF2D1B1B).withValues(alpha: 0.4),
    );

    // Player half (slightly different shade)
    canvas.drawRect(
      Rect.fromLTWH(0, size.height / 2, size.width, size.height / 2),
      Paint()..color = const Color(0xFF1B2D1B).withValues(alpha: 0.4),
    );

    // Grid lines (subtle)
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.03)
      ..strokeWidth = 0.5;

    for (double x = 0; x < size.width; x += 30 * scaleX) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += 30 * scaleY) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Center divider
    final dividerPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..strokeWidth = 2;
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      dividerPaint,
    );
  }

  void _drawBridges(Canvas canvas, Size size) {
    final scaleX = size.width / GameConstants.arenaWidth;
    final scaleY = size.height / GameConstants.arenaHeight;
    final centerY = GameConstants.bridgeY * scaleY;
    final bridgeW = GameConstants.bridgeWidth * scaleX;
    final gap = GameConstants.bridgeGap * scaleX;

    final bridgePaint = Paint()..color = const Color(0xFF8B6914).withValues(alpha: 0.6);

    // Left bridge
    final leftBridgeX = (size.width / 2 - gap / 2 - bridgeW);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(leftBridgeX, centerY - 10 * scaleY, bridgeW, 20 * scaleY),
        Radius.circular(4 * scaleX),
      ),
      bridgePaint,
    );

    // Right bridge
    final rightBridgeX = (size.width / 2 + gap / 2);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(rightBridgeX, centerY - 10 * scaleY, bridgeW, 20 * scaleY),
        Radius.circular(4 * scaleX),
      ),
      bridgePaint,
    );

    // Water/river between bridges
    final riverPaint = Paint()
      ..color = const Color(0xFF2563EB).withValues(alpha: 0.2);
    canvas.drawRect(
      Rect.fromLTWH(
        leftBridgeX + bridgeW,
        centerY - 10 * scaleY,
        gap - bridgeW * 0 + (leftBridgeX - (size.width / 2 - gap / 2 - bridgeW)) + (rightBridgeX - leftBridgeX - bridgeW),
        20 * scaleY,
      ),
      riverPaint,
    );
  }

  void _drawDeployZone(Canvas canvas, Size size) {
    final scaleY = size.height / GameConstants.arenaHeight;
    final minY = GameConstants.deployZoneMinY * scaleY;
    final maxY = GameConstants.deployZoneMaxY * scaleY;

    // Subtle deploy zone highlight
    final zonePaint = Paint()
      ..color = const Color(0xFF4ADE80).withValues(alpha: 0.04);
    canvas.drawRect(
      Rect.fromLTWH(0, minY, size.width, maxY - minY),
      zonePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
