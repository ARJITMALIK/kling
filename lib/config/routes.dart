import 'package:flutter/material.dart';

class AppRoutes {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String invite = '/invite';
  static const String pairSuccess = '/pair-success';
  static const String dashboard = '/dashboard';
  static const String matchmaking = '/matchmaking';
  static const String battle = '/battle';
  static const String battleResult = '/battle-result';
  static const String emoteGallery = '/emotes';
  static const String profile = '/profile';
}
