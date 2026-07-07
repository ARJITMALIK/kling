import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'config/theme.dart';
import 'config/routes.dart';
import 'providers/auth_provider.dart';
import 'providers/couple_provider.dart';
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

class ClingApp extends ConsumerStatefulWidget {
  const ClingApp({super.key});

  @override
  ConsumerState<ClingApp> createState() => _ClingAppState();
}

class _ClingAppState extends ConsumerState<ClingApp> {
  StreamSubscription? _inviteSubscription;
  StreamSubscription? _gameStartSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _listenToEvents();
    });
  }

  void _listenToEvents() {
    final socket = ref.read(socketServiceProvider);

    _inviteSubscription = socket.gameInvitedEvents.listen((data) {
      print('ClingApp: Received game invite: $data');
      final auth = ref.read(authProvider);
      final currentUserId = auth.user?.uid;
      final invitedBy = data['invitedBy'] as String?;
      final invitedByName = data['invitedByName'] as String? ?? 'Your partner';

      // Only show snackbar if it was invited by the partner (not ourselves)
      if (invitedBy != null && invitedBy != currentUserId) {
        _showInviteSnackbar(invitedByName);
      }
    });

    _gameStartSubscription = socket.gameStateEvents.listen((data) {
      print('ClingApp: Received game state update: $data');
      final finished = data['finished'] as bool? ?? false;
      if (!finished) {
        final navState = AppRoutes.navigatorKey.currentState;
        if (navState != null) {
          // Check if we are already on the battle route to avoid duplicate push
          if (!BattleScreen.isActive) {
            navState.pushNamedAndRemoveUntil(
              AppRoutes.battle,
              (route) => route.settings.name == AppRoutes.dashboard || route.isFirst,
              arguments: {'matchId': data['matchId']},
            );
          }
        }
      }
    });
  }

  void _showInviteSnackbar(String partnerName) {
    final context = AppRoutes.navigatorKey.currentContext;
    if (context == null) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Text('⚔️ ', style: TextStyle(fontSize: 20)),
            Expanded(
              child: Text(
                '$partnerName wants to battle!',
                style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
              ),
            ),
          ],
        ),
        action: SnackBarAction(
          label: 'JOIN',
          textColor: AppColors.accentPink,
          onPressed: () {
            ref.read(coupleProvider.notifier).acceptBattle();
          },
        ),
        duration: const Duration(seconds: 15),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.bgCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: AppColors.accentPink.withValues(alpha: 0.5), width: 1),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _inviteSubscription?.cancel();
    _gameStartSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cling',
      navigatorKey: AppRoutes.navigatorKey,
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
