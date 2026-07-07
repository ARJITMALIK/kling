import 'dart:math';
import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import '../../../widgets/glass_card.dart';
import '../../../widgets/pulse_dot.dart';

class DistanceCard extends StatelessWidget {
  final double? myLat;
  final double? myLng;
  final double? partnerLat;
  final double? partnerLng;
  final VoidCallback? onTap;

  const DistanceCard({
    super.key,
    this.myLat,
    this.myLng,
    this.partnerLat,
    this.partnerLng,
    this.onTap,
  });

  double? get _distanceKm {
    if (myLat == null || myLng == null || partnerLat == null || partnerLng == null) {
      return null;
    }
    return _haversine(myLat!, myLng!, partnerLat!, partnerLng!);
  }

  String get _distanceText {
    final d = _distanceKm;
    if (d == null) return '--';
    if (d < 1) return '${(d * 1000).round()}m';
    if (d < 10) return '${d.toStringAsFixed(1)}km';
    return '${d.round()}km';
  }

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      margin: const EdgeInsets.all(6),
      padding: const EdgeInsets.all(16),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.near_me, color: AppColors.accentBlue, size: 18),
              const SizedBox(width: 6),
              const Text(
                'Distance',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              const PulseDot(color: AppColors.accentGreen, size: 6),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _distanceText,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppColors.accentBlue,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'away from you',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  /// Haversine formula for distance between two lat/lng points
  static double _haversine(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371.0; // Earth radius in km
    final dLat = _toRad(lat2 - lat1);
    final dLon = _toRad(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRad(lat1)) * cos(_toRad(lat2)) * sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  static double _toRad(double deg) => deg * pi / 180;
}
