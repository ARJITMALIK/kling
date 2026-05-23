import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import '../../../models/user_model.dart';
import '../../../widgets/glass_card.dart';

class MoodCard extends StatelessWidget {
  final MoodEntry? myMood;
  final MoodEntry? partnerMood;
  final String partnerName;
  final ValueChanged<String> onMoodSelected;

  const MoodCard({
    super.key,
    this.myMood,
    this.partnerMood,
    required this.partnerName,
    required this.onMoodSelected,
  });

  static const List<String> moods = [
    '😊', '😢', '😡', '🥰', '😴',
    '🤔', '😤', '🥺', '😎', '🤗',
    '😂', '🫠', '😭', '🫣', '🥳',
  ];

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Text(
                '💭',
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(width: 8),
              const Text(
                'Mood',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (partnerMood != null) ...[
                Text(
                  '$partnerName is feeling ',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
                Text(
                  partnerMood!.emoji,
                  style: const TextStyle(fontSize: 18),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          if (myMood != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                'You\'re feeling ${myMood!.emoji}',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ),

          // Mood grid
          const Text(
            'How are you feeling?',
            style: TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: moods.map((emoji) {
              final isSelected = myMood?.emoji == emoji;
              return GestureDetector(
                onTap: () => onMoodSelected(emoji),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.accentPink.withValues(alpha: 0.2)
                        : Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: isSelected
                        ? Border.all(color: AppColors.accentPink, width: 1.5)
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      emoji,
                      style: TextStyle(fontSize: isSelected ? 24 : 20),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
