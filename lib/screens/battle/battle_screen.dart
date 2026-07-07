import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/theme.dart';
import '../../config/constants.dart';
import '../../config/routes.dart';
import '../../models/game/game_state.dart';
import '../../models/game/game_action.dart';
import '../../models/emote_model.dart';
import '../../game_engine/game_loop.dart';
import '../../game_engine/game_renderer.dart';
import '../../providers/auth_provider.dart';
import '../../providers/couple_provider.dart';
import 'widgets/card_tray.dart';
import 'widgets/bub_bar.dart';
import 'widgets/game_emote_overlay.dart';

class BattleScreen extends ConsumerStatefulWidget {
  const BattleScreen({super.key});

  static bool isActive = false;

  @override
  ConsumerState<BattleScreen> createState() => _BattleScreenState();
}

class _BattleScreenState extends ConsumerState<BattleScreen>
    with SingleTickerProviderStateMixin {
  late GameLoop _gameLoop;
  late Ticker _ticker;
  late String _myId;
  int? _selectedCardIndex;
  String? _activeEmote;
  double _emoteTimer = 0;
  bool _showEmotePanel = false;
  bool _gameStarted = false;
  int _countDown = 3;
  String? _matchId;
  StreamSubscription? _actionSubscription;
  StreamSubscription? _stateSubscription;

  @override
  void initState() {
    super.initState();
    BattleScreen.isActive = true;

    _myId = ref.read(authProvider).user?.uid ?? 'user-001';
    final partnerId = ref.read(coupleProvider).partner?.uid ?? 'partner-001';

    _gameLoop = GameLoop(
      myPlayerId: _myId,
      opponentId: partnerId,
      onAction: (action) {
        ref.read(socketServiceProvider).sendGameAction(action);
        if (action is DeployAction && _matchId != null) {
          ref.read(apiServiceProvider).deployTroop(_matchId!, action.troopType.name);
        }
      },
      onGameEnd: _onGameEnd,
      onDestroyTower: (targetPlayerId, towerType) {
        if (_matchId != null) {
          ref.read(apiServiceProvider).destroyTower(_matchId!, targetPlayerId, towerType);
        }
      },
    );

    _ticker = createTicker(_onTick);

    // ── Listen to peer game actions (troop deploys, emotes) ──
    _actionSubscription = ref.read(socketServiceProvider).gameActions.listen((action) {
      if (action.playerId != _myId) {
        if (action is DeployAction) {
          setState(() {
            _gameLoop.handleOpponentDeploy(action.troopType, action.x, action.y);
          });
        } else if (action is EmoteAction) {
          setState(() {
            _activeEmote = action.emoteId;
            _emoteTimer = 2.0;
          });
        }
      }
    });

    // ── Listen to server game state (authoritative HP + game end) ──
    _stateSubscription = ref.read(socketServiceProvider).gameStateEvents.listen((data) {
      if (!mounted) return;
      _applyServerState(data);
    });

    _startCountdown();
  }

  /// Applies the server-broadcast game state onto the local game loop.
  ///
  /// The server payload has `user1` and `user2` objects each with `id`,
  /// `princessHp`, `kingHp`. We map them to "my player" vs "opponent" by
  /// matching ids, then call [GameLoop.syncServerState] which overwrites tower
  /// HPs and drives victory/defeat if `finished == true`.
  void _applyServerState(Map<String, dynamic> data) {
    final user1 = data['user1'] as Map<String, dynamic>?;
    final user2 = data['user2'] as Map<String, dynamic>?;
    if (user1 == null || user2 == null) return;

    final finished = data['finished'] as bool? ?? false;
    final serverWinnerId = data['winnerId'] as String?;
    // startedAt is the server epoch ms — used to anchor the match timer
    final startedAt = (data['startedAt'] as num?)?.toInt();

    final Map<String, dynamic> myData;
    final Map<String, dynamic> opponentData;

    if (user1['id'] == _myId) {
      myData = user1;
      opponentData = user2;
    } else {
      myData = user2;
      opponentData = user1;
    }

    // Sync server Bub so our regen display matches
    final serverBub = (myData['bub'] as num?)?.toDouble();
    if (serverBub != null) _gameLoop.bub = serverBub.clamp(0, GameConstants.bubMax.toDouble());

    setState(() {
      _gameLoop.syncServerState(
        myData: myData,
        opponentData: opponentData,
        finished: finished,
        serverWinnerId: serverWinnerId,
        startedAt: startedAt,
      );
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    _matchId = args?['matchId'] as String?;
  }

  void _startCountdown() async {
    for (int i = 3; i > 0; i--) {
      if (!mounted) return;
      setState(() => _countDown = i);
      await Future.delayed(const Duration(seconds: 1));
    }
    if (!mounted) return;
    setState(() {
      _gameStarted = true;
      _countDown = 0;
    });
    _lastElapsed = Duration.zero;
    _ticker.start();
  }

  Duration _lastElapsed = Duration.zero;

  void _onTick(Duration elapsed) {
    // Compute true wall-clock delta between frames.
    // Cap at 50 ms to prevent a large dt spike when the app resumes from
    // background (which would teleport troops across the arena).
    final rawDt = (elapsed - _lastElapsed).inMicroseconds / 1000000.0;
    _lastElapsed = elapsed;
    final dt = rawDt.clamp(0.0, 0.05); // max 50 ms per frame

    setState(() {
      _gameLoop.update(dt);

      // Emote timer
      if (_activeEmote != null) {
        _emoteTimer -= dt;
        if (_emoteTimer <= 0) {
          _activeEmote = null;
        }
      }
    });
  }

  void _onGameEnd(GameResult result, String? winnerId) {
    _ticker.stop();
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed(
          AppRoutes.battleResult,
          arguments: {
            'result': result,
            'playerTowers': _gameLoop.playerTowersDestroyed,
            'enemyTowers': _gameLoop.enemyTowersDestroyed,
          },
        );
      }
    });
  }

  void _onArenaTap(TapDownDetails details, BoxConstraints constraints) {
    if (_selectedCardIndex == null) return;

    final arenaHeight = constraints.maxHeight;
    final arenaWidth = constraints.maxWidth;

    final gameX = (details.localPosition.dx / arenaWidth) * GameConstants.arenaWidth;
    final gameY = (details.localPosition.dy / arenaHeight) * GameConstants.arenaHeight;

    final success = _gameLoop.deployCard(_selectedCardIndex!, gameX, gameY);
    if (success) {
      setState(() => _selectedCardIndex = null);
    }
  }

  Future<void> _showSurrenderDialog() async {
    if (_gameLoop.status == GameStatus.finished) return;
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: AppColors.bgSecondary,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppColors.accentRed.withValues(alpha: 0.4),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.accentRed.withValues(alpha: 0.18),
                blurRadius: 32,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🏳️', style: TextStyle(fontSize: 40)),
              const SizedBox(height: 12),
              const Text(
                'Surrender?',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'You will accept defeat and the battle will end.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.55),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  // Cancel
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.of(ctx).pop(false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        decoration: BoxDecoration(
                          color: AppColors.bgCard,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.12),
                          ),
                        ),
                        child: const Center(
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Surrender
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.of(ctx).pop(true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.accentRed,
                              AppColors.accentRed.withValues(alpha: 0.75),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.accentRed.withValues(alpha: 0.35),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text(
                            'Surrender',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed == true && mounted) {
      if (_matchId != null) {
        ref.read(apiServiceProvider).surrenderBattle(_matchId!);
      }
      _ticker.stop();
      setState(() {
        _gameLoop.status = GameStatus.finished;
        _gameLoop.result = GameResult.lose;
        _gameLoop.winnerId = null;
      });
      // Brief pause so the defeat overlay shows before navigating
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        Navigator.of(context).pushReplacementNamed(
          AppRoutes.battleResult,
          arguments: {
            'result': GameResult.lose,
            'playerTowers': _gameLoop.playerTowersDestroyed,
            'enemyTowers': _gameLoop.enemyTowersDestroyed,
          },
        );
      }
    }
  }

  void _onEmoteTap(String emoteId) {
    final elapsed = _gameLoop.elapsedSeconds;
    final action = EmoteAction(
      playerId: _myId,
      timestamp: (elapsed * 1000).round(),
      emoteId: emoteId,
    );
    ref.read(socketServiceProvider).sendGameAction(action);

    setState(() {
      _activeEmote = emoteId;
      _emoteTimer = 2.0;
      _showEmotePanel = false;
    });
  }

  @override
  void dispose() {
    BattleScreen.isActive = false;
    _ticker.dispose();
    _actionSubscription?.cancel();
    _stateSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: AppColors.bgPrimary,
        child: SafeArea(
          child: Column(
            children: [
              // Top HUD - timer + opponent info
              _buildTopHud(),

              // Arena
              Expanded(
                child: Stack(
                  children: [
                    LayoutBuilder(
                      builder: (context, constraints) {
                        return GestureDetector(
                          onTapDown: (details) => _onArenaTap(details, constraints),
                          child: CustomPaint(
                            size: Size(constraints.maxWidth, constraints.maxHeight),
                            painter: GameRenderer(gameLoop: _gameLoop),
                          ),
                        );
                      },
                    ),

                    // Countdown overlay
                    if (!_gameStarted)
                      Center(
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: AppColors.bgPrimary.withValues(alpha: 0.8),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.accentPink,
                              width: 3,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              '$_countDown',
                              style: const TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.w900,
                                color: AppColors.accentPink,
                              ),
                            ),
                          ),
                        ),
                      ),

                    // Game over overlay
                    if (_gameLoop.status == GameStatus.finished)
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 40,
                            vertical: 20,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.bgPrimary.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppColors.accentGold,
                              width: 2,
                            ),
                          ),
                          child: Text(
                            _gameLoop.result == GameResult.win
                                ? '🏆 Victory!'
                                : _gameLoop.result == GameResult.lose
                                    ? '💔 Defeat'
                                    : '🤝 Draw',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              color: _gameLoop.result == GameResult.win
                                  ? AppColors.accentGold
                                  : _gameLoop.result == GameResult.lose
                                      ? AppColors.accentRed
                                      : AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ),

                    // Active emote display
                    if (_activeEmote != null)
                      Positioned(
                        bottom: 20,
                        right: 20,
                        child: GameEmoteOverlay(emoteId: _activeEmote!),
                      ),

                    // Emote panel
                    if (_showEmotePanel)
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: _buildEmotePanel(),
                      ),
                  ],
                ),
              ),

              // Bottom HUD - cards + bub
              _buildBottomHud(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopHud() {
    final partnerName = ref.watch(coupleProvider).partner?.displayName ?? 'Partner';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary.withValues(alpha: 0.9),
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withValues(alpha: 0.06),
          ),
        ),
      ),
      child: Row(
        children: [
          // Opponent info
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$partnerName 💕',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const Spacer(),
          // Timer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: _gameLoop.status == GameStatus.overtime
                  ? AppColors.accentRed.withValues(alpha: 0.2)
                  : AppColors.bgCard,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _gameLoop.status == GameStatus.overtime
                    ? AppColors.accentRed.withValues(alpha: 0.5)
                    : Colors.white.withValues(alpha: 0.1),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.timer,
                  size: 16,
                  color: _gameLoop.status == GameStatus.overtime
                      ? AppColors.accentRed
                      : AppColors.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  _gameLoop.timeRemaining,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: _gameLoop.status == GameStatus.overtime
                        ? AppColors.accentRed
                        : Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          // Score
          Text(
            '${_gameLoop.playerTowersDestroyed} - ${_gameLoop.enemyTowersDestroyed}',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
          // End Battle button (hidden once game is over)
          if (_gameLoop.status != GameStatus.finished) ...[
            const SizedBox(width: 10),
            GestureDetector(
              onTap: _showSurrenderDialog,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.accentRed.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(
                    color: AppColors.accentRed.withValues(alpha: 0.45),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.flag_outlined,
                      size: 13,
                      color: AppColors.accentRed,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'End Battle',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.accentRed,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBottomHud() {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary.withValues(alpha: 0.95),
        border: Border(
          top: BorderSide(
            color: Colors.white.withValues(alpha: 0.06),
          ),
        ),
      ),
      child: Column(
        children: [
          // Bub bar
          BubBar(
            currentBub: _gameLoop.bub,
            maxBub: GameConstants.bubMax.toDouble(),
          ),
          const SizedBox(height: 8),
          // Cards + emote button
          Row(
            children: [
              // Emote button
              GestureDetector(
                onTap: () => setState(() => _showEmotePanel = !_showEmotePanel),
                child: Container(
                  width: 44,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.bgCard,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  child: const Center(
                    child: Text('💬', style: TextStyle(fontSize: 22)),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              // Cards
              Expanded(
                child: CardTray(
                  hand: _gameLoop.hand,
                  currentBub: _gameLoop.bub,
                  selectedIndex: _selectedCardIndex,
                  nextCard: _gameLoop.hand.nextCard,
                  onCardTap: (index) {
                    setState(() {
                      if (_selectedCardIndex == index) {
                        _selectedCardIndex = null;
                      } else {
                        _selectedCardIndex = index;
                      }
                    });
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmotePanel() {
    final battleEmotes = AppEmotes.battleEmotes;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary.withValues(alpha: 0.95),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        border: Border(
          top: BorderSide(
            color: Colors.white.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: battleEmotes.map((emote) {
          return GestureDetector(
            onTap: () => _onEmoteTap(emote.id),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.bgCard,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
              child: Text(
                '${emote.emoji} ${emote.name}',
                style: const TextStyle(fontSize: 13),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
