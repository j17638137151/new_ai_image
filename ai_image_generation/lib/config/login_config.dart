enum LoginMode {
  phoneSms, // 手机号 + 验证码登录（国内）
  emailPassword, // 邮箱 + 密码登录（海外）
}

class LoginConfig {
  final LoginMode mode;

  const LoginConfig({required this.mode});

  bool get isPhoneLogin => mode == LoginMode.phoneSms;
  bool get isEmailLogin => mode == LoginMode.emailPassword;
}

/// 当前App使用的登录配置
///
/// 开发阶段你可以改这里：
/// - 国内版本：LoginMode.phoneSms
/// - 海外版本：LoginMode.emailPassword
///
/// 后面如果需要，也可以改为通过 --dart-define 注入，而不是写死。
const LoginConfig loginConfig = LoginConfig(mode: LoginMode.phoneSms);
