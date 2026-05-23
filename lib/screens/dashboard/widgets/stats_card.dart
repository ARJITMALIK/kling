import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import '../../../models/couple_model.dart';
import '../../../widgets/glass_card.dart';

class StatsCard extends StatelessWidget {
  final CoupleModel? couple;
  final String myName;
  final String partnerName;

  const StatsCard({
    super.key,
    this.couple,
    required this.myName,
    required this.partnerName,
  });

  @override
  Widget build(BuildContext context) {
    if (couple == null) return const SizedBox.shrink();

    final now = DateTime.now();
    final together = couple!.togetherSince;
    final daysTogether = now.difference(together).inDays;
    final firstMeet = couple!.firstMeetDate;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text('📊', style: TextStyle(fontSize: 18)),
              SizedBox(width: 8),
              Text(
                'Our Story',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Stats grid
          Row(
            children: [
              Expanded(
                child: _StatItem(
                  icon: '💕',
                  label: 'Days Together',
                  value: '$daysTogether',
                  color: AppColors.accentPink,
                ),
              ),
              Container(
                width: 1,
                height: 50,
                color: Colors.white.withValues(alpha: 0.08),
              ),
              Expanded(
                child: _StatItem(
                  icon: '🎮',
                  label: 'Games Played',
                  value: '${couple!.gameStats.totalGames}',
                  color: AppColors.accentPurple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: Colors.white.withValues(alpha: 0.06)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatItem(
                  icon: '🏆',
                  label: '$myName Wins',
                  value: '${couple!.gameStats.user1Wins}',
                  color: AppColors.accentGold,
                ),
              ),
              Container(
                width: 1,
                height: 50,
                color: Colors.white.withValues(alpha: 0.08),
              ),
              Expanded(
                child: _StatItem(
                  icon: '🏆',
                  label: '$partnerName Wins',
                  value: '${couple!.gameStats.user2Wins}',
                  color: AppColors.accentBlue,
                ),
              ),
            ],
          ),

          if (firstMeet != null) ...[
            const SizedBox(height: 12),
            Divider(color: Colors.white.withValues(alpha: 0.06)),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('🫂', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Text(
                  'First met: ${_formatDate(firstMeet)}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

class _StatItem extends StatelessWidget {
  final String icon;
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(icon, style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 11,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
