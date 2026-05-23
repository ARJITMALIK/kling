import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/theme.dart';
import '../../../providers/couple_provider.dart';
import '../../../widgets/glass_card.dart';

class GmGnCard extends ConsumerWidget {
  const GmGnCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hour = DateTime.now().hour;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          // Good Morning
          Expanded(
            child: _ActionButton(
              emoji: '☀️',
              label: 'Good Morning',
              gradient: const LinearGradient(
                colors: [Color(0xFFFF8C42), Color(0xFFFFD700)],
              ),
              isActive: hour < 12,
              onTap: () {
                ref.read(coupleProvider.notifier).sendGoodMorning();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Good Morning sent! ☀️'),
                    backgroundColor: const Color(0xFFFF8C42),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 12),
          // Good Night
          Expanded(
            child: _ActionButton(
              emoji: '🌙',
              label: 'Good Night',
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFFC084FC)],
              ),
              isActive: hour >= 20,
              onTap: () {
                ref.read(coupleProvider.notifier).sendGoodNight();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Good Night sent! 🌙'),
                    backgroundColor: const Color(0xFF6366F1),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String emoji;
  final String label;
  final LinearGradient gradient;
  final bool isActive;
  final VoidCallback onTap;

  const _ActionButton({
    required this.emoji,
    required this.label,
    required this.gradient,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          gradient: isActive ? gradient : null,
          color: isActive ? null : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive
                ? Colors.transparent
                : Colors.white.withValues(alpha: 0.1),
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: gradient.colors.first.withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.white : AppColors.textSecondary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
