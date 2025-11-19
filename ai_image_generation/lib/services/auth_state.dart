import 'package:flutter/foundation.dart';

import 'auth_api_service.dart';

/// 简单的全局登录状态（仅内存，不做持久化）
class AuthState extends ChangeNotifier {
  AuthState._internal();

  static final AuthState instance = AuthState._internal();

  LoginResult? _currentUser;

  LoginResult? get currentUser => _currentUser;

  bool get isLoggedIn => _currentUser != null;

  void setLoginResult(LoginResult result) {
    _currentUser = result;
    notifyListeners();
  }

  void logout() {
    _currentUser = null;
    notifyListeners();
  }

  /// 刷新用户资料
  Future<bool> refreshProfile() async {
    if (_currentUser == null) return false;

    final updatedUser = await AuthApiService.getProfile(_currentUser!.token);
    if (updatedUser != null) {
      _currentUser = updatedUser;
      notifyListeners();
      return true;
    }
    return false;
  }
}
