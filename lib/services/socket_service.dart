import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../config/constants.dart';
import '../models/game/game_action.dart';

/// Socket.IO service for real-time game sync and dashboard updates.
class SocketService {
  IO.Socket? _socket;
  String? _authToken;

  // Stream controllers
  final _liveEventsController = StreamController<Map<String, dynamic>>.broadcast();
  final _moodController = StreamController<Map<String, dynamic>>.broadcast();
  final _batteryController = StreamController<Map<String, dynamic>>.broadcast();
  final _musicController = StreamController<Map<String, dynamic>>.broadcast();
  final _pingController = StreamController<Map<String, dynamic>>.broadcast();
  final _emoteController = StreamController<Map<String, dynamic>>.broadcast();
  final _gameStateController = StreamController<Map<String, dynamic>>.broadcast();
  final _coupleEventsController = StreamController<Map<String, dynamic>>.broadcast();
  final _locationController = StreamController<Map<String, dynamic>>.broadcast();

  // Compatibility controllers for game channel
  final _gameActionController = StreamController<GameAction>.broadcast();
  final _gameEventController = StreamController<Map<String, dynamic>>.broadcast();

  // Public streams
  Stream<Map<String, dynamic>> get liveEvents => _liveEventsController.stream;
  Stream<Map<String, dynamic>> get moodEvents => _moodController.stream;
  Stream<Map<String, dynamic>> get batteryEvents => _batteryController.stream;
  Stream<Map<String, dynamic>> get musicEvents => _musicController.stream;
  Stream<Map<String, dynamic>> get pingEvents => _pingController.stream;
  Stream<Map<String, dynamic>> get emoteEvents => _emoteController.stream;
  Stream<Map<String, dynamic>> get gameStateEvents => _gameStateController.stream;
  Stream<Map<String, dynamic>> get coupleEvents => _coupleEventsController.stream;
  Stream<Map<String, dynamic>> get locationEvents => _locationController.stream;

  // Compatibility streams
  Stream<GameAction> get gameActions => _gameActionController.stream;
  Stream<Map<String, dynamic>> get gameEvents => _gameEventController.stream;

  bool get isConnected => _socket?.connected ?? false;

  void setAuthToken(String token) {
    _authToken = token;
  }

  // ─── Live Dashboard Socket.IO ───

