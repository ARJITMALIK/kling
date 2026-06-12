import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/couple_model.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/widget_service.dart';
import '../services/socket_service.dart';
import '../services/device_telemetry_service.dart';
import '../services/media_session_service.dart';
import 'auth_provider.dart';

// ─── Couple State ───

class CoupleState {
  final CoupleModel? couple;
  final UserModel? partner;
  final List<LocationAlert> locationAlerts;
  final bool isLoading;
  final String? error;

  const CoupleState({
    this.couple,
    this.partner,
    this.locationAlerts = const [],
    this.isLoading = false,
    this.error,
  });

  CoupleState copyWith({
    CoupleModel? couple,
    UserModel? partner,
    List<LocationAlert>? locationAlerts,
    bool? isLoading,
    String? error,
  }) {
    return CoupleState(
      couple: couple ?? this.couple,
      partner: partner ?? this.partner,
      locationAlerts: locationAlerts ?? this.locationAlerts,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class CoupleNotifier extends StateNotifier<CoupleState> {
  final ApiService _api;
  final SocketService _socket;
  final Ref _ref;
  final List<StreamSubscription> _subscriptions = [];
  DeviceTelemetryService? _telemetry;
  MediaSessionService? _media;

  CoupleNotifier(this._api, this._socket, this._ref) : super(const CoupleState()) {
    _listenToSocketEvents();
    _startTelemetry();
  }

  void _startTelemetry() {
    _telemetry = DeviceTelemetryService(
      _socket,
      onBatteryUpdate: (level) {
        final authNotifier = _ref.read(authProvider.notifier);
        if (authNotifier.state.user != null) {
          authNotifier.updateUser(authNotifier.state.user!.copyWith(battery: level));
        }
      },
      onLocationUpdate: (lat, lng) {
        final authNotifier = _ref.read(authProvider.notifier);
        if (authNotifier.state.user != null) {
          authNotifier.updateUser(authNotifier.state.user!.copyWith(lat: lat, lng: lng));
        }
      },
    );
    _media = MediaSessionService(_socket);
    _telemetry!.start();
    _media!.start();
  }

  void _listenToSocketEvents() {
    _subscriptions.add(_socket.moodEvents.listen((data) {
      print('CoupleNotifier: Partner mood event: $data');
      if (state.partner != null && data['from'] == state.partner!.uid) {
        state = state.copyWith(
          partner: state.partner!.copyWith(
            currentMood: MoodEntry(
              emoji: data['emoji'] as String,
              setAt: DateTime.fromMillisecondsSinceEpoch(
                data['at'] as int? ?? DateTime.now().millisecondsSinceEpoch,
              ),
            ),
          ),
        );
      }
    }));

    _subscriptions.add(_socket.batteryEvents.listen((data) {
      print('CoupleNotifier: Partner battery event: $data');
      if (state.partner != null && data['from'] == state.partner!.uid) {
        final updatedPartner = state.partner!.copyWith(
          battery: (data['level'] as num).toInt(),
        );
        state = state.copyWith(partner: updatedPartner);
        WidgetService.syncPartnerStats(updatedPartner);
      }
    }));

    _subscriptions.add(_socket.musicEvents.listen((data) {
      print('CoupleNotifier: Partner music event: $data');
      if (state.partner != null && data['from'] == state.partner!.uid) {
        final music = data['music'] as Map<String, dynamic>?;
        state = state.copyWith(
          partner: state.partner!.copyWith(
            currentSong: music != null && music['title'] != null && (music['title'] as String).isNotEmpty
                ? SongEntry(
                    title: music['title'] as String,
                    artist: (music['artist'] ?? '') as String,
                  )
                : null,
          ),
        );
      }
    }));

    _subscriptions.add(_socket.pingEvents.listen((data) {
      print('CoupleNotifier: Partner ping event: $data');
      loadCoupleData();
    }));

    _subscriptions.add(_socket.locationEvents.listen((data) {
      print('CoupleNotifier: Partner location event: $data');
      if (state.partner != null && data['from'] == state.partner!.uid) {
        final lat = (data['lat'] as num?)?.toDouble();
        final lng = (data['lng'] as num?)?.toDouble();
        if (lat != null && lng != null) {
          state = state.copyWith(
            partner: state.partner!.copyWith(lat: lat, lng: lng),
          );
        }
      }
    }));

    _subscriptions.add(_socket.gameStateEvents.listen((data) {
      print('CoupleNotifier: Game state updated: $data');
      loadCoupleData();
    }));

    _subscriptions.add(_socket.coupleEvents.listen((data) {
      print('CoupleNotifier: Couple event received: $data');
      loadCoupleData();
    }));
  }

  Future<void> loadCoupleData() async {
    state = state.copyWith(isLoading: true);
    try {
      final couple = await _api.getCouple();
      final partner = await _api.getPartnerStatus();
      final alerts = await _api.getLocationAlerts();
      state = CoupleState(
        couple: couple,
        partner: partner,
        locationAlerts: alerts,
      );
      
      // Sync native widgets
      await WidgetService.syncPartnerStats(partner);
      
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<String> generateInviteCode() async {
    return await _api.generateInviteCode();
  }

  Future<bool> joinCouple(String code) async {
    try {
      await _api.joinCouple(code);
      await loadCoupleData();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> cancelRequest() async {
    try {
      await _api.cancelRequest();
      await loadCoupleData();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<void> unpair() async {
    await _api.unpair();
    state = const CoupleState();
  }

  Future<void> updateMood(String emoji) async {
    _socket.sendMoodUpdate(emoji);
    final authNotifier = _ref.read(authProvider.notifier);
    if (authNotifier.state.user != null) {
      authNotifier.updateUser(
        authNotifier.state.user!.copyWith(
          currentMood: MoodEntry(emoji: emoji, setAt: DateTime.now()),
        ),
      );
    }
  }

  Future<void> updateSong(String title, String artist) async {
    _socket.sendMusicSync(title, artist);
    final authNotifier = _ref.read(authProvider.notifier);
    if (authNotifier.state.user != null) {
      authNotifier.updateUser(
        authNotifier.state.user!.copyWith(
          currentSong: SongEntry(title: title, artist: artist),
        ),
      );
    }
  }

  Future<void> sendGoodMorning() async {
    _socket.sendPing();
    await loadCoupleData();
  }

  Future<void> sendGoodNight() async {
    _socket.sendPing();
    await loadCoupleData();
  }

  Future<void> pingPartner() async {
    _socket.sendPing();
  }

  Future<void> requestBattle() async {
    await _api.requestBattle();
  }

  @override
  void dispose() {
    _telemetry?.stop();
    _media?.stop();
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    super.dispose();
  }
}

final coupleProvider = StateNotifierProvider<CoupleNotifier, CoupleState>((ref) {
  final api = ref.read(apiServiceProvider);
  final socket = ref.read(socketServiceProvider);
  return CoupleNotifier(api, socket, ref);
});
