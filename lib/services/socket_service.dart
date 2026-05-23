import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../config/constants.dart';
import '../models/game/game_action.dart';

/// WebSocket service for real-time game sync and dashboard updates.
class SocketService {
  WebSocketChannel? _gameChannel;
  WebSocketChannel? _liveChannel;
  String? _authToken;

  // Game event streams
  final _gameActionController = StreamController<GameAction>.broadcast();
  final _gameEventController = StreamController<Map<String, dynamic>>.broadcast();

  // Live dashboard event streams
  final _liveEventController = StreamController<Map<String, dynamic>>.broadcast();

  Stream<GameAction> get gameActions => _gameActionController.stream;
  Stream<Map<String, dynamic>> get gameEvents => _gameEventController.stream;
  Stream<Map<String, dynamic>> get liveEvents => _liveEventController.stream;

  void setAuthToken(String token) {
    _authToken = token;
  }

  // ─── Game WebSocket ───

  void connectToGame(String gameId) {
    _gameChannel?.sink.close();
    _gameChannel = WebSocketChannel.connect(
      Uri.parse('${ApiConstants.wsUrl}/game/$gameId?token=$_authToken'),
    );

    _gameChannel!.stream.listen(
      (data) {
        final json = jsonDecode(data as String) as Map<String, dynamic>;
        final type = json['type'] as String;

        if (type == 'opponent_deploy' || type == 'opponent_emote') {
          // Convert to GameAction
          final actionJson = Map<String, dynamic>.from(json);
          actionJson['type'] = type.replaceFirst('opponent_', '');
          _gameActionController.add(GameAction.fromJson(actionJson));
        } else {
          _gameEventController.add(json);
        }
      },
      onError: (error) {
        _gameEventController.addError(error);
      },
      onDone: () {
        _gameEventController.add({'type': 'disconnected'});
      },
    );
  }

  void sendGameAction(GameAction action) {
    _gameChannel?.sink.add(jsonEncode(action.toJson()));
  }

  void disconnectFromGame() {
    _gameChannel?.sink.close();
    _gameChannel = null;
  }

  // ─── Live Dashboard WebSocket ───

  void connectLive() {
    _liveChannel?.sink.close();
    _liveChannel = WebSocketChannel.connect(
      Uri.parse('${ApiConstants.wsUrl}/live?token=$_authToken'),
    );

    _liveChannel!.stream.listen(
      (data) {
        final json = jsonDecode(data as String) as Map<String, dynamic>;
        _liveEventController.add(json);
      },
      onError: (error) {
        _liveEventController.addError(error);
      },
    );
  }

  void disconnectLive() {
    _liveChannel?.sink.close();
    _liveChannel = null;
  }

  // ─── Cleanup ───

  void dispose() {
    disconnectFromGame();
    disconnectLive();
    _gameActionController.close();
    _gameEventController.close();
    _liveEventController.close();
  }
}
