import 'troop_data.dart';

/// Actions that are synced between players via WebSocket
abstract class GameAction {
  final String playerId;
  final int timestamp; // Milliseconds since game start

  const GameAction({required this.playerId, required this.timestamp});

  Map<String, dynamic> toJson();

  factory GameAction.fromJson(Map<String, dynamic> json) {
    switch (json['type'] as String) {
      case 'deploy':
        return DeployAction.fromJson(json);
      case 'emote':
        return EmoteAction.fromJson(json);
      default:
        throw ArgumentError('Unknown action type: ${json['type']}');
    }
  }
}

class DeployAction extends GameAction {
  final TroopType troopType;
  final double x;
  final double y;

  const DeployAction({
    required super.playerId,
    required super.timestamp,
    required this.troopType,
    required this.x,
    required this.y,
  });

  @override
  Map<String, dynamic> toJson() => {
        'type': 'deploy',
        'playerId': playerId,
        'timestamp': timestamp,
        'troopType': troopType.name,
        'x': x,
        'y': y,
      };

  factory DeployAction.fromJson(Map<String, dynamic> json) {
    return DeployAction(
      playerId: json['playerId'] as String,
      timestamp: json['timestamp'] as int,
      troopType: TroopType.values.byName(json['troopType'] as String),
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
    );
  }
}

class EmoteAction extends GameAction {
  final String emoteId;

  const EmoteAction({
    required super.playerId,
    required super.timestamp,
    required this.emoteId,
  });

  @override
  Map<String, dynamic> toJson() => {
        'type': 'emote',
        'playerId': playerId,
        'timestamp': timestamp,
        'emoteId': emoteId,
      };

  factory EmoteAction.fromJson(Map<String, dynamic> json) {
    return EmoteAction(
      playerId: json['playerId'] as String,
      timestamp: json['timestamp'] as int,
      emoteId: json['emoteId'] as String,
    );
  }
}
