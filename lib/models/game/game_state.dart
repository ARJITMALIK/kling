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
