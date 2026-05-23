import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import '../../../widgets/glass_card.dart';

class PartnerBatteryCard extends StatelessWidget {
  final int batteryLevel;

  const PartnerBatteryCard({super.key, required this.batteryLevel});

  Color get _batteryColor {
    if (batteryLevel > 60) return AppColors.accentGreen;
    if (batteryLevel > 20) return AppColors.accentOrange;
    return AppColors.accentRed;
  }

  IconData get _batteryIcon {
    if (batteryLevel > 80) return Icons.battery_full;
    if (batteryLevel > 60) return Icons.battery_5_bar;
    if (batteryLevel > 40) return Icons.battery_4_bar;
    if (batteryLevel > 20) return Icons.battery_2_bar;
    return Icons.battery_1_bar;
  }

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      margin: const EdgeInsets.all(6),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_batteryIcon, color: _batteryColor, size: 20),
              const SizedBox(width: 6),
              const Text(
                'Battery',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '$batteryLevel%',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: _batteryColor,
            ),
          ),
          const SizedBox(height: 8),
          // Battery bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: batteryLevel / 100,
              backgroundColor: Colors.white.withValues(alpha: 0.08),
              color: _batteryColor,
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}
