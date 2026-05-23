import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/constants.dart';
import '../models/user_model.dart';
import '../models/couple_model.dart';
import '../models/game/game_state.dart';
import 'api_service.dart';

/// Real API implementation — calls your Go/NestJS backend.
/// Replace the base URL in ApiConstants when deploying.
class RealApiService implements ApiService {
  final http.Client _client = http.Client();
  String? _authToken;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_authToken != null) 'Authorization': 'Bearer $_authToken',
      };

  // ─── Auth ───

  @override
  Future<UserModel> register(String email, String password, String displayName) async {
    final res = await _post('/auth/register', {
      'email': email,
      'password': password,
      'displayName': displayName,
    });
    _authToken = res['token'] as String?;
    return UserModel.fromJson(res['user'] as Map<String, dynamic>);
  }

  @override
  Future<UserModel> login(String email, String password) async {
    final res = await _post('/auth/login', {'email': email, 'password': password});
    _authToken = res['token'] as String?;
    return UserModel.fromJson(res['user'] as Map<String, dynamic>);
  }

  @override
  Future<void> logout() async {
    await _post('/auth/logout', {});
    _authToken = null;
  }

  @override
  Future<UserModel> getMe() async {
    final res = await _get('/auth/me');
    return UserModel.fromJson(res);
  }

  // ─── Couple ───

  @override
  Future<String> generateInviteCode() async {
    final res = await _post('/couple/generate-code', {});
    return res['inviteCode'] as String;
  }

  @override
  Future<CoupleModel> joinCouple(String inviteCode) async {
    final res = await _post('/couple/join', {'inviteCode': inviteCode});
    return CoupleModel.fromJson(res);
  }

  @override
  Future<CoupleModel?> getCouple() async {
    try {
      final res = await _get('/couple');
      return CoupleModel.fromJson(res);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> unpair() async {
    await _delete('/couple');
  }

  // ─── Dashboard ───

  @override
  Future<void> updateBattery(int level) async {
    await _put('/me/battery', {'level': level});
  }

  @override
  Future<void> updateLocation(double lat, double lng) async {
    await _put('/me/location', {'lat': lat, 'lng': lng});
  }

  @override
  Future<void> updateMood(String emoji) async {
    await _put('/me/mood', {'emoji': emoji});
  }

  @override
  Future<void> updateSong(String title, String artist) async {
    await _put('/me/song', {'title': title, 'artist': artist});
  }

  @override
  Future<UserModel?> getPartnerStatus() async {
    try {
      final res = await _get('/partner/status');
      return UserModel.fromJson(res);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<CoupleModel?> getCoupleStats() async => getCouple();

  @override
  Future<CoupleStreaks?> getStreaks() async {
    try {
      final res = await _get('/couple/streaks');
      return CoupleStreaks.fromJson(res);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> sendGoodMorning() async {
    await _post('/couple/gm', {});
  }

  @override
  Future<void> sendGoodNight() async {
    await _post('/couple/gn', {});
  }

  @override
  Future<MissingMeter?> getMissingMeter() async {
    try {
      final res = await _get('/couple/missing-meter');
      return MissingMeter.fromJson(res);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> pingPartner() async {
    await _post('/couple/missing/ping', {});
  }

  @override
  Future<List<LocationAlert>> getLocationAlerts() async {
    try {
      final res = await _getList('/location/alerts');
      return res.map((e) => LocationAlert.fromJson(e)).toList();
    } catch (_) {
      return [];
    }
  }

  // ─── Emotes ───

  @override
  Future<void> sendEmote(String emoteId) async {
    await _post('/emotes/send', {'emoteId': emoteId});
  }

  @override
  Future<List<ReceivedEmote>> getReceivedEmotes() async {
    try {
      final res = await _getList('/emotes/received');
      return res.map((e) => ReceivedEmote.fromJson(e)).toList();
    } catch (_) {
      return [];
    }
  }

  // ─── Game ───

  @override
  Future<void> requestBattle() async {
    await _post('/game/request', {});
  }

  @override
  Future<void> acceptBattle() async {
    await _post('/game/accept', {});
  }

  @override
  Future<GameStateModel?> getActiveGame() async {
    try {
      final res = await _get('/game/active');
      return GameStateModel.fromJson(res);
    } catch (_) {
      return null;
    }
  }

  // ─── HTTP Helpers ───

  Future<Map<String, dynamic>> _get(String path) async {
    final res = await _client.get(
      Uri.parse('${ApiConstants.baseUrl}$path'),
      headers: _headers,
    );
    _checkResponse(res);
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> _getList(String path) async {
    final res = await _client.get(
      Uri.parse('${ApiConstants.baseUrl}$path'),
      headers: _headers,
    );
    _checkResponse(res);
    return (jsonDecode(res.body) as List).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> _post(String path, Map<String, dynamic> body) async {
    final res = await _client.post(
      Uri.parse('${ApiConstants.baseUrl}$path'),
      headers: _headers,
      body: jsonEncode(body),
    );
    _checkResponse(res);
    if (res.body.isEmpty) return {};
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<void> _put(String path, Map<String, dynamic> body) async {
    final res = await _client.put(
      Uri.parse('${ApiConstants.baseUrl}$path'),
      headers: _headers,
      body: jsonEncode(body),
    );
    _checkResponse(res);
  }

  Future<void> _delete(String path) async {
    final res = await _client.delete(
      Uri.parse('${ApiConstants.baseUrl}$path'),
      headers: _headers,
    );
    _checkResponse(res);
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
