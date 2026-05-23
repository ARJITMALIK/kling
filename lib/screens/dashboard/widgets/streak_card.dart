import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import '../../../models/couple_model.dart';
import '../../../widgets/glass_card.dart';

class StreakCard extends StatelessWidget {
  final CoupleStreaks? streaks;

  const StreakCard({super.key, this.streaks});

  @override
  Widget build(BuildContext context) {
    if (streaks == null) return const SizedBox.shrink();

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text('🔥', style: TextStyle(fontSize: 18)),
              SizedBox(width: 8),
              Text(
                'Streaks',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _StreakItem(
                  emoji: '🔥',
                  label: 'General',
                  count: streaks!.general.count,
                  gradient: AppColors.gradientFire,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StreakItem(
                  emoji: '☀️',
                  label: 'Good AM',
                  count: streaks!.goodMorning.count,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF8C42), Color(0xFFFFD700)],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StreakItem(
                  emoji: '🌙',
                  label: 'Good PM',
                  count: streaks!.goodNight.count,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFFC084FC)],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StreakItem extends StatelessWidget {
  final String emoji;
  final String label;
  final int count;
  final LinearGradient gradient;

  const _StreakItem({
    required this.emoji,
    required this.label,
    required this.count,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.white.withValues(alpha: 0.04),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.06),
        ),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 8),
          ShaderMask(
            shaderCallback: (bounds) => gradient.createShader(bounds),
            child: Text(
              '$count',
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
