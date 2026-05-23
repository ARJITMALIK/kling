import 'dart:math';
import 'package:flutter/material.dart';
import '../config/constants.dart';
import '../models/game/troop_data.dart';
import '../models/game/tower_data.dart';
import '../models/game/card_model.dart';
import '../models/game/game_state.dart';
import '../models/game/game_action.dart';
import 'entity.dart';
import 'troop_entity.dart';
import 'tower_entity.dart';

/// Core game loop managing all entities, timing, and game state.
class GameLoop {
  // Entities
  final List<TowerEntity> playerTowers;
  final List<TowerEntity> enemyTowers;
  final List<TroopEntity> troops = [];

  // Game state
  double elapsedSeconds = 0;
  double bub = GameConstants.bubStart.toDouble();
  double enemyBub = GameConstants.bubStart.toDouble();
  GameStatus status = GameStatus.active;
  GameResult? result;
  String? winnerId;

  // Card management
  late DeckModel deck;
  late HandModel hand;

  // Player info
  final String myPlayerId;
  final String opponentId;

  // Callbacks
  final void Function(GameAction action)? onAction;
  final void Function(GameResult result, String? winnerId)? onGameEnd;

  GameLoop({
    required this.myPlayerId,
    required this.opponentId,
    this.onAction,
    this.onGameEnd,
  })  : playerTowers = TowerEntity.createPlayerTowers(),
        enemyTowers = TowerEntity.createEnemyTowers() {
    // Initialize deck and hand
    deck = DeckModel.defaultDeck();
    final initialCards = List.generate(GameConstants.handSize, (_) => deck.drawNext());
    hand = HandModel(cards: initialCards, nextCard: deck.drawNext());
  }

  List<Entity> get allEntities => [
        ...playerTowers,
        ...enemyTowers,
        ...troops,
      ];

  /// Update game state by dt seconds
  void update(double dt) {
    if (status == GameStatus.finished) return;

    elapsedSeconds += dt;

    // Check time
    final maxTime = status == GameStatus.overtime
        ? GameConstants.matchDurationSeconds + GameConstants.overtimeDurationSeconds
        : GameConstants.matchDurationSeconds;

    if (elapsedSeconds >= maxTime.toDouble()) {
      if (status == GameStatus.active) {
        // Check if overtime needed
        final pDestroyed = _countDestroyedTowers(enemyTowers);
        final eDestroyed = _countDestroyedTowers(playerTowers);
        if (pDestroyed == eDestroyed) {
          status = GameStatus.overtime;
        } else {
          _endGame();
          return;
        }
      } else {
        _endGame();
        return;
      }
    }

    // Regenerate bub
    bub = (bub + GameConstants.bubRegenPerSecond * dt)
        .clamp(0, GameConstants.bubMax.toDouble());
    enemyBub = (enemyBub + GameConstants.bubRegenPerSecond * dt)
        .clamp(0, GameConstants.bubMax.toDouble());

    // Update all entities
    final entities = allEntities;
    for (final entity in entities) {
      entity.update(dt, entities);
    }

    // Remove dead troops
    troops.removeWhere((t) => t.isDead);

    // Check king tower activation (if both princess towers destroyed)
    _checkKingActivation(playerTowers);
    _checkKingActivation(enemyTowers);

    // Check win condition (king tower destroyed)
    final playerKing = playerTowers.firstWhere((t) => t.type == TowerType.king);
    final enemyKing = enemyTowers.firstWhere((t) => t.type == TowerType.king);

    if (playerKing.isDead) {
      result = GameResult.lose;
      winnerId = opponentId;
      status = GameStatus.finished;
      onGameEnd?.call(result!, winnerId);
    } else if (enemyKing.isDead) {
      result = GameResult.win;
      winnerId = myPlayerId;
      status = GameStatus.finished;
      onGameEnd?.call(result!, winnerId);
    }
  }

