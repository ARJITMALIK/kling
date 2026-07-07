import 'dart:async';
import 'dart:io' show Platform;
import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'socket_service.dart';

/// Reads local device battery & GPS and pushes them over the live socket.
/// Call [start] once the socket is connected; call [stop] on logout/dispose.
///
/// On iOS we use a custom native method channel (com.cling/battery) because
/// battery_plus throws UNAVAILABLE on some iOS versions before UIDevice's
/// battery notification loop is ready.
/// On Android, battery_plus works reliably and is used as-is.
class DeviceTelemetryService {
  final SocketService _socket;
  final Battery _battery = Battery();

  /// Custom native channel for iOS battery reads.
  static const _nativeBatteryChannel = MethodChannel('com.cling/battery');

  /// Optional callbacks so callers can keep their own state in sync.
  final void Function(int level, String status)? onBatteryUpdate;
  final void Function(double lat, double lng)? onLocationUpdate;

  Timer? _batteryTimer;
  Timer? _gpsTimer;
  StreamSubscription<BatteryState>? _batteryStateSubscription;

  int? _lastSentBattery;
  String? _lastSentStatus;

  DeviceTelemetryService(
    this._socket, {
    this.onBatteryUpdate,
    this.onLocationUpdate,
  });

  // ── Start ──────────────────────────────────────────────────────────────────

  Future<void> start() async {
    print('DeviceTelemetry: start() called (platform: ${Platform.operatingSystem})');

    if (!Platform.isIOS) {
      // On Android, subscribe to the battery_plus state stream for real-time updates.
      try {
        _batteryStateSubscription = _battery.onBatteryStateChanged.listen(
          (state) {
            print('DeviceTelemetry: onBatteryStateChanged fired → $state');
            _syncBattery();
          },
          onError: (e) {
            print('DeviceTelemetry: onBatteryStateChanged stream error: $e');
          },
        );
        print('DeviceTelemetry: onBatteryStateChanged subscription created OK');
      } catch (e) {
        print('DeviceTelemetry: Failed to subscribe onBatteryStateChanged: $e');
      }
    }

    // Initial sync
    await _syncBattery();
    await _syncGps();

    // Periodic resync as a fallback
    _batteryTimer = Timer.periodic(const Duration(minutes: 2), (_) => _syncBattery());
    _gpsTimer = Timer.periodic(const Duration(minutes: 3), (_) => _syncGps());
    print('DeviceTelemetry: periodic timers started');
  }

  // ── Stop ───────────────────────────────────────────────────────────────────

  void stop() {
    print('DeviceTelemetry: stop() called');
    _batteryStateSubscription?.cancel();
    _batteryStateSubscription = null;
    _batteryTimer?.cancel();
    _gpsTimer?.cancel();
    _batteryTimer = null;
    _gpsTimer = null;
  }

  // ── Battery ────────────────────────────────────────────────────────────────

  String _mapBatteryState(BatteryState state) {
    switch (state) {
      case BatteryState.charging:
        return 'charging';
      case BatteryState.discharging:
        return 'discharging';
      case BatteryState.full:
        return 'full';
      case BatteryState.unknown:
      default:
        return 'unknown';
    }
  }

  /// Reads battery info via the custom native iOS channel.
  /// The native side enables UIDevice.isBatteryMonitoringEnabled and waits
  /// up to 3 seconds for a valid reading before returning.
  Future<({int level, String status})?> _readBatteryIOS() async {
    try {
      final raw = await _nativeBatteryChannel.invokeMapMethod<String, dynamic>('getBatteryInfo');
      if (raw == null) return null;
      final level = (raw['level'] as int?) ?? -1;
      final status = (raw['status'] as String?) ?? 'unknown';
      print('DeviceTelemetry [iOS]: native channel returned level=$level status=$status');
      if (level < 0) return null;
      return (level: level, status: status);
    } catch (e) {
      print('DeviceTelemetry [iOS]: native channel error: $e');
      return null;
    }
  }

  /// Reads battery info via battery_plus (Android & other platforms).
  Future<({int level, String status})?> _readBatteryAndroid() async {
    try {
      final level = await _battery.batteryLevel;
      if (level < 0) {
        print('DeviceTelemetry [Android]: batteryLevel=$level (skipping)');
        return null;
      }
      final state = await _battery.batteryState;
      final status = _mapBatteryState(state);
      print('DeviceTelemetry [Android]: level=$level status=$status');
      return (level: level, status: status);
    } catch (e) {
      print('DeviceTelemetry: _readBatteryAndroid EXCEPTION: $e');
      return null;
    }
  }

  Future<void> _syncBattery() async {
    final reading = Platform.isIOS
        ? await _readBatteryIOS()
        : await _readBatteryAndroid();

    if (reading == null) return;

    final level = reading.level;
    final statusStr = reading.status;

    // Send if changed by ≥ 3% or if the status changed (e.g. plugged in)
    if (_lastSentBattery == null ||
        _lastSentStatus == null ||
        (level - _lastSentBattery!).abs() >= 3 ||
        statusStr != _lastSentStatus) {
      print('DeviceTelemetry: sending battery:sync level=$level status=$statusStr');
      _socket.sendBatterySync(level, statusStr);
      _lastSentBattery = level;
      _lastSentStatus = statusStr;
      onBatteryUpdate?.call(level, statusStr);
    }
  }

  /// Public debug method — call this from the UI to force a battery read.
  Future<void> debugBatteryRead() async {
    print('DeviceTelemetry [DEBUG]: ── Manual battery read triggered (${Platform.operatingSystem}) ──');
    final reading = Platform.isIOS
        ? await _readBatteryIOS()
        : await _readBatteryAndroid();
    if (reading != null) {
      print('DeviceTelemetry [DEBUG]: Got level=${reading.level} status=${reading.status}');
      _socket.sendBatterySync(reading.level, reading.status);
      _lastSentBattery = reading.level;
      _lastSentStatus = reading.status;
      onBatteryUpdate?.call(reading.level, reading.status);
    } else {
      print('DeviceTelemetry [DEBUG]: reading returned null — battery not available');
    }
    print('DeviceTelemetry [DEBUG]: ── Manual battery read done ──');
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
    } catch (e) {
      print('DeviceTelemetry: _syncGps EXCEPTION: $e');
    }
  }
}
