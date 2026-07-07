import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/theme.dart';
import '../../providers/couple_provider.dart';
import '../../widgets/bottom_nav.dart';

class MatchmakingScreen extends ConsumerStatefulWidget {
  const MatchmakingScreen({super.key});

  @override
  ConsumerState<MatchmakingScreen> createState() => _MatchmakingScreenState();
}

class _MatchmakingScreenState extends ConsumerState<MatchmakingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _startBattle() {
    setState(() => _isSearching = true);
    ref.read(coupleProvider.notifier).requestBattle();
  }

  @override
  Widget build(BuildContext context) {
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
                  // Crossed swords
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, _) {
                      final scale = 1.0 + _pulseController.value * 0.1;
                      return Transform.scale(
                        scale: scale,
                        child: const Text('⚔️', style: TextStyle(fontSize: 72)),
                      );
                    },
                  ),
                  const SizedBox(height: 32),

                  ShaderMask(
                    shaderCallback: (bounds) =>
                        AppColors.gradientFire.createShader(bounds),
                    child: const Text(
                      'Battle Arena',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Challenge your partner to a battle!',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 48),

                  if (!_isSearching)
                    GestureDetector(
                      onTap: _startBattle,
                      child: Container(
                        width: 160,
                        height: 160,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: AppColors.gradientFire,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF3366).withValues(alpha: 0.4),
                              blurRadius: 40,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.sports_esports, color: Colors.white, size: 40),
                              SizedBox(height: 4),
                              Text(
                                'BATTLE',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else ...[
                    SizedBox(
                      width: 60,
                      height: 60,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        color: AppColors.accentPink,
                        backgroundColor: AppColors.accentPink.withValues(alpha: 0.2),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Waiting for partner...',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 16,
                      ),
                    ),
                  ],

                  const SizedBox(height: 48),
                  // Game info
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.bgCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.06),
                      ),
                    ),
                    child: const Column(
                      children: [
                        _InfoRow(icon: '⏱️', text: '3 min match + 1 min overtime'),
                        SizedBox(height: 8),
                        _InfoRow(icon: '💗', text: 'Bub: 1/sec, max 10'),
                        SizedBox(height: 8),
                        _InfoRow(icon: '🏰', text: 'Destroy their King Tower to win'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: const BottomNav(currentIndex: 1),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String icon;
  final String text;

  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(icon, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 10),
        Text(
          text,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

class AnimatedBuilder extends AnimatedWidget {
  final Widget Function(BuildContext context, Widget? child) builder;

  const AnimatedBuilder({
    super.key,
    required Animation<double> animation,
    required this.builder,
  }) : super(listenable: animation);

  @override
  Widget build(BuildContext context) {
    return builder(context, null);
  }
}