  void connectLive() {
    if (_socket != null) {
      disconnectLive();
    }

    final token = _authToken;
    if (token == null || token.isEmpty) {
      print('Cannot connect to live socket: token is null or empty');
      return;
    }

    final url = '${ApiConstants.socketUrl}${ApiConstants.socketNamespace}';
    print('Connecting to live socket at: $url');

    _socket = IO.io(url, IO.OptionBuilder()
      .setTransports(['websocket'])
      .setAuth({'token': token})
      .enableAutoConnect()
      .setTimeout(10000)
      .setReconnectionDelayMax(5000)
      .build());

    _socket!.onConnect((_) {
      print('Connected to live socket namespace: ${ApiConstants.socketNamespace}');
      _liveEventsController.add({'type': 'connected'});
    });

    _socket!.onDisconnect((_) {
      print('Disconnected from live socket');
      _liveEventsController.add({'type': 'disconnected'});
    });

    _socket!.onConnectError((err) {
      print('Socket connection error: $err');
      _liveEventsController.add({'type': 'error', 'error': err});
    });

    // Mood update listener
    _socket!.on('mood:update', (data) {
      print('Socket mood:update received: $data');
      final map = Map<String, dynamic>.from(data as Map);
      _moodController.add(map);
      _liveEventsController.add({'type': 'mood', ...map});
    });

    // Battery sync listener
    _socket!.on('battery:sync', (data) {
      print('Socket battery:sync received: $data');
      final map = Map<String, dynamic>.from(data as Map);
      _batteryController.add(map);
      _liveEventsController.add({'type': 'battery', ...map});
    });

    // Music sync listener
    _socket!.on('music:sync', (data) {
      print('Socket music:sync received: $data');
      final map = Map<String, dynamic>.from(data as Map);
      _musicController.add(map);
      _liveEventsController.add({'type': 'music', ...map});
    });

    // Ping listener
    _socket!.on('ping', (data) {
      print('Socket ping received: $data');
      final map = Map<String, dynamic>.from(data as Map);
      _pingController.add(map);
      _liveEventsController.add({'type': 'ping', ...map});
    });

    // Emote listener
    _socket!.on('emote', (data) {
      print('Socket emote received: $data');
      final map = Map<String, dynamic>.from(data as Map);
      _emoteController.add(map);
      _liveEventsController.add({'type': 'emote', ...map});
    });

    // GPS updated listener — partner's location changed
    _socket!.on('gps:updated', (data) {
      print('Socket gps:updated received: $data');
      final map = Map<String, dynamic>.from(data as Map);
      _locationController.add(map);
      _liveEventsController.add({'type': 'location', ...map});
    });

    // Game state updated listener
    _socket!.on('game:state_updated', (data) {
      print('Socket game:state_updated received: $data');
      final map = Map<String, dynamic>.from(data as Map);
      _gameStateController.add(map);
      _gameEventController.add(map); // compatibility
      _liveEventsController.add({'type': 'game_state', ...map});
    });

    // Couple events listeners
    _socket!.on('couple:pending', (data) {
      print('Socket couple:pending received: $data');
      final map = Map<String, dynamic>.from(data as Map);
      _coupleEventsController.add({'type': 'pending', ...map});
    });

    _socket!.on('couple:linked', (data) {
      print('Socket couple:linked received: $data');
      final map = Map<String, dynamic>.from(data as Map);
      _coupleEventsController.add({'type': 'linked', ...map});
    });

    _socket!.on('couple:canceled', (data) {
      print('Socket couple:canceled received: $data');
      final map = Map<String, dynamic>.from(data as Map);
      _coupleEventsController.add({'type': 'canceled', ...map});
    });
  }

  // Emits
  void sendMoodUpdate(String emoji) {
    if (_socket != null && _socket!.connected) {
      _socket!.emit('mood:update', {'emoji': emoji});
    }
  }

  void sendBatterySync(int level) {
    if (_socket != null && _socket!.connected) {
      _socket!.emit('battery:sync', {'level': level});
    }
  }

  void sendMusicSync(String title, String? artist) {
    if (_socket != null && _socket!.connected) {
      _socket!.emit('music:sync', {'title': title, 'artist': artist ?? ''});
    }
  }

  void clearMusicSync() {
    if (_socket != null && _socket!.connected) {
      _socket!.emit('music:sync', {'title': '', 'artist': ''});
    }
  }

  void sendGpsUpdate(double lat, double lng) {
    if (_socket != null && _socket!.connected) {
      _socket!.emit('gps:update', {'lat': lat, 'lng': lng});
    }
  }

  void sendPing() {
    if (_socket != null && _socket!.connected) {
      _socket!.emit('ping');
    }
  }

  void sendEmote(String emoji) {
    if (_socket != null && _socket!.connected) {
      _socket!.emit('emote', {'emoji': emoji});
    }
  }

  void disconnectLive() {
    _socket?.disconnect();
    _socket?.close();
    _socket = null;
  }

  // ─── Game WebSocket Compatibility Stubs ───

  void connectToGame(String gameId) {
    // The backend uses the live namespace /live for game state sync.
    // This is a stub for backward compatibility.
    print('connectToGame stub called for gameId: $gameId');
  }

  void sendGameAction(GameAction action) {
    // Game actions are now sent via the REST deployTroop endpoint in RealApiService.
    // This is a stub for backward compatibility.
    print('sendGameAction stub called: ${action.toJson()}');
  }

  void disconnectFromGame() {
    // Compatibility stub.
    print('disconnectFromGame stub called');
  }

  // ─── Cleanup ───

  void dispose() {
    disconnectLive();
    _liveEventsController.close();
    _moodController.close();
    _batteryController.close();
    _musicController.close();
    _pingController.close();
    _emoteController.close();
    _gameStateController.close();
    _gameActionController.close();
    _gameEventController.close();
    _coupleEventsController.close();
    _locationController.close();
  }
}
