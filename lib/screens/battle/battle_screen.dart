import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../../config/theme.dart';
import '../../config/constants.dart';
import '../../config/routes.dart';
import '../../models/game/troop_data.dart';
import '../../models/game/game_state.dart';
import '../../models/emote_model.dart';
import '../../game_engine/game_loop.dart';
import '../../game_engine/game_renderer.dart';
import 'widgets/card_tray.dart';
import 'widgets/bub_bar.dart';
import 'widgets/game_emote_overlay.dart';

class BattleScreen extends StatefulWidget {
  const BattleScreen({super.key});

  @override
  State<BattleScreen> createState() => _BattleScreenState();
}

class _BattleScreenState extends State<BattleScreen>
    with SingleTickerProviderStateMixin {
  late GameLoop _gameLoop;
  late Ticker _ticker;
  int? _selectedCardIndex;
  String? _activeEmote;
  double _emoteTimer = 0;
  bool _showEmotePanel = false;
  bool _gameStarted = false;
  int _countDown = 3;

  @override
  void initState() {
    super.initState();

    _gameLoop = GameLoop(
      myPlayerId: 'user-001',
      opponentId: 'partner-001',
      onGameEnd: _onGameEnd,
    );

    _ticker = createTicker(_onTick);

    // Countdown before start
    _startCountdown();
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
    _ticker.start();

    // Demo: spawn some enemy troops periodically
    _startDemoOpponent();
  }

  void _startDemoOpponent() async {
    // Simulate opponent deploying troops for demo purposes
    final troopTypes = [
      TroopType.cupidArcher,
      TroopType.heartbreakHorde,
      TroopType.loveKnight,
      TroopType.butterflySwarm,
      TroopType.roseBomber,
    ];
    int index = 0;

    while (mounted && _gameLoop.status != GameStatus.finished) {
      await Future.delayed(Duration(seconds: 5 + (index % 3)));
      if (!mounted || _gameLoop.status == GameStatus.finished) break;

      final type = troopTypes[index % troopTypes.length];
      final data = TroopData.get(type);

      if (_gameLoop.enemyBub >= data.bubCost) {
        _gameLoop.enemyBub -= data.bubCost;
        // Deploy on enemy's half (y 60-240 in logical coords)
        final x = 80.0 + (index % 3) * 70.0;
        final y = 80.0 + (index % 2) * 60.0;
        _gameLoop.handleOpponentDeploy(type, x, GameConstants.arenaHeight - y);
      }
      index++;
    }
  }

  void _onTick(Duration elapsed) {
    setState(() {
      _gameLoop.update(1 / 60);

      // Emote timer
      if (_activeEmote != null) {
        _emoteTimer -= 1 / 60;
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

    // Convert screen coordinates to game coordinates
    final arenaHeight = constraints.maxHeight;
    final arenaWidth = constraints.maxWidth;

    final gameX = (details.localPosition.dx / arenaWidth) * GameConstants.arenaWidth;
    final gameY = (details.localPosition.dy / arenaHeight) * GameConstants.arenaHeight;

    final success = _gameLoop.deployCard(_selectedCardIndex!, gameX, gameY);
    if (success) {
      setState(() => _selectedCardIndex = null);
    }
  }

  void _onEmoteTap(String emoteId) {
    setState(() {
      _activeEmote = emoteId;
      _emoteTimer = 2.0;
      _showEmotePanel = false;
    });
  }

  @override
  void dispose() {
    _ticker.dispose();
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
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Poornima 💕',
                style: TextStyle(
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
