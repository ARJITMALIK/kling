import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import '../../../widgets/glass_card.dart';

class PartnerBatteryCard extends StatelessWidget {
  final int? batteryLevel;
  final String? batteryStatus;
  final int? myBatteryLevel;
  final String? myBatteryStatus;
  final VoidCallback? onTap;

  const PartnerBatteryCard({
    super.key,
    required this.batteryLevel,
    this.batteryStatus,
    this.myBatteryLevel,
    this.myBatteryStatus,
    this.onTap,
  });

  /// Returns null for negative values (iOS returns -1 when battery monitoring
  /// is unavailable). The card treats null as "unknown" and shows '--'.
  int? get _safePartnerLevel => (batteryLevel != null && batteryLevel! >= 0) ? batteryLevel : null;
  int? get _safeMyLevel => (myBatteryLevel != null && myBatteryLevel! >= 0) ? myBatteryLevel : null;

  Color get _batteryColor {
    if (batteryStatus == 'charging') return AppColors.accentGreen;
    final level = _safePartnerLevel ?? 50;
    if (level > 60) return AppColors.accentGreen;
    if (level > 20) return AppColors.accentOrange;
    return AppColors.accentRed;
  }

  IconData get _batteryIcon {
    if (batteryStatus == 'charging') return Icons.battery_charging_full;
    final level = _safePartnerLevel ?? 50;
    if (level > 80) return Icons.battery_full;
    if (level > 60) return Icons.battery_5_bar;
    if (level > 40) return Icons.battery_4_bar;
    if (level > 20) return Icons.battery_2_bar;
    return Icons.battery_1_bar;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
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
              const Spacer(),
              if (_safeMyLevel != null)
                Text(
                  'You: $_safeMyLevel%${myBatteryStatus == 'charging' ? '⚡' : ''}',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                _safePartnerLevel != null ? '$_safePartnerLevel%' : '--',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: _batteryColor,
                ),
              ),
              if (batteryStatus == 'charging') ...[
                const SizedBox(width: 4),
                const Icon(Icons.bolt, color: AppColors.accentGreen, size: 20),
              ],
            ],
          ),
          const SizedBox(height: 8),
          // Battery bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (_safePartnerLevel ?? 0) / 100,
              backgroundColor: Colors.white.withValues(alpha: 0.08),
              color: _batteryColor,
              minHeight: 6,
            ),
          ),
          if (batteryStatus != null && batteryStatus != 'unknown') ...[
            const SizedBox(height: 6),
            Text(
              batteryStatus == 'charging'
                  ? 'Charging'
                  : batteryStatus == 'full'
                      ? 'Fully Charged'
                      : 'Discharging',
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    ),
    );
  }
}
