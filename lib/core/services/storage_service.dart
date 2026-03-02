import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// 本地存储服务
class StorageService {
  StorageService._();
  static final StorageService instance = StorageService._();

  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Token相关
  static const String _keyAccessToken = 'access_token';
  static const String _keyRefreshToken = 'refresh_token';
  static const String _keyTokenExpire = 'token_expire';

  String? get accessToken => _prefs.getString(_keyAccessToken);
  String? get refreshToken => _prefs.getString(_keyRefreshToken);
  int? get tokenExpire => _prefs.getInt(_keyTokenExpire);

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    int? expireTime,
  }) async {
    await _prefs.setString(_keyAccessToken, accessToken);
    await _prefs.setString(_keyRefreshToken, refreshToken);
    if (expireTime != null) {
      await _prefs.setInt(_keyTokenExpire, expireTime);
    }
  }

  Future<void> clearTokens() async {
    await _prefs.remove(_keyAccessToken);
    await _prefs.remove(_keyRefreshToken);
    await _prefs.remove(_keyTokenExpire);
  }

  // 用户信息
  static const String _keyUserInfo = 'user_info';

  Map<String, dynamic>? get userInfo {
    final jsonStr = _prefs.getString(_keyUserInfo);
    if (jsonStr == null) return null;
    return jsonDecode(jsonStr) as Map<String, dynamic>;
  }

  Future<void> saveUserInfo(Map<String, dynamic> info) async {
    await _prefs.setString(_keyUserInfo, jsonEncode(info));
  }

  Future<void> clearUserInfo() async {
    await _prefs.remove(_keyUserInfo);
  }

  // 通用方法
  Future<void> setString(String key, String value) async {
    await _prefs.setString(key, value);
  }

  String? getString(String key) => _prefs.getString(key);

  Future<void> setInt(String key, int value) async {
    await _prefs.setInt(key, value);
  }

  int? getInt(String key) => _prefs.getInt(key);

  Future<void> setBool(String key, bool value) async {
    await _prefs.setBool(key, value);
  }

  bool? getBool(String key) => _prefs.getBool(key);

  Future<void> remove(String key) async {
    await _prefs.remove(key);
  }

  Future<void> clear() async {
    await _prefs.clear();
  }
}
