import 'package:shared_preferences/shared_preferences.dart';

/// Persists JWT access & refresh tokens in SharedPreferences.
/// Works on both Android and iOS out of the box.
class TokenStorage {
  static const _keyAccess = 'cling_access_token';
  static const _keyRefresh = 'cling_refresh_token';

  /// Save both tokens after login / register / refresh.
  static Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyAccess, accessToken);
    await prefs.setString(_keyRefresh, refreshToken);
  }

  /// Read the stored access token (null if never logged in).
  static Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyAccess);
  }

  /// Read the stored refresh token (null if never logged in).
  static Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyRefresh);
  }

  /// Clear everything on logout.
  static Future<void> clearTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyAccess);
    await prefs.remove(_keyRefresh);
  }

  /// Quick check — is there a stored access token at all?
  static Future<bool> hasTokens() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }
}
