import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'auth_api_service.dart';
import 'auth_state.dart';

/// 用户资料更新服务
class UserProfileService {
  UserProfileService._();

  static String get _baseUrl => AuthApiService.baseUrl;

  /// 更新用户资料
  /// [nickname] 昵称（可选）
  /// [avatarUrl] 头像URL（可选）
  /// [bio] 个人简介（可选）
  static Future<bool> updateProfile({
    String? nickname,
    String? avatarUrl,
    String? bio,
  }) async {
    final token = AuthState.instance.currentUser?.token;
    if (token == null) {
      debugPrint('[Profile] 用户未登录，无法更新资料');
      return false;
    }

    try {
      // 构建请求体（只包含非空字段）
      final Map<String, dynamic> body = {};
      if (nickname != null) body['nickname'] = nickname;
      if (avatarUrl != null) body['avatarUrl'] = avatarUrl;
      if (bio != null) body['bio'] = bio;

      if (body.isEmpty) {
        debugPrint('[Profile] 没有要更新的字段');
        return false;
      }

      final uri = Uri.parse('$_baseUrl/user/profile');
      debugPrint('[Profile] 更新资料: $uri');
      debugPrint('[Profile] 更新内容: $body');

      final response = await http.put(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(body),
      );

      debugPrint('[Profile] 响应状态码: ${response.statusCode}');
      debugPrint('[Profile] 响应内容: ${response.body}');

      if (response.statusCode == 200) {
        // 更新成功，调用方需要刷新页面或重新获取profile
        debugPrint('[Profile] 资料更新成功');
        return true;
      } else {
        debugPrint('[Profile] 更新失败: ${response.statusCode}');
        return false;
      }
    } catch (e, stack) {
      debugPrint('[Profile] 更新异常: $e');
      debugPrint('[Profile] 堆栈: $stack');
      return false;
    }
  }
}
