class ApiConstants {
  static const String baseUrl = 'http://localhost:8080/api';
  static const String wsUrl = 'ws://localhost:8080/ws';
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
