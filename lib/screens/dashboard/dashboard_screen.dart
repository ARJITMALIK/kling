import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/couple_provider.dart';
import '../../widgets/bottom_nav.dart';
import 'widgets/partner_battery_card.dart';
import 'widgets/distance_card.dart';
import 'widgets/mood_card.dart';
import 'widgets/current_song_card.dart';
import 'widgets/location_alert_card.dart';
import 'widgets/stats_card.dart';
import 'widgets/streak_card.dart';
import 'widgets/gm_gn_card.dart';
import 'widgets/missing_meter_card.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await ref.read(coupleProvider.notifier).requestLocationPermissionAndSync();
      if (mounted) {
        ref.read(coupleProvider.notifier).loadCoupleData();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final couple = ref.watch(coupleProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.gradientBg),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hey ${auth.user?.displayName ?? ''} 💕',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          couple.partner != null
                              ? 'Connected with ${couple.partner!.displayName}'
                              : 'Your love hub',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    // Battle button
                    GestureDetector(
                      onTap: () => ref.read(coupleProvider.notifier).requestBattle(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          gradient: AppColors.gradientFire,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF3366).withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.sports_esports, color: Colors.white, size: 18),
                            SizedBox(width: 6),
                            Text(
                              'Battle',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Dashboard content
              Expanded(
                child: RefreshIndicator(
                  color: AppColors.accentPink,
                  onRefresh: () => ref.read(coupleProvider.notifier).loadCoupleData(),
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
                    children: [
                      // Good Morning / Good Night buttons
                      const GmGnCard(),

                      // Top row: Battery + Distance
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Row(
                          children: [
                            Expanded(
                              child: PartnerBatteryCard(
                                batteryLevel: couple.partner?.battery,
                                batteryStatus: couple.partner?.batteryStatus,
                                myBatteryLevel: auth.user?.battery,
                                myBatteryStatus: auth.user?.batteryStatus,
                                onTap: () {
                                  ref.read(coupleProvider.notifier).debugBatteryRead();
                                },
                              ),
                            ),
                            Expanded(
                              child: DistanceCard(
                                myLat: auth.user?.lat,
                                myLng: auth.user?.lng,
                                partnerLat: couple.partner?.lat,
                                partnerLng: couple.partner?.lng,
                                onTap: () {
                                  ref.read(coupleProvider.notifier).requestLocationPermissionAndSync();
                                },
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Mood
                      MoodCard(
                        myMood: auth.user?.currentMood,
                        partnerMood: couple.partner?.currentMood,
                        partnerName: couple.partner?.displayName ?? 'Partner',
                        onMoodSelected: (emoji) {
                          ref.read(coupleProvider.notifier).updateMood(emoji);
                        },
                      ),

                      // Current Song
                      CurrentSongCard(
                        mySong: auth.user?.currentSong,
                        partnerSong: couple.partner?.currentSong,
                        partnerName: couple.partner?.displayName ?? 'Partner',
                      ),

                      // Streaks
                      StreakCard(streaks: couple.couple?.streaks),

                      // Missing Meter
                      MissingMeterCard(
                        meter: couple.couple?.missingMeter,
                        myName: auth.user?.displayName ?? 'You',
                        partnerName: couple.partner?.displayName ?? 'Poornima',
                        isUser1: auth.user?.uid == couple.couple?.user1Id,
                      ),

                      // Stats
                      StatsCard(
                        couple: couple.couple,
                        myName: auth.user?.displayName ?? 'You',
                        partnerName: couple.partner?.displayName ?? 'Poornima',
                      ),

                      // Location Alerts
                      if (couple.locationAlerts.isNotEmpty)
                        ...couple.locationAlerts.map(
                          (alert) => LocationAlertCard(alert: alert),
                        ),

                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const BottomNav(currentIndex: 0),
    );
  }
}
