import 'dart:math';
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
///
/// ## Sync Architecture
///
/// The game uses a **server-authoritative** model for anything that must be
/// identical on both clients:
///
/// * **Tower HP** – only ever written by [syncServerState]. Troops walk toward
///   towers and fight each other locally for visual effect, but they **never
///   deal damage to towers** in the local simulation. All tower damage comes
///   from the server via the `game:state_updated` socket event.
///
/// * **Match timer** – driven by the server `startedAt` epoch ms value that
///   arrives in the first [syncServerState] call. Both clients compute elapsed
///   time as `now − startedAt`, so they are always in sync regardless of when
///   the local ticker started.
///
/// * **Win / draw / lose** – exclusively determined by [syncServerState] using
///   the server's `finished` and `winnerId` fields.
///
/// * **Troop positions** – purely local / visual. Each client runs the same
///   physics given the same spawn events. Troops fight each other and die
///   locally (and are removed from the list), but their damage never touches
///   towers.
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

  // Seeding Random to guarantee identical swarm spawns on both screens
  late final Random random;

  // Server-provided match start epoch (ms). Set on first syncServerState call.
  int? _serverStartedAt;

  // Track which towers have already had their destruction reported to the
  // server, so the event fires exactly once per tower per match.
  final Set<TowerEntity> _destroyedReported = {};

  // Card management
  late DeckModel deck;
  late HandModel hand;

  // Player info
  final String myPlayerId;
  final String opponentId;

  // Callbacks
  final void Function(GameAction action)? onAction;
  final void Function(GameResult result, String? winnerId)? onGameEnd;
  final void Function(String targetPlayerId, String towerType)? onDestroyTower;

  GameLoop({
    required this.myPlayerId,
    required this.opponentId,
    this.onAction,
    this.onGameEnd,
    this.onDestroyTower,
  })  : playerTowers = TowerEntity.createPlayerTowers(),
        enemyTowers = TowerEntity.createEnemyTowers() {
    // Deterministic random seed derived from both player IDs
    final seed = myPlayerId.hashCode ^ opponentId.hashCode;
    random = Random(seed);

    deck = DeckModel.defaultDeck();
    final initialCards = List.generate(GameConstants.handSize, (_) => deck.drawNext());
    hand = HandModel(cards: initialCards, nextCard: deck.drawNext());
  }

  List<Entity> get allEntities => [
        ...playerTowers,
        ...enemyTowers,
        ...troops,
      ];

  // ─── Update ───────────────────────────────────────────────────────────────

  /// Advance the simulation by [dt] seconds (called from the Flutter Ticker).
  void update(double dt) {
    if (status == GameStatus.finished) return;

    // Timer: use server start time if available (authoritative); fall back to
    // local accumulation only until the first sync arrives.
    if (_serverStartedAt != null) {
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      elapsedSeconds = (nowMs - _serverStartedAt!) / 1000.0;
    } else {
      elapsedSeconds += dt;
    }

    // Regenerate bub locally (server bub is overwritten on each sync, but we
    // regen locally to keep the UI feeling responsive between syncs).
    bub = (bub + GameConstants.bubRegenPerSecond * dt)
        .clamp(0, GameConstants.bubMax.toDouble());
    enemyBub = (enemyBub + GameConstants.bubRegenPerSecond * dt)
        .clamp(0, GameConstants.bubMax.toDouble());

    // Update all entities
    final entities = allEntities;
    for (final entity in entities) {
      entity.update(dt, entities);
    }

    // Report individual tower deaths to the backend exactly once per tower.
    // Each princess tower death is reported separately; the king tower signals
    // match over.
    for (final t in playerTowers) {
      if (t.isDead && !_destroyedReported.contains(t)) {
        _destroyedReported.add(t);
        onDestroyTower?.call(myPlayerId, t.type == TowerType.king ? 'king' : 'princess');
      }
    }
    for (final t in enemyTowers) {
      if (t.isDead && !_destroyedReported.contains(t)) {
        _destroyedReported.add(t);
        onDestroyTower?.call(opponentId, t.type == TowerType.king ? 'king' : 'princess');
      }
    }

    // Remove dead troops so they disappear from the screen.
    troops.removeWhere((t) => t.isDead);

    // Keep king activation state up-to-date in local physics.
    _checkKingActivation(playerTowers);
    _checkKingActivation(enemyTowers);

    // NOTE: Win condition is NOT checked here. It is driven exclusively by the
    // server via [syncServerState] to keep both screens perfectly in sync.
  }

  // ─── Server State Sync ────────────────────────────────────────────────────

  /// Apply authoritative state received from the server via `game:state_updated`.
  ///
  /// Overwrites tower HPs and resolves game end. Called every time the socket
  /// emits `game:state_updated` (on every [deployTroop] REST call and once per
  /// second from the bub ticker).
  void syncServerState({
    required Map<String, dynamic> myData,
    required Map<String, dynamic> opponentData,
    required bool finished,
    required String? serverWinnerId,
    int? startedAt,
  }) {
    // Lock in the server start time on first call so the timer syncs.
    if (startedAt != null && _serverStartedAt == null) {
      _serverStartedAt = startedAt;
    }

    // ── Tower HP ──
    final myPrincessHp  = (myData['princessHp']  as num?)?.toInt() ?? 0;
    final myKingHp      = (myData['kingHp']      as num?)?.toInt() ?? 0;
    final oppPrincessHp = (opponentData['princessHp'] as num?)?.toInt() ?? 0;
    final oppKingHp     = (opponentData['kingHp']     as num?)?.toInt() ?? 0;

    _applyHpToTowers(playerTowers, myPrincessHp,  myKingHp);
    _applyHpToTowers(enemyTowers,  oppPrincessHp, oppKingHp);

    // ── Game end ──
    if (finished && status != GameStatus.finished) {
      status = GameStatus.finished;
      if (serverWinnerId == null) {
        result = GameResult.draw;
        winnerId = null;
      } else if (serverWinnerId == myPlayerId) {
        result = GameResult.win;
        winnerId = myPlayerId;
      } else {
        result = GameResult.lose;
        winnerId = serverWinnerId;
      }
      onGameEnd?.call(result!, winnerId);
    }
  }

  /// Maps the server's authoritative HP values onto local tower entities.
  ///
  /// ## One-directional ratchet rule
  ///
  /// The backend bub-ticker broadcasts every second with unchanged HP values
  /// (the server does NOT run troop physics, so it never records troop-attack
  /// damage between destroy-tower calls). If we overwrote local HP blindly on
  /// every tick, local troop damage would be erased each second.
  ///
  /// Rule: the server value is only applied when it is **lower** than the
  /// current local value — tower HP can only go down, never up.
  ///
  /// Exceptions (always applied unconditionally):
  ///  • hp == 0 / isDead — a confirmed server kill must be respected
  ///    immediately to keep game-end in sync on both screens.
  ///  • King activation — purely structural, not HP-related.
  void _applyHpToTowers(List<TowerEntity> towers, int serverPrincessHp, int serverKingHp) {
    const serverPrincessMax = 1000;
    const serverKingMax     = 2000;

    final princessRatio = (serverPrincessHp / serverPrincessMax).clamp(0.0, 1.0);
    final kingRatio     = (serverKingHp     / serverKingMax    ).clamp(0.0, 1.0);

    for (final t in towers) {
      if (t.type == TowerType.princess) {
        if (serverPrincessHp <= 0) {
          // Confirmed kill from server — apply unconditionally
          t.hp     = 0;
          t.isDead = true;
        } else {
          // Only apply if server says HP is lower than what we show locally
          final serverHp = (t.maxHp * princessRatio).round();
          if (serverHp < t.hp) t.hp = serverHp;
          // Never restore isDead once set by local physics
        }
      } else if (t.type == TowerType.king) {
        if (serverKingHp <= 0) {
          t.hp     = 0;
          t.isDead = true;
        } else {
          final serverHp = (t.maxHp * kingRatio).round();
          if (serverHp < t.hp) t.hp = serverHp;
        }
        if (!t.isDead && serverPrincessHp <= 0) {
          t.isActivated = true;
        }
      }
    }
    _checkKingActivation(towers);
  }

  // ─── Card / Troop Deployment ──────────────────────────────────────────────

  /// Deploy a card at logical position [x], [y].
  bool deployCard(int handIndex, double x, double y) {
    if (status == GameStatus.finished) return false;
    if (handIndex < 0 || handIndex >= hand.cards.length) return false;

    final card = hand.cards[handIndex];
    if (bub < card.bubCost) return false;

    if (y < GameConstants.deployZoneMinY || y > GameConstants.deployZoneMaxY) {
      return false;
    }

    bub -= card.bubCost;
    _spawnTroop(card.troopType, x, y, 1);

    hand.cards[handIndex] = hand.nextCard!;
    hand.nextCard = deck.drawNext();

    onAction?.call(DeployAction(
      playerId: myPlayerId,
      timestamp: (elapsedSeconds * 1000).round(),
      troopType: card.troopType,
      x: x,
      y: y,
    ));

    return true;
  }

  /// Handle opponent deployment received over WebSocket.
  ///
  /// Mirrors both axes because the partner sent coordinates in *their* frame
  /// where they are at the bottom of the screen.
  void handleOpponentDeploy(TroopType troopType, double x, double y) {
    final mirroredX = GameConstants.arenaWidth  - x;
    final mirroredY = GameConstants.arenaHeight - y;
    _spawnTroop(troopType, mirroredX, mirroredY, 2);
  }

  void _spawnTroop(TroopType type, double x, double y, int playerId) {
    final data = TroopData.get(type);

    if (data.isSpell) {
      _applySpell(data, x, y, playerId);
      return;
    }

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
    final radius = 40.0;
    for (final entity in allEntities) {
      if (entity.isDead) continue;
      // Spells only harm enemies; never damage towers directly
      if (entity is TowerEntity) continue;
      if (casterId == 1 && entity.isPlayer) continue;
      if (casterId == 2 && entity.isOpponent) continue;

      final dist = sqrt(pow(entity.x - x, 2) + pow(entity.y - y, 2));
      if (dist <= radius) {
        entity.takeDamage(spell.dps);
      }
    }
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  void _checkKingActivation(List<TowerEntity> towers) {
    final king = towers.firstWhere((t) => t.type == TowerType.king);
    if (king.isActivated) return;
    final princessTowers = towers.where((t) => t.type == TowerType.princess);
    if (princessTowers.every((t) => t.isDead)) {
      king.isActivated = true;
    }
  }

  int _countDestroyedTowers(List<TowerEntity> towers) =>
      towers.where((t) => t.isDead).length;

  /// Remaining match time as a `M:SS` string computed from the server clock.
  String get timeRemaining {
    final maxTime = (status == GameStatus.overtime
            ? GameConstants.matchDurationSeconds + GameConstants.overtimeDurationSeconds
            : GameConstants.matchDurationSeconds)
        .toDouble();
    final remaining = (maxTime - elapsedSeconds).clamp(0.0, maxTime);
    final minutes = (remaining / 60).floor();
    final seconds = (remaining % 60).floor();
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  int get playerTowersDestroyed => _countDestroyedTowers(enemyTowers);
  int get enemyTowersDestroyed  => _countDestroyedTowers(playerTowers);
}
