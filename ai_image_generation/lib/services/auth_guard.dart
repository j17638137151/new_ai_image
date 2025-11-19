import 'package:flutter/material.dart';

import 'auth_state.dart';
import '../pages/auth_entry_page.dart';

/// 登录鉴权工具
/// 在发起生成等需要登录的操作前调用，未登录时跳转到登录入口页
class AuthGuard {
  AuthGuard._();

  /// 确保用户已登录
  /// 返回 true 表示已登录或登录成功，false 表示用户取消登录
  static Future<bool> ensureLoggedIn(BuildContext context) async {
    // 已登录，直接通过
    if (AuthState.instance.isLoggedIn) {
      return true;
    }

    // 未登录，跳转到登录入口页
    final result = await Navigator.push<bool>(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const AuthEntryPage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.0, 1.0);
          const end = Offset.zero;
          const curve = Curves.easeInOutCubic;

          final tween = Tween(
            begin: begin,
            end: end,
          ).chain(CurveTween(curve: curve));

          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );

    // result 可以用来区分是否登录成功，这里以 AuthState 为准
    return AuthState.instance.isLoggedIn && (result ?? true);
  }
}
