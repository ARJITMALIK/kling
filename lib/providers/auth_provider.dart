import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:geolocator/geolocator.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/real_api_service.dart';
import '../services/socket_service.dart';

// ─── Service Providers ───

final apiServiceProvider = Provider<ApiService>((ref) {
  return RealApiService();
});

final socketServiceProvider = Provider<SocketService>((ref) {
  final service = SocketService();
  ref.onDispose(() => service.dispose());
  return service;
});

// ─── Auth State ───

enum AuthStatus { loading, authenticated, unauthenticated }

class AuthState {
  final AuthStatus status;
  final UserModel? user;
  final String? error;

  const AuthState({
    this.status = AuthStatus.loading,
    this.user,
    this.error,
  });

  AuthState copyWith({AuthStatus? status, UserModel? user, String? error}) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      error: error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final ApiService _api;
  final SocketService _socket;

  AuthNotifier(this._api, this._socket) : super(const AuthState()) {
    // Proactively check auth on initialization
    checkAuth();
  }

  void _connectSocket() {
    if (_api is RealApiService) {
      final token = _api.accessToken;
      if (token != null && token.isNotEmpty) {
        _socket.setAuthToken(token);
        _socket.connectLive();
        _seedOwnTelemetry();
      }
    }
  }

  /// Reads the device battery + GPS once and updates the user model so the
  /// DistanceCard and BatteryCard have an initial value to show.
  Future<void> _seedOwnTelemetry() async {
    try {
      final level = await Battery().batteryLevel;
      if (state.user != null) {
        state = state.copyWith(user: state.user!.copyWith(battery: level));
      }
    } catch (_) {}

    try {
      final permission = await Geolocator.checkPermission();
      if (permission != LocationPermission.denied &&
          permission != LocationPermission.deniedForever) {
        final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
            timeLimit: Duration(seconds: 10),
          ),
        );
        if (state.user != null) {
          state = state.copyWith(
            user: state.user!.copyWith(lat: pos.latitude, lng: pos.longitude),
          );
        }
      }
    } catch (_) {}
  }

  Future<void> checkAuth() async {
    try {
      final user = await _api.getMe();
      state = AuthState(status: AuthStatus.authenticated, user: user);
      _connectSocket();
    } catch (_) {
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading, error: null);
    try {
      final user = await _api.login(email, password);
      state = AuthState(status: AuthStatus.authenticated, user: user);
      _connectSocket();
      return true;
    } catch (e) {
      state = AuthState(
        status: AuthStatus.unauthenticated,
        error: e.toString(),
      );
      return false;
    }
  }

  Future<bool> register(String email, String password, String displayName) async {
    state = state.copyWith(status: AuthStatus.loading, error: null);
    try {
      final user = await _api.register(email, password, displayName);
      state = AuthState(status: AuthStatus.authenticated, user: user);
      _connectSocket();
      return true;
    } catch (e) {
      state = AuthState(
        status: AuthStatus.unauthenticated,
        error: e.toString(),
      );
      return false;
    }
  }

  Future<void> logout() async {
    _socket.disconnectLive();
    await _api.logout();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  void updateUser(UserModel user) {
    state = state.copyWith(user: user);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final api = ref.read(apiServiceProvider);
  final socket = ref.read(socketServiceProvider);
  return AuthNotifier(api, socket);
});
