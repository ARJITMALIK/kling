import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'config/theme.dart';
import 'config/routes.dart';
import 'screens/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/pairing/invite_screen.dart';
import 'screens/pairing/pair_success_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/battle/matchmaking_screen.dart';
import 'screens/battle/battle_screen.dart';
import 'screens/battle/result_screen.dart';
import 'screens/emotes/emote_gallery_screen.dart';
import 'screens/profile/profile_screen.dart';

class ClingApp extends StatelessWidget {
  const ClingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cling',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      initialRoute: AppRoutes.splash,
      routes: {
        AppRoutes.splash: (_) => const SplashScreen(),
        AppRoutes.login: (_) => const LoginScreen(),
        AppRoutes.register: (_) => const RegisterScreen(),
        AppRoutes.invite: (_) => const InviteScreen(),
        AppRoutes.pairSuccess: (_) => const PairSuccessScreen(),
        AppRoutes.dashboard: (_) => const DashboardScreen(),
        AppRoutes.matchmaking: (_) => const MatchmakingScreen(),
        AppRoutes.battle: (_) => const BattleScreen(),
        AppRoutes.battleResult: (_) => const ResultScreen(),
        AppRoutes.emoteGallery: (_) => const EmoteGalleryScreen(),
        AppRoutes.profile: (_) => const ProfileScreen(),
      },
    );
  }
}
