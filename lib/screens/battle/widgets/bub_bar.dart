import 'package:flutter/material.dart';
import '../../../config/theme.dart';

class BubBar extends StatelessWidget {
  final double currentBub;
  final double maxBub;

  const BubBar({
    super.key,
    required this.currentBub,
    required this.maxBub,
  });

  @override
  Widget build(BuildContext context) {
    final percent = (currentBub / maxBub).clamp(0.0, 1.0);
    final displayBub = currentBub.floor();

    return Row(
      children: [
        // Bub icon
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFF6B9D), Color(0xFFFF3366)],
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Center(
            child: Text('💗', style: TextStyle(fontSize: 14)),
          ),
        ),
        const SizedBox(width: 8),

        // Progress bar
        Expanded(
          child: Stack(
            children: [
              // Background
              Container(
                height: 16,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              // Fill
              FractionallySizedBox(
                widthFactor: percent,
                child: Container(
                  height: 16,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF6B9D), Color(0xFFFF3366)],
                    ),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.bubColor.withValues(alpha: 0.4),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
              ),
              // Segments
              SizedBox(
                height: 16,
                child: Row(
                  children: List.generate(10, (i) {
                    return Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          border: i < 9
                              ? Border(
                                  right: BorderSide(
                                    color: AppColors.bgPrimary.withValues(alpha: 0.3),
                                    width: 1,
                                  ),
                                )
                              : null,
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),

        // Count
        SizedBox(
          width: 36,
          child: Text(
            '$displayBub/${maxBub.toInt()}',
            style: const TextStyle(
              color: AppColors.bubColor,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
