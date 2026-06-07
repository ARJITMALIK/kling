enum GameStatus { waiting, active, overtime, finished }

enum GameResult { win, lose, draw }

class GameStateModel {
  final String gameId;
  final String player1Id;
  final String player2Id;
  final GameStatus status;
  final int elapsedMs; // Time since game start
  final GameResult? result;
  final String? winnerId;
  final int player1TowersDestroyed;
  final int player2TowersDestroyed;

  const GameStateModel({
    required this.gameId,
    required this.player1Id,
    required this.player2Id,
    required this.status,
    this.elapsedMs = 0,
    this.result,
    this.winnerId,
    this.player1TowersDestroyed = 0,
    this.player2TowersDestroyed = 0,
  });

  factory GameStateModel.fromJson(Map<String, dynamic> json) {
    if (json.containsKey('matchId') || json.containsKey('user1')) {
      // Backend GameState structure format
      final user1 = json['user1'] as Map<String, dynamic>?;
      final user2 = json['user2'] as Map<String, dynamic>?;
      final finished = (json['finished'] as bool?) ?? false;
      final winnerId = json['winnerId'] as String?;

      return GameStateModel(
        gameId: (json['matchId'] ?? '') as String,
        player1Id: (user1?['id'] ?? '') as String,
        player2Id: (user2?['id'] ?? '') as String,
        status: finished ? GameStatus.finished : GameStatus.active,
        elapsedMs: json['startedAt'] != null 
            ? DateTime.now().millisecondsSinceEpoch - (json['startedAt'] as int)
            : 0,
        result: finished 
            ? (winnerId == null 
                ? GameResult.draw 
                : (winnerId == user1?['id'] ? GameResult.win : GameResult.lose))
            : null,
        winnerId: winnerId,
        player1TowersDestroyed: ((user2?['princessHp'] ?? 2500) as num) <= 0 ? 1 : 0,
        player2TowersDestroyed: ((user1?['princessHp'] ?? 2500) as num) <= 0 ? 1 : 0,
      );
    }

    return GameStateModel(
      gameId: json['gameId'] as String,
      player1Id: json['player1Id'] as String,
      player2Id: json['player2Id'] as String,
      status: GameStatus.values.byName(json['status'] as String),
      elapsedMs: json['elapsedMs'] as int? ?? 0,
      result: json['result'] != null
          ? GameResult.values.byName(json['result'] as String)
          : null,
      winnerId: json['winnerId'] as String?,
      player1TowersDestroyed: json['player1TowersDestroyed'] as int? ?? 0,
      player2TowersDestroyed: json['player2TowersDestroyed'] as int? ?? 0,
    );
  }

  factory GameStateModel.fromBackendJson(Map<String, dynamic> json, String myUserId) {
    final user1 = json['user1'] as Map<String, dynamic>?;
    final user2 = json['user2'] as Map<String, dynamic>?;

    final isUser1Me = user1?['id'] == myUserId;
    final finished = (json['finished'] as bool?) ?? false;
    final winnerId = json['winnerId'] as String?;

    GameResult? result;
    if (finished) {
      if (winnerId == null) {
        result = GameResult.draw;
      } else if (winnerId == myUserId) {
        result = GameResult.win;
      } else {
        result = GameResult.lose;
      }
    }

    // Calculate destroyed towers based on princessHp and kingHp (TOWER_HP: Princess=2500, King=4000)
    final opponent = isUser1Me ? user2 : user1;
    final me = isUser1Me ? user1 : user2;

    final opponentPrincessHp = (opponent?['princessHp'] ?? 2500) as num;
    final opponentKingHp = (opponent?['kingHp'] ?? 4000) as num;
    final mePrincessHp = (me?['princessHp'] ?? 2500) as num;
    final meKingHp = (me?['kingHp'] ?? 4000) as num;

    int enemyDestroyed = 0;
    if (opponentPrincessHp <= 0) enemyDestroyed++;
    if (opponentKingHp <= 0) enemyDestroyed++;

    int playerDestroyed = 0;
    if (mePrincessHp <= 0) playerDestroyed++;
    if (meKingHp <= 0) playerDestroyed++;

    return GameStateModel(
      gameId: (json['matchId'] ?? json['gameId'] ?? '') as String,
      player1Id: (user1?['id'] ?? '') as String,
      player2Id: (user2?['id'] ?? '') as String,
      status: finished ? GameStatus.finished : GameStatus.active,
      elapsedMs: json['startedAt'] != null 
          ? DateTime.now().millisecondsSinceEpoch - (json['startedAt'] as int)
          : 0,
      result: result,
      winnerId: winnerId,
      player1TowersDestroyed: isUser1Me ? enemyDestroyed : playerDestroyed,
      player2TowersDestroyed: isUser1Me ? playerDestroyed : enemyDestroyed,
    );
  }

  Map<String, dynamic> toJson() => {
        'gameId': gameId,
        'player1Id': player1Id,
        'player2Id': player2Id,
        'status': status.name,
        'elapsedMs': elapsedMs,
        'result': result?.name,
        'winnerId': winnerId,
        'player1TowersDestroyed': player1TowersDestroyed,
        'player2TowersDestroyed': player2TowersDestroyed,
      };
}
