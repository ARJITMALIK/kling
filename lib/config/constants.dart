import 'dart:io' show Platform;

class ApiConstants {
  /// The backend runs on port 3000 with global prefix `api/v1`.
  /// Android emulator maps `10.0.2.2` → host machine's `localhost`.
  /// iOS simulator can reach `localhost` directly.
  /// For physical devices, replace with your machine's LAN IP.
  static String get _host {
    return '192.168.1.34';
  }

  // static String get baseUrl => 'http://$_host:3000/api/v1';
  static String get baseUrl => 'https://purebred-scrambler-patronize.ngrok-free.dev/api/v1';

  /// Socket.IO connects over HTTP (it upgrades to WS internally).
  static String get socketUrl => 'https://purebred-scrambler-patronize.ngrok-free.dev';

  /// The Socket.IO namespace used by the live-gateway.
  static const String socketNamespace = '/live';
}

class GameConstants {
  // Timing
  static const int matchDurationSeconds = 180; // 3 minutes
  static const int overtimeDurationSeconds = 60; // 1 minute
  static const double gameTickRate = 60.0; // 60 fps

  // Bub (currency)
  static const int bubMax = 10;
  static const int bubStart = 5;
  static const double bubRegenPerSecond = 1.0;

  // Cards
  static const int handSize = 4;
  static const int deckSize = 8;

  // Arena dimensions (logical units)
  static const double arenaWidth = 300;
  static const double arenaHeight = 500;
  static const double bridgeY = 250; // Center line
  static const double bridgeWidth = 40;
  static const double bridgeGap = 80; // Gap between two bridges

  // Tower positions (logical units)
  static const double kingTowerY = 50; // Enemy king
  static const double playerKingTowerY = 450; // Player king
  static const double princessTowerOffset = 80; // X offset from center
  static const double princessTowerEnemyY = 90;
  static const double princessTowerPlayerY = 410;

  // Deploy zone
  static const double deployZoneMinY = 260; // Just past bridge
  static const double deployZoneMaxY = 440; // Before king tower
}

class AppConstants {
  static const String appName = 'Cling';
  static const int streakGoodMorningDeadlineHour = 12; // Before noon
  static const int streakGoodNightStartHour = 20; // After 8pm
  static const double locationAlertRadiusMeters = 200;
  static const int missingMeterResetDays = 7;

  // Missing meter scoring
  static const int profileVisitScore = 2;
  static const int pingScore = 1;
  static const int waitTimeScorePer10Min = 1;
  static const int appOpenScore = 1;
}
