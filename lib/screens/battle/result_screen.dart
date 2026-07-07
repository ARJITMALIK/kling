import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../config/routes.dart';
import '../../models/game/game_state.dart';
import '../../widgets/gradient_button.dart';

class ResultScreen extends StatefulWidget {
  const ResultScreen({super.key});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final result = args?['result'] as GameResult? ?? GameResult.draw;
    final playerTowers = args?['playerTowers'] as int? ?? 0;
    final enemyTowers = args?['enemyTowers'] as int? ?? 0;

    final isWin = result == GameResult.win;
    final isDraw = result == GameResult.draw;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.gradientBg),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Result icon
                  ScaleTransition(
                    scale: CurvedAnimation(
                      parent: _controller,
                      curve: Curves.elasticOut,
                    ),
                    child: Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        gradient: isWin
                            ? AppColors.gradientGold
                            : isDraw
                                ? AppColors.gradientBlue
                                : AppColors.gradientFire,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: (isWin
                                    ? AppColors.accentGold
                                    : isDraw
                                        ? AppColors.accentBlue
                                        : AppColors.accentRed)
                                .withValues(alpha: 0.4),
                            blurRadius: 50,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          isWin ? '🏆' : isDraw ? '🤝' : '💔',
                          style: const TextStyle(fontSize: 64),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  FadeTransition(
                    opacity: CurvedAnimation(
                      parent: _controller,
                      curve: const Interval(0.3, 0.8, curve: Curves.easeIn),
                    ),
                    child: Column(
                      children: [
                        ShaderMask(
                          shaderCallback: (bounds) => (isWin
                                  ? AppColors.gradientGold
                                  : isDraw
                                      ? AppColors.gradientBlue
                                      : AppColors.gradientFire)
                              .createShader(bounds),
                          child: Text(
                            isWin ? 'Victory!' : isDraw ? 'Draw!' : 'Defeat',
                            style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Score
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _ScoreColumn(
                              label: 'You',
                              towers: playerTowers,
                              color: AppColors.accentBlue,
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                              child: Text(
                                'vs',
                                style: TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            _ScoreColumn(
                              label: 'Poornima',
                              towers: enemyTowers,
                              color: AppColors.accentPink,
                            ),
                          ],
                        ),
                        const SizedBox(height: 40),

                        // Actions
                        GradientButton(
                          text: 'Rematch! ⚔️',
                          gradient: AppColors.gradientFire,
                          onPressed: () {
                            Navigator.of(context).pushReplacementNamed(AppRoutes.matchmaking);
                          },
                        ),
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: () {
                            Navigator.of(context).pushReplacementNamed(AppRoutes.dashboard);
                          },
                          child: const Padding(
                            padding: EdgeInsets.all(12),
                            child: Text(
                              'Back to Dashboard',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ScoreColumn extends StatelessWidget {
  final String label;
  final int towers;
  final Color color;

  const _ScoreColumn({
    required this.label,
    required this.towers,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Icon(
                i < towers ? Icons.star : Icons.star_border,
                color: i < towers ? AppColors.accentGold : AppColors.textMuted,
                size: 28,
              ),
            );
          }),
        ),
      ],
    );
  }
}
