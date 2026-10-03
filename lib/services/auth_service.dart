// AuthService — manages JWT token persistence and session restoration.
// Flutter NEVER contacts Supabase directly. All auth goes through Flask.
// Token is stored in SharedPreferences and sent as Bearer header on every request.

import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  static const String _tokenKey = 'auth_access_token';

  String? _token;

  String? get token => _token;
  bool get hasToken => _token != null && _token!.isNotEmpty;

  /// Load token from persistent storage on app startup.
  Future<void> loadStoredToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString(_tokenKey);
    } catch (e) {
      debugPrint('AuthService: Failed to load stored token: $e');
      _token = null;
    }
  }

  /// Persist token after a successful login.
  Future<void> saveToken(String token) async {
    _token = token;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, token);
    } catch (e) {
      debugPrint('AuthService: Failed to save token: $e');
    }
  }

  /// Clear token on logout or on receiving a 401 response.
  Future<void> clearToken() async {
    _token = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
    } catch (e) {
      debugPrint('AuthService: Failed to clear token: $e');
    }
  }
}
