import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../../core/services/storage_service.dart';
import '../../core/services/http_client.dart';
import '../../core/services/websocket_service.dart';

/// 认证状态Provider
class AuthProvider extends ChangeNotifier {
  UserModel? _user;
  bool _isLoading = false;
  String? _error;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _user != null;

  AuthProvider() {
    _init();
  }

  void _init() {
    HttpClient.instance.init();
    _loadUserFromStorage();
  }

  void _loadUserFromStorage() {
    final userInfo = StorageService.instance.userInfo;
    if (userInfo != null) {
      _user = UserModel.fromJson(userInfo);
      notifyListeners();
    }
  }

  /// 登录
  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // ✅ 修复Bug4: 路径 /api/user/login → /api/v1/auth/login
      final response = await HttpClient.instance.post(
        '/api/v1/auth/login',
        data: {'username': username, 'password': password},
      );

      if (response.isSuccess) {
        final data = response.data as Map<String, dynamic>;
        await StorageService.instance.saveTokens(
          accessToken: data['accessToken'] as String,
          refreshToken: data['refreshToken'] as String,
        );

        _user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
        await StorageService.instance.saveUserInfo(_user!.toJson());

        // 连接WebSocket
        WebSocketService.instance.connect();

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = response.message;
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = '登录失败: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// 注册
  Future<bool> register({
    required String username,
    required String password,
    required String nickname,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // ✅ 修复Bug4: 路径 /api/user/register → /api/v1/auth/register
      final response = await HttpClient.instance.post(
        '/api/v1/auth/register',
        data: {
          'username': username,
          'password': password,
          'nickname': nickname,
        },
      );

      _isLoading = false;
      if (response.isSuccess) {
        notifyListeners();
        return true;
      } else {
        _error = response.message;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = '注册失败: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// 登出
  Future<void> logout() async {
    try {
      // ✅ 修复Bug4: 路径 /api/user/logout → /api/v1/auth/logout
      await HttpClient.instance.post('/api/v1/auth/logout');
    } catch (_) {}

    WebSocketService.instance.disconnect();
    await StorageService.instance.clearTokens();
    await StorageService.instance.clearUserInfo();

    _user = null;
    notifyListeners();
  }

  /// 刷新用户信息
  Future<void> refreshUserInfo() async {
    if (_user == null) return;

    try {
      // ✅ 修复Bug4: 路径 /api/user/info → /api/v1/users/me
      final response = await HttpClient.instance.get('/api/v1/users/me');
      if (response.isSuccess) {
        _user = UserModel.fromJson(response.data as Map<String, dynamic>);
        await StorageService.instance.saveUserInfo(_user!.toJson());
        notifyListeners();
      }
    } catch (_) {}
  }

  /// 更新用户信息
  Future<bool> updateUserInfo({
    String? nickname,
    String? signature,
    int? gender,
    String? birthday,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      // ✅ 修复Bug4: 路径 /api/user/update → /api/v1/users/{userId}（PUT）
      final userInfo = StorageService.instance.userInfo;
      final userId = (userInfo?['userId'] as num?)?.toInt() ?? 0;
      final response = await HttpClient.instance.put(
        '/api/v1/users/$userId',
        data: {
          if (nickname != null) 'nickname': nickname,
          if (signature != null) 'signature': signature,
          if (gender != null) 'gender': gender,
          if (birthday != null) 'birthday': birthday,
        },
      );

      _isLoading = false;
      if (response.isSuccess) {
        await refreshUserInfo();
        return true;
      } else {
        _error = response.message;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = '更新失败: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// 修改密码
  Future<bool> changePassword(String oldPassword, String newPassword) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // ✅ 修复Bug4: POST /api/user/password → PUT /api/v1/users/{userId}/password
      // 服务端用@RequestParam，需要用params（query参数）传递
      final userInfo = StorageService.instance.userInfo;
      final userId = (userInfo?['userId'] as num?)?.toInt() ?? 0;
      final response = await HttpClient.instance.put(
        '/api/v1/users/$userId/password',
        params: {'oldPassword': oldPassword, 'newPassword': newPassword},
      );

      _isLoading = false;
      if (response.isSuccess) {
        notifyListeners();
        return true;
      } else {
        _error = response.message;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = '修改密码失败: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
