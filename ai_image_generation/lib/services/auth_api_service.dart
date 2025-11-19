import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/login_config.dart';

class AuthApiService {
  AuthApiService._();

  static const String _baseUrl = 'http://localhost:3100';

  static String get baseUrl => _baseUrl;

  /// 通用登录入口，根据当前 loginConfig 决定走哪种模式
  static Future<LoginResult> login({required String identifier}) async {
    if (loginConfig.isPhoneLogin) {
      return _loginWithPhone(phone: identifier);
    } else {
      // 预留给邮箱登录，当前先抛异常，避免误用
      throw UnsupportedError('当前配置为邮箱登录模式，但未实现 email 登录逻辑');
    }
  }

  /// 显式手机号登录（供页面直接调用），等价于当前配置为 phoneSms 时的 login()
  static Future<LoginResult> loginWithPhone(String phone) {
    return _loginWithPhone(phone: phone);
  }

  /// 显式邮箱登录（供后续 foreign 模式使用）
  static Future<LoginResult> loginWithEmail({
    required String email,
    required String password,
  }) async {
    final uri = Uri.parse('$_baseUrl/auth/login');

    final body = jsonEncode({
      'loginMode': 'emailPassword',
      'email': email,
      'password': password,
    });

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    if (response.statusCode != 200) {
      throw Exception('登录失败: ${response.statusCode} ${response.body}');
    }

    final Map<String, dynamic> data = jsonDecode(response.body);
    return LoginResult.fromJson(data);
  }

  /// 手机号 + 万能验证码登录（开发环境）
  static Future<LoginResult> _loginWithPhone({required String phone}) async {
    final uri = Uri.parse('$_baseUrl/auth/login');

    final body = jsonEncode({
      'loginMode': 'phoneSms',
      'phone': phone,
      'smsCode': '666666', // 万能验证码，仅开发阶段使用
    });

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    if (response.statusCode != 200) {
      throw Exception('登录失败: ${response.statusCode} ${response.body}');
    }

    final Map<String, dynamic> data = jsonDecode(response.body);
    return LoginResult.fromJson(data);
  }

  /// 获取用户资料
  static Future<LoginResult?> getProfile(String token) async {
    try {
      final uri = Uri.parse('$_baseUrl/auth/profile');

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200) {
        debugPrint('获取用户资料失败: ${response.statusCode}');
        return null;
      }

      final Map<String, dynamic> data = jsonDecode(response.body);
      // 将token添加回返回数据（因为API返回不包含token）
      data['token'] = token;
      data['expiresIn'] = 30 * 24 * 60 * 60; // 默认30天

      return LoginResult.fromJson(data);
    } catch (e) {
      debugPrint('获取用户资料异常: $e');
      return null;
    }
  }

  /// 手机号注册（当前与登录行为类似，使用万能验证码）
  static Future<LoginResult> registerWithPhone(String phone) async {
    final uri = Uri.parse('$_baseUrl/auth/register');

    final body = jsonEncode({
      'loginMode': 'phoneSms',
      'phone': phone,
      'smsCode': '666666',
    });

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    if (response.statusCode != 200) {
      throw Exception('注册失败: ${response.statusCode} ${response.body}');
    }

    final Map<String, dynamic> data = jsonDecode(response.body);
    return LoginResult.fromJson(data);
  }

  /// 邮箱注册（仅开发阶段，密码明文传输，与后端当前实现一致）
  static Future<LoginResult> registerWithEmail({
    required String email,
    required String password,
  }) async {
    final uri = Uri.parse('$_baseUrl/auth/register');

    final body = jsonEncode({
      'loginMode': 'emailPassword',
      'email': email,
      'password': password,
    });

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    if (response.statusCode != 200) {
      throw Exception('注册失败: ${response.statusCode} ${response.body}');
    }

    final Map<String, dynamic> data = jsonDecode(response.body);
    return LoginResult.fromJson(data);
  }
}

class LoginResult {
  final String userId;
  final String token;
  final String loginMode;
  final int expiresIn;
  final String? nickname;
  final String? avatarUrl;
  final String? bio;

  const LoginResult({
    required this.userId,
    required this.token,
    required this.loginMode,
    required this.expiresIn,
    this.nickname,
    this.avatarUrl,
    this.bio,
  });

  factory LoginResult.fromJson(Map<String, dynamic> json) {
    return LoginResult(
      userId: json['userId'] as String,
      token: json['token'] as String,
      loginMode: json['loginMode'] as String,
      expiresIn: (json['expiresIn'] as num).toInt(),
      nickname: json['nickname'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      bio: json['bio'] as String?,
    );
  }

  LoginResult copyWith({
    String? userId,
    String? token,
    String? loginMode,
    int? expiresIn,
    String? nickname,
    String? avatarUrl,
    String? bio,
  }) {
    return LoginResult(
      userId: userId ?? this.userId,
      token: token ?? this.token,
      loginMode: loginMode ?? this.loginMode,
      expiresIn: expiresIn ?? this.expiresIn,
      nickname: nickname ?? this.nickname,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
    );
  }
}
