import 'dart:async';
import 'package:battery_plus/battery_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'socket_service.dart';

/// Reads local device battery & GPS and pushes them over the live socket.
/// Call [start] once the socket is connected; call [stop] on logout/dispose.
class DeviceTelemetryService {
  final SocketService _socket;
  final Battery _battery = Battery();

  /// Optional callbacks so callers can keep their own state in sync.
  final void Function(int level)? onBatteryUpdate;
  final void Function(double lat, double lng)? onLocationUpdate;

  Timer? _batteryTimer;
  Timer? _gpsTimer;

  int? _lastSentBattery;

  DeviceTelemetryService(
    this._socket, {
    this.onBatteryUpdate,
    this.onLocationUpdate,
  });

  // ── Start ──────────────────────────────────────────────────────────────────

  Future<void> start() async {
    await _syncBattery();
    await _syncGps();

    // Resync battery every 2 minutes
    _batteryTimer = Timer.periodic(const Duration(minutes: 2), (_) => _syncBattery());
    // Resync GPS every 3 minutes
    _gpsTimer = Timer.periodic(const Duration(minutes: 3), (_) => _syncGps());
  }

  // ── Stop ───────────────────────────────────────────────────────────────────

  void stop() {
    _batteryTimer?.cancel();
    _gpsTimer?.cancel();
    _batteryTimer = null;
    _gpsTimer = null;
  }

  // ── Battery ────────────────────────────────────────────────────────────────

  Future<void> _syncBattery() async {
    try {
      final level = await _battery.batteryLevel;
      // Only send if changed by ≥ 3% to avoid spam
      if (_lastSentBattery == null || (level - _lastSentBattery!).abs() >= 3) {
        _socket.sendBatterySync(level);
        _lastSentBattery = level;
        onBatteryUpdate?.call(level);
      }
    } catch (_) {
      // Battery read can fail on some platforms — silently ignore
    }
  }

  // ── GPS ────────────────────────────────────────────────────────────────────

  Future<void> _syncGps() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 10),
        ),
      );
      _socket.sendGpsUpdate(position.latitude, position.longitude);
      onLocationUpdate?.call(position.latitude, position.longitude);
    } catch (_) {
      // GPS read can fail (no fix, timeout, etc.) — silently ignore
    }
  }
}