  /// Deploy a card at position (logical coordinates)
  bool deployCard(int handIndex, double x, double y) {
    if (status == GameStatus.finished) return false;
    if (handIndex < 0 || handIndex >= hand.cards.length) return false;

    final card = hand.cards[handIndex];
    if (bub < card.bubCost) return false;

    // Validate deploy zone (player's half only)
    if (y < GameConstants.deployZoneMinY || y > GameConstants.deployZoneMaxY) {
      return false;
    }

    // Spend bub
    bub -= card.bubCost;

    // Spawn troops
    _spawnTroop(card.troopType, x, y, 1);

    // Replace card in hand
    hand.cards[handIndex] = hand.nextCard!;
    hand.nextCard = deck.drawNext();

    // Send action
    onAction?.call(DeployAction(
      playerId: myPlayerId,
      timestamp: (elapsedSeconds * 1000).round(),
      troopType: card.troopType,
      x: x,
      y: y,
    ));

    return true;
  }

  /// Handle opponent deployment (from WebSocket)
  void handleOpponentDeploy(TroopType troopType, double x, double y) {
    // Mirror Y coordinate for opponent
    final mirroredY = GameConstants.arenaHeight - y;
    _spawnTroop(troopType, x, mirroredY, 2);
  }

  void _spawnTroop(TroopType type, double x, double y, int playerId) {
    final data = TroopData.get(type);

    if (data.isSpell) {
      // Instant spell effect (Arrow Rain)
      _applySpell(data, x, y, playerId);
      return;
    }

    // Spawn multiple units for swarm troops
    final random = Random();
    for (int i = 0; i < data.spawnCount; i++) {
      final offsetX = data.spawnCount > 1 ? (random.nextDouble() - 0.5) * 20 : 0.0;
      final offsetY = data.spawnCount > 1 ? (random.nextDouble() - 0.5) * 20 : 0.0;

      troops.add(TroopEntity(
        x: x + offsetX,
        y: y + offsetY,
        playerId: playerId,
        data: data,
      ));
    }
  }

  void _applySpell(TroopData spell, double x, double y, int casterId) {
    final radius = 40.0; // Spell area of effect
    for (final entity in allEntities) {
      if (entity.isDead) continue;
      if (casterId == 1 && entity.isPlayer) continue;
      if (casterId == 2 && entity.isOpponent) continue;

      final dist = sqrt(pow(entity.x - x, 2) + pow(entity.y - y, 2));
      if (dist <= radius) {
        entity.takeDamage(spell.dps);
      }
    }
  }

  void _checkKingActivation(List<TowerEntity> towers) {
    final king = towers.firstWhere((t) => t.type == TowerType.king);
    if (king.isActivated) return;

    final princessTowers = towers.where((t) => t.type == TowerType.princess);
    if (princessTowers.every((t) => t.isDead)) {
      king.isActivated = true;
    }
  }

  int _countDestroyedTowers(List<TowerEntity> towers) {
    return towers.where((t) => t.isDead).length;
  }

  void _endGame() {
    final pDestroyed = _countDestroyedTowers(enemyTowers);
    final eDestroyed = _countDestroyedTowers(playerTowers);

    if (pDestroyed > eDestroyed) {
      result = GameResult.win;
      winnerId = myPlayerId;
    } else if (eDestroyed > pDestroyed) {
      result = GameResult.lose;
      winnerId = opponentId;
    } else {
      result = GameResult.draw;
      winnerId = null;
    }

    status = GameStatus.finished;
    onGameEnd?.call(result!, winnerId);
  }

  /// Get remaining time as formatted string
  String get timeRemaining {
    final maxTime = status == GameStatus.overtime
        ? GameConstants.matchDurationSeconds + GameConstants.overtimeDurationSeconds
        : GameConstants.matchDurationSeconds;
    final remaining = (maxTime - elapsedSeconds).clamp(0, maxTime.toDouble());
    final minutes = (remaining / 60).floor();
    final seconds = (remaining % 60).floor();
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  int get playerTowersDestroyed => _countDestroyedTowers(enemyTowers);
  int get enemyTowersDestroyed => _countDestroyedTowers(playerTowers);
}
