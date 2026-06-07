class CoupleModel {
  final String coupleId;
  final String user1Id;
  final String user2Id;
  final DateTime? firstMeetDate;
  final DateTime togetherSince;
  final CoupleStreaks streaks;
  final MissingMeter missingMeter;
  final GameStats gameStats;

  const CoupleModel({
    required this.coupleId,
    required this.user1Id,
    required this.user2Id,
    this.firstMeetDate,
    required this.togetherSince,
    required this.streaks,
    required this.missingMeter,
    required this.gameStats,
  });

  factory CoupleModel.fromJson(Map<String, dynamic> json) {
    return CoupleModel(
      coupleId: (json['coupleId'] ?? json['id'] ?? '') as String,
      user1Id: (json['user1Id'] ?? '') as String,
      user2Id: (json['user2Id'] ?? '') as String,
      firstMeetDate: json['firstMeetDate'] != null
          ? DateTime.parse(json['firstMeetDate'] as String)
          : null,
      togetherSince: json['togetherSince'] != null
          ? DateTime.parse(json['togetherSince'] as String)
          : DateTime.now(),
      streaks: json['streaks'] != null
          ? CoupleStreaks.fromJson(json['streaks'] as Map<String, dynamic>)
          : const CoupleStreaks(
              general: StreakData(count: 0, lastDate: ''),
              goodMorning: StreakData(count: 0, lastDate: ''),
              goodNight: StreakData(count: 0, lastDate: ''),
            ),
      missingMeter: json['missingMeter'] != null
          ? MissingMeter.fromJson(json['missingMeter'] as Map<String, dynamic>)
          : const MissingMeter(user1Score: 0, user2Score: 0, weekStart: ''),
      gameStats: json['gameStats'] != null
          ? GameStats.fromJson(json['gameStats'] as Map<String, dynamic>)
          : const GameStats(user1Wins: 0, user2Wins: 0, draws: 0),
    );
  }

  Map<String, dynamic> toJson() => {
        'coupleId': coupleId,
        'user1Id': user1Id,
        'user2Id': user2Id,
        'firstMeetDate': firstMeetDate?.toIso8601String(),
        'togetherSince': togetherSince.toIso8601String(),
        'streaks': streaks.toJson(),
        'missingMeter': missingMeter.toJson(),
        'gameStats': gameStats.toJson(),
      };
}

class CoupleStreaks {
  final StreakData general;
  final StreakData goodMorning;
  final StreakData goodNight;

  const CoupleStreaks({
    required this.general,
    required this.goodMorning,
    required this.goodNight,
  });

  factory CoupleStreaks.fromJson(Map<String, dynamic> json) {
    return CoupleStreaks(
      general: json['general'] != null
          ? StreakData.fromJson(json['general'] as Map<String, dynamic>)
          : const StreakData(count: 0, lastDate: ''),
      goodMorning: json['goodMorning'] != null
          ? StreakData.fromJson(json['goodMorning'] as Map<String, dynamic>)
          : const StreakData(count: 0, lastDate: ''),
      goodNight: json['goodNight'] != null
          ? StreakData.fromJson(json['goodNight'] as Map<String, dynamic>)
          : const StreakData(count: 0, lastDate: ''),
    );
  }

  Map<String, dynamic> toJson() => {
        'general': general.toJson(),
        'goodMorning': goodMorning.toJson(),
        'goodNight': goodNight.toJson(),
      };
}

class StreakData {
  final int count;
  final String lastDate; // YYYY-MM-DD
  final bool user1Done;
  final bool user2Done;

  const StreakData({
    required this.count,
    required this.lastDate,
    this.user1Done = false,
    this.user2Done = false,
  });

  factory StreakData.fromJson(Map<String, dynamic> json) {
    return StreakData(
      count: (json['count'] ?? 0) as int,
      lastDate: (json['lastDate'] ?? json['lastAt'] ?? '') as String,
      user1Done: json['user1Done'] as bool? ?? false,
      user2Done: json['user2Done'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'count': count,
        'lastDate': lastDate,
        'user1Done': user1Done,
        'user2Done': user2Done,
      };
}

class MissingMeter {
  final int user1Score;
  final int user2Score;
  final String weekStart; // YYYY-MM-DD

  const MissingMeter({
    required this.user1Score,
    required this.user2Score,
    required this.weekStart,
  });

  factory MissingMeter.fromJson(Map<String, dynamic> json) {
    return MissingMeter(
      user1Score: (json['user1Score'] ?? 0) as int,
      user2Score: (json['user2Score'] ?? 0) as int,
      weekStart: (json['weekStart'] ?? '') as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'user1Score': user1Score,
        'user2Score': user2Score,
        'weekStart': weekStart,
      };
}

class GameStats {
  final int user1Wins;
  final int user2Wins;
  final int draws;

  const GameStats({
    required this.user1Wins,
    required this.user2Wins,
    required this.draws,
  });

  int get totalGames => user1Wins + user2Wins + draws;

  factory GameStats.fromJson(Map<String, dynamic> json) {
    return GameStats(
      user1Wins: (json['user1Wins'] ?? 0) as int,
      user2Wins: (json['user2Wins'] ?? 0) as int,
      draws: (json['draws'] ?? 0) as int,
    );
  }

  Map<String, dynamic> toJson() => {
        'user1Wins': user1Wins,
        'user2Wins': user2Wins,
        'draws': draws,
      };
}
