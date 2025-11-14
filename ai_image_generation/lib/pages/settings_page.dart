import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String _currentLanguage = '中文';
  String _cacheSize = '125MB';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // 顶部导航栏
            _buildTopBar(),
            
            // 设置列表
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    
                    // 设置标题
                    const Text(
                      '⚙️ 设置',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    
                    const SizedBox(height: 30),
                    
                    // 设置项列表
                    _buildSettingsList(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: Row(
        children: [
          // 返回按钮
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.grey[800],
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.keyboard_arrow_down,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
          
          const Spacer(),
          
          // 标题
          const Text(
            '设置',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          
          const Spacer(),
          
          // 占位，保持居中
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildSettingsList() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _buildSettingsItem(
            icon: '🌍',
            title: '语言',
            subtitle: _currentLanguage,
            onTap: _handleLanguageSettings,
          ),
          _buildDivider(),
          _buildSettingsItem(
            icon: '🔒',
            title: '隐私政策',
            onTap: _handlePrivacyPolicy,
          ),
          _buildDivider(),
          _buildSettingsItem(
            icon: '⚙️',
            title: '系统设置',
            subtitle: '管理应用权限',
            onTap: _handleSystemSettings,
          ),
          _buildDivider(),
          _buildSettingsItem(
            icon: '💾',
            title: '清理缓存',
            subtitle: _cacheSize,
            onTap: _handleClearCache,
          ),
          _buildDivider(),
          _buildSettingsItem(
            icon: '❓',
            title: '帮助与反馈',
            onTap: _handleHelpAndFeedback,
          ),
          _buildDivider(),
          _buildSettingsItem(
            icon: 'ℹ️',
            title: '关于应用',
            subtitle: 'v1.0.0',
            onTap: _handleAboutApp,
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsItem({
    required String icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    bool isLast = false,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            // 图标
            Text(
              icon,
              style: const TextStyle(fontSize: 24),
            ),
            
            const SizedBox(width: 15),
            
            // 标题和副标题
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            
            // 箭头
            Icon(
              Icons.keyboard_arrow_right,
              color: Colors.grey[500],
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      margin: const EdgeInsets.only(left: 60),
      height: 0.5,
      color: Colors.grey[700],
    );
  }

  // 语言设置处理
  void _handleLanguageSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildLanguageSelector(),
    );
  }

  Widget _buildLanguageSelector() {
    return Container(
      height: 200,
      decoration: const BoxDecoration(
        color: Color(0xFF1C1C1C),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // 顶部指示条
          Container(
            margin: const EdgeInsets.only(top: 10),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[600],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // 标题
          const Text(
            '选择语言',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          
          const SizedBox(height: 20),
          
          // 语言选项
          _buildLanguageOption('中文', '中文'),
          _buildLanguageOption('English', 'English'),
        ],
      ),
    );
  }

  Widget _buildLanguageOption(String title, String value) {
    final isSelected = _currentLanguage == value;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentLanguage = value;
        });
        Navigator.pop(context);
        HapticFeedback.lightImpact();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        color: Colors.transparent,
        child: Row(
          children: [
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.blue : Colors.white,
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            
            const Spacer(),
            
            if (isSelected)
              const Icon(
                Icons.check,
                color: Colors.blue,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  // 隐私政策处理
  void _handlePrivacyPolicy() {
    debugPrint('打开隐私政策');
    // TODO: 实现隐私政策页面或WebView
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('隐私政策功能开发中...'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  // 系统设置处理
  void _handleSystemSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1C),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          '跳转系统设置',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          '即将跳转到系统设置页面，您可以在那里管理应用的相册权限、相机权限等。',
          style: TextStyle(color: Colors.grey[300]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              '取消',
              style: TextStyle(color: Colors.grey[400]),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _openSystemSettings();
            },
            child: const Text(
              '前往设置',
              style: TextStyle(color: Colors.blue),
            ),
          ),
        ],
      ),
    );
  }

  // 打开系统设置
  Future<void> _openSystemSettings() async {
    try {
      await openAppSettings();
      debugPrint('已跳转到系统设置');
    } catch (e) {
      debugPrint('跳转系统设置失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('跳转失败，请手动前往系统设置'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // 清理缓存处理
  void _handleClearCache() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1C),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          '清理缓存',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          '确定要清理 $_cacheSize 的缓存数据吗？',
          style: TextStyle(color: Colors.grey[300]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              '取消',
              style: TextStyle(color: Colors.grey[400]),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _performClearCache();
            },
            child: const Text(
              '清理',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _performClearCache() {
    // 模拟清理缓存
    setState(() {
      _cacheSize = '0MB';
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('缓存已清理完成'),
        backgroundColor: Colors.green,
      ),
    );
  }

  // 帮助与反馈处理
  void _handleHelpAndFeedback() {
    debugPrint('打开帮助与反馈');
    // TODO: 实现帮助与反馈页面
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('帮助与反馈功能开发中...'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  // 关于应用处理
  void _handleAboutApp() {
    debugPrint('打开关于应用');
    // TODO: 实现关于应用页面
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('关于应用功能开发中...'),
        backgroundColor: Colors.blue,
      ),
    );
  }
}
