import 'package:shared_preferences/shared_preferences.dart';

class AuthStore {
  static const _kAccessToken = 'access_token';

  Future<String?> loadAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    final tok = prefs.getString(_kAccessToken);
    if (tok == null || tok.trim().isEmpty) return null;
    return tok;
  }

  Future<void> saveAccessToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kAccessToken, token);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kAccessToken);
  }
}
