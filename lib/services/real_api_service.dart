import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/constants.dart';
import '../models/user_model.dart';
import '../models/couple_model.dart';
import '../models/game/game_state.dart';
import 'api_service.dart';
import 'token_storage.dart';

/// Real API implementation — calls the NestJS backend.
/// All endpoints are prefixed with /api/v1 (set in ApiConstants.baseUrl).
class RealApiService implements ApiService {
  final http.Client _client = http.Client();
  String? _accessToken;
  String? _refreshToken;
  bool _tokensLoaded = false;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_accessToken != null) 'Authorization': 'Bearer $_accessToken',
      };

  /// Call this on app start to load persisted tokens.
  Future<void> loadStoredTokens() async {
    _accessToken = await TokenStorage.getAccessToken();
    _refreshToken = await TokenStorage.getRefreshToken();
    _tokensLoaded = true;
  }

  Future<void> _ensureTokensLoaded() async {
    if (!_tokensLoaded) {
      await loadStoredTokens();
    }
  }

  /// Current access token (exposed for SocketService handshake).
  String? get accessToken => _accessToken;

  // ─── Auth ───

  @override
  Future<UserModel> register(String email, String password, String displayName) async {
    final res = await _post('/auth/register', {
      'email': email,
      'password': password,
      'displayName': displayName,
    });
    await _handleAuthResponse(res);
    return _userFromAuthResponse(res);
  }

  @override
  Future<UserModel> login(String email, String password) async {
    final res = await _post('/auth/login', {
      'email': email,
      'password': password,
    });
    await _handleAuthResponse(res);
    return _userFromAuthResponse(res);
  }

  @override
  Future<void> logout() async {
    try {
      await _post('/auth/logout', {});
    } catch (_) {
      // Even if the server call fails, clear local tokens
    }
    _accessToken = null;
    _refreshToken = null;
    await TokenStorage.clearTokens();
  }

  @override
  Future<UserModel> getMe() async {
    await _ensureTokensLoaded();
    // No dedicated /me endpoint on backend. We verify the token
    // by attempting a refresh — if it works, we're logged in.
    if (_accessToken == null && _refreshToken == null) {
      throw Exception('Not logged in');
    }

    // Try refreshing to validate session and get fresh user data
    if (_refreshToken != null) {
      try {
        final res = await _postRaw('/auth/refresh', {'refreshToken': _refreshToken});
        if (res.statusCode < 400) {
          final body = jsonDecode(res.body) as Map<String, dynamic>;
          await _handleAuthResponse(body);
          return _userFromAuthResponse(body);
        }
      } catch (_) {}
    }

    throw Exception('Session expired');
  }

  // ─── Couple / Pairs ───

  @override
  Future<String> generateInviteCode() async {
    final res = await _get('/pairs/invite-code');
    return res['inviteCode'] as String;
  }

  @override
  Future<CoupleModel> joinCouple(String inviteCode) async {
    await _post('/pairs/link', {'inviteCode': inviteCode});
    // After linking, refresh tokens to get updated coupleId in JWT
    await _refreshTokens();
    // Return a minimal couple model — full data loaded via loadCoupleData()
    return CoupleModel(
      coupleId: '',
      user1Id: '',
      user2Id: '',
      togetherSince: DateTime.now(),
      streaks: const CoupleStreaks(
        general: StreakData(count: 0, lastDate: ''),
        goodMorning: StreakData(count: 0, lastDate: ''),
        goodNight: StreakData(count: 0, lastDate: ''),
      ),
      missingMeter: const MissingMeter(user1Score: 0, user2Score: 0, weekStart: ''),
      gameStats: const GameStats(user1Wins: 0, user2Wins: 0, draws: 0),
    );
  }

  @override
  Future<CoupleModel?> getCouple() async {
    // Build a CoupleModel from multiple backend endpoints
    try {
      final partner = await getPartnerStatus();
      if (partner == null) return null;

      final streaks = await getStreaks();
      final missing = await getMissingMeter();

      return CoupleModel(
        coupleId: '', // We don't have direct access; it's embedded in JWT
        user1Id: '',
        user2Id: partner.uid,
        togetherSince: DateTime.now(),
        streaks: streaks ?? const CoupleStreaks(
          general: StreakData(count: 0, lastDate: ''),
          goodMorning: StreakData(count: 0, lastDate: ''),
          goodNight: StreakData(count: 0, lastDate: ''),
        ),
        missingMeter: missing ?? const MissingMeter(user1Score: 0, user2Score: 0, weekStart: ''),
        gameStats: const GameStats(user1Wins: 0, user2Wins: 0, draws: 0),
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> unpair() async {
    await _delete('/pairs/unlink');
  }

  // ─── Dashboard ───

  @override
  Future<void> updateBattery(int level) async {
    // Battery is synced via WebSocket (battery:sync), not REST
    // This is handled by SocketService.sendBatterySync()
  }

  @override
  Future<void> updateLocation(double lat, double lng) async {
    // Location is synced via WebSocket or background job
    // For now, archive as a place visit
    try {
      await _post('/places/visit', {'lat': lat, 'lng': lng});
    } catch (_) {}
  }

  @override
  Future<void> updateMood(String emoji) async {
    // Mood is synced via WebSocket (mood:update), not REST
    // This is handled by SocketService.sendMoodUpdate()
  }

  @override
  Future<void> updateSong(String title, String artist) async {
    // Song is synced via WebSocket (music:sync), not REST
    // This is handled by SocketService.sendMusicSync()
  }

  @override
  Future<UserModel?> getPartnerStatus() async {
    try {
      final res = await _get('/pairs/partner');
      // Backend returns {id, displayName, avatarUrl}
      return UserModel(
        uid: res['id'] as String,
        email: '', // Not exposed by partner endpoint
        displayName: res['displayName'] as String,
        avatarUrl: res['avatarUrl'] as String?,
        createdAt: DateTime.now(),
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<CoupleModel?> getCoupleStats() async => getCouple();

  @override
  Future<CoupleStreaks?> getStreaks() async {
    try {
      final res = await _getList('/streaks');
      // Backend returns an array of {id, coupleId, type, count, lastAt, updatedAt}
      int generalCount = 0;
      String generalLast = '';
      int gmCount = 0;
      String gmLast = '';
      int gnCount = 0;
      String gnLast = '';

      for (final streak in res) {
        final type = streak['type'] as String;
        final count = streak['count'] as int;
        final lastAt = streak['lastAt'] as String? ?? '';

        switch (type) {
          case 'GENERAL':
            generalCount = count;
            generalLast = lastAt;
            break;
          case 'GOOD_MORNING':
            gmCount = count;
            gmLast = lastAt;
            break;
          case 'GOOD_NIGHT':
            gnCount = count;
            gnLast = lastAt;
            break;
        }
      }

      return CoupleStreaks(
        general: StreakData(count: generalCount, lastDate: generalLast),
        goodMorning: StreakData(count: gmCount, lastDate: gmLast),
        goodNight: StreakData(count: gnCount, lastDate: gnLast),
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> sendGoodMorning() async {
    // Handled via WebSocket ping which triggers streak recording on backend
    // The backend's event emitter handles this when a ping event fires
  }

  @override
  Future<void> sendGoodNight() async {
    // Same as sendGoodMorning — uses WebSocket ping
  }

  @override
  Future<MissingMeter?> getMissingMeter() async {
    try {
      final res = await _get('/missing');
      return MissingMeter(
        user1Score: res['user1Score'] as int,
        user2Score: res['user2Score'] as int,
        weekStart: (res['weekStart'] as String?) ?? '',
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> pingPartner() async {
    // Ping is sent via WebSocket (ping event), not REST
    // Handled by SocketService.sendPing()
  }

  @override
  Future<List<LocationAlert>> getLocationAlerts() async {
    try {
      final res = await _getList('/places/history');
      return res.map((e) => LocationAlert(
        place: (e['label'] as String?) ?? 'Unknown place',
        partnerVisitDate: DateTime.parse(e['visitedAt'] as String),
        lat: (e['lat'] as num).toDouble(),
        lng: (e['lng'] as num).toDouble(),
      )).toList();
    } catch (_) {
      return [];
    }
  }

  // ─── Emotes ───

  @override
  Future<void> sendEmote(String emoteId) async {
    // Emotes are sent via WebSocket (emote event), not REST
    // Handled by SocketService.sendEmote()
  }

  @override
  Future<List<ReceivedEmote>> getReceivedEmotes() async {
    // No REST endpoint for received emotes — they arrive via WebSocket
    return [];
  }

  // ─── Game ───

  @override
  Future<void> requestBattle() async {
    await _post('/game/start', {});
  }

  @override
  Future<void> acceptBattle() async {
    // Game start is done via POST /game/start by either player
    // The match state is broadcast via WebSocket
  }

  @override
  Future<GameStateModel?> getActiveGame() async {
    // No dedicated "active game" endpoint — the game state
    // comes via WebSocket events (game:state_updated)
    return null;
  }

  /// Start a new game match. Returns the backend GameState.
  Future<Map<String, dynamic>> startMatch() async {
    return await _post('/game/start', {});
  }

  /// Deploy a troop in an active match.
  Future<Map<String, dynamic>> deployTroop(String matchId, String troopId) async {
    return await _post('/game/deploy', {
      'matchId': matchId,
      'troopId': troopId,
    });
  }

  /// Get game state for a specific match.
  Future<Map<String, dynamic>?> getGameState(String matchId) async {
    try {
      return await _get('/game/state/$matchId');
    } catch (_) {
      return null;
    }
  }

  /// Record a "missing you" profile visit.
  Future<void> recordMissingVisit() async {
    await _post('/missing/visit', {});
  }

  // ─── Token Management ───

  Future<void> _handleAuthResponse(Map<String, dynamic> res) async {
    _accessToken = res['accessToken'] as String?;
    _refreshToken = res['refreshToken'] as String?;
    if (_accessToken != null && _refreshToken != null) {
      await TokenStorage.saveTokens(
        accessToken: _accessToken!,
        refreshToken: _refreshToken!,
      );
    }
  }

  UserModel _userFromAuthResponse(Map<String, dynamic> res) {
    final user = res['user'] as Map<String, dynamic>;
    return UserModel(
      uid: user['id'] as String,
      email: user['email'] as String,
      displayName: user['displayName'] as String,
      avatarUrl: user['avatarUrl'] as String?,
      createdAt: DateTime.now(),
    );
  }

  Future<bool> _refreshTokens() async {
    if (_refreshToken == null) return false;
    try {
      final res = await _postRaw('/auth/refresh', {'refreshToken': _refreshToken});
      if (res.statusCode < 400 && res.body.isNotEmpty) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        await _handleAuthResponse(body);
        return true;
      }
    } catch (_) {}
    return false;
  }

  // ─── HTTP Helpers ───

  Future<Map<String, dynamic>> _get(String path) async {
    await _ensureTokensLoaded();
    try {
      var res = await _client.get(
        Uri.parse('${ApiConstants.baseUrl}$path'),
        headers: _headers,
      ).timeout(const Duration(seconds: 10));

      // Auto-refresh on 401
      if (res.statusCode == 401 && await _refreshTokens()) {
        res = await _client.get(
          Uri.parse('${ApiConstants.baseUrl}$path'),
          headers: _headers,
        ).timeout(const Duration(seconds: 10));
      }

      _checkResponse(res);
      return jsonDecode(res.body) as Map<String, dynamic>;
    } on TimeoutException {
      throw const ApiException(statusCode: 408, message: 'Connection timed out');
    } on SocketException {
      throw const ApiException(statusCode: 0, message: 'No internet connection or backend is unreachable');
    }
  }

  Future<List<Map<String, dynamic>>> _getList(String path) async {
    await _ensureTokensLoaded();
    try {
      var res = await _client.get(
        Uri.parse('${ApiConstants.baseUrl}$path'),
        headers: _headers,
      ).timeout(const Duration(seconds: 10));

      // Auto-refresh on 401
      if (res.statusCode == 401 && await _refreshTokens()) {
        res = await _client.get(
          Uri.parse('${ApiConstants.baseUrl}$path'),
          headers: _headers,
        ).timeout(const Duration(seconds: 10));
      }

      _checkResponse(res);
      return (jsonDecode(res.body) as List).cast<Map<String, dynamic>>();
    } on TimeoutException {
      throw const ApiException(statusCode: 408, message: 'Connection timed out');
    } on SocketException {
      throw const ApiException(statusCode: 0, message: 'No internet connection or backend is unreachable');
    }
  }

  Future<Map<String, dynamic>> _post(String path, Map<String, dynamic> body) async {
    await _ensureTokensLoaded();
    try {
      var res = await _client.post(
        Uri.parse('${ApiConstants.baseUrl}$path'),
        headers: _headers,
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 10));

      // Auto-refresh on 401 (skip for auth endpoints)
      if (res.statusCode == 401 && !path.startsWith('/auth/') && await _refreshTokens()) {
        res = await _client.post(
          Uri.parse('${ApiConstants.baseUrl}$path'),
          headers: _headers,
          body: jsonEncode(body),
        ).timeout(const Duration(seconds: 10));
      }

      _checkResponse(res);
      if (res.body.isEmpty) return {};
      return jsonDecode(res.body) as Map<String, dynamic>;
    } on TimeoutException {
      throw const ApiException(statusCode: 408, message: 'Connection timed out');
    } on SocketException {
      throw const ApiException(statusCode: 0, message: 'No internet connection or backend is unreachable');
    }
  }

  /// Raw POST without response checking — used for refresh attempts.
  Future<http.Response> _postRaw(String path, Map<String, dynamic> body) async {
    await _ensureTokensLoaded();
    try {
      return await _client.post(
        Uri.parse('${ApiConstants.baseUrl}$path'),
        headers: {
          'Content-Type': 'application/json',
          if (_accessToken != null) 'Authorization': 'Bearer $_accessToken',
        },
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 10));
    } on TimeoutException {
      throw const ApiException(statusCode: 408, message: 'Connection timed out');
    } on SocketException {
      throw const ApiException(statusCode: 0, message: 'No internet connection or backend is unreachable');
    }
  }

  Future<void> _delete(String path) async {
    await _ensureTokensLoaded();
    try {
      var res = await _client.delete(
        Uri.parse('${ApiConstants.baseUrl}$path'),
        headers: _headers,
      ).timeout(const Duration(seconds: 10));

      // Auto-refresh on 401
      if (res.statusCode == 401 && await _refreshTokens()) {
        res = await _client.delete(
          Uri.parse('${ApiConstants.baseUrl}$path'),
          headers: _headers,
        ).timeout(const Duration(seconds: 10));
      }

      _checkResponse(res);
    } on TimeoutException {
      throw const ApiException(statusCode: 408, message: 'Connection timed out');
    } on SocketException {
      throw const ApiException(statusCode: 0, message: 'No internet connection or backend is unreachable');
    }
  }

  void _checkResponse(http.Response res) {
    if (res.statusCode >= 400) {
      final body = res.body.isNotEmpty ? jsonDecode(res.body) : {};
      throw ApiException(
        statusCode: res.statusCode,
        message: body['message'] as String? ?? 'Request failed',
      );
    }
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String message;

  const ApiException({required this.statusCode, required this.message});

  @override
  String toString() => 'ApiException($statusCode): $message';
}
