import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import '../../../models/couple_model.dart';
import '../../../widgets/glass_card.dart';

class MissingMeterCard extends StatelessWidget {
  final MissingMeter? meter;
  final String myName;
  final String partnerName;
  final bool isUser1;

  const MissingMeterCard({
    super.key,
    this.meter,
    required this.myName,
    required this.partnerName,
    required this.isUser1,
  });

  @override
  Widget build(BuildContext context) {
    if (meter == null) return const SizedBox.shrink();

    final myScore = isUser1 ? meter!.user1Score : meter!.user2Score;
    final partnerScore = isUser1 ? meter!.user2Score : meter!.user1Score;
    final total = myScore + partnerScore;
    final myPercent = total > 0 ? myScore / total : 0.5;
    final partnerPercent = total > 0 ? partnerScore / total : 0.5;
    final whoMissesMore = myScore > partnerScore
        ? '$myName misses more 🥺'
        : myScore < partnerScore
            ? '$partnerName misses more 🥺'
            : "You miss each other equally 💕";

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text('💕', style: TextStyle(fontSize: 18)),
              SizedBox(width: 8),
              Text(
                'Missing Meter',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            whoMissesMore,
            style: const TextStyle(
              color: AppColors.accentPink,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),

          // Labels
          Row(
            children: [
              Text(
                myName,
                style: const TextStyle(
                  color: AppColors.accentPink,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                partnerName,
                style: const TextStyle(
                  color: AppColors.accentPurple,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Dual progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 14,
              child: Row(
                children: [
                  Expanded(
                    flex: (myPercent * 100).round().clamp(5, 95),
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFFFF6B9D), Color(0xFFFF3366)],
                        ),
                      ),
                    ),
                  ),
                  Container(width: 2, color: AppColors.bgPrimary),
                  Expanded(
                    flex: (partnerPercent * 100).round().clamp(5, 95),
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFFA855F7), Color(0xFFC084FC)],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),

          // Scores
          Row(
            children: [
              Text(
                '$myScore pts',
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                ),
              ),
              const Spacer(),
              Text(
                '$partnerScore pts',
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Based on profile visits, pings & wait time • Resets weekly',
            style: TextStyle(
              color: AppColors.textMuted.withValues(alpha: 0.5),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
