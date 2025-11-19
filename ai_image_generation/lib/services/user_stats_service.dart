import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'auth_api_service.dart';
import 'auth_state.dart';

/// 用户统计数据模型
class UserStats {
  final int todayCount;
  final int weekCount;
  final int totalCount;

  const UserStats({
    required this.todayCount,
    required this.weekCount,
    required this.totalCount,
  });

  factory UserStats.fromJson(Map<String, dynamic> json) {
    return UserStats(
      todayCount: json['todayCount'] as int? ?? 0,
      weekCount: json['weekCount'] as int? ?? 0,
      totalCount: json['totalCount'] as int? ?? 0,
    );
  }
}

/// 用户统计服务
class UserStatsService {
  UserStatsService._();

  static String get _baseUrl => AuthApiService.baseUrl;

  /// 获取用户统计数据
  static Future<UserStats> getStats() async {
    final token = AuthState.instance.currentUser?.token;
    if (token == null) {
      debugPrint('[Stats] 用户未登录，返回0统计');
      return const UserStats(todayCount: 0, weekCount: 0, totalCount: 0);
    }

    try {
      final uri = Uri.parse('$_baseUrl/user/stats');
      debugPrint('[Stats] 请求统计数据: $uri');

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint('[Stats] 响应状态码: ${response.statusCode}');
      debugPrint('[Stats] 响应内容: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final stats = UserStats.fromJson(data);
        debugPrint(
          '[Stats] 获取统计成功: 今日${stats.todayCount}, 本周${stats.weekCount}, 总计${stats.totalCount}',
        );
        return stats;
      } else {
        debugPrint('[Stats] 获取统计失败: ${response.statusCode}');
        return const UserStats(todayCount: 0, weekCount: 0, totalCount: 0);
      }
    } catch (e, stack) {
      debugPrint('[Stats] 获取统计异常: $e');
      debugPrint('[Stats] 堆栈: $stack');
      return const UserStats(todayCount: 0, weekCount: 0, totalCount: 0);
    }
  }
}
