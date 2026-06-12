import 'dart:async';
import 'package:flutter/services.dart';
import 'socket_service.dart';

/// Detects media currently playing on music apps (Spotify, YouTube Music,
/// Apple Music, YouTube) via a platform MethodChannel backed by Android
/// NotificationListenerService, and emits it over the live socket.
class MediaSessionService {
  static const _channel = MethodChannel('com.cohyme.cling/media_session');

  final SocketService _socket;
  Timer? _pollTimer;

  String? _lastTitle;
  String? _lastArtist;

  MediaSessionService(this._socket);

  // ── Start ──────────────────────────────────────────────────────────────────

  Future<void> start() async {
    // Initial fetch
    await _pollMedia();
    // Poll every 15 seconds
    _pollTimer = Timer.periodic(const Duration(seconds: 15), (_) => _pollMedia());
  }

  // ── Stop ───────────────────────────────────────────────────────────────────

  void stop() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  // ── Check notification listener permission ─────────────────────────────────

  Future<bool> hasNotificationAccess() async {
    try {
      final result = await _channel.invokeMethod<bool>('hasNotificationAccess');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<void> openNotificationSettings() async {
    try {
      await _channel.invokeMethod('openNotificationSettings');
    } catch (_) {}
  }

  // ── Poll ───────────────────────────────────────────────────────────────────

  Future<void> _pollMedia() async {
    try {
      final result = await _channel.invokeMethod<Map>('getCurrentMedia');
      if (result == null) {
        // Nothing playing — clear if we had something before
        if (_lastTitle != null) {
          _socket.clearMusicSync();
          _lastTitle = null;
          _lastArtist = null;
        }
        return;
      }

      final title = result['title'] as String? ?? '';
      final artist = result['artist'] as String? ?? '';

      if (title.isEmpty) {
        if (_lastTitle != null) {
          _socket.clearMusicSync();
          _lastTitle = null;
          _lastArtist = null;
        }
        return;
      }

      // Only send if changed
      if (title != _lastTitle || artist != _lastArtist) {
        _socket.sendMusicSync(title, artist);
        _lastTitle = title;
        _lastArtist = artist;
      }
    } catch (_) {
      // Platform channel might not be available on iOS or in debug — ignore
    }
  }
}
