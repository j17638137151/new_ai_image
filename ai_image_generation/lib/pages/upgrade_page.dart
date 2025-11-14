import 'package:flutter/material.dart';

class UpgradePage extends StatefulWidget {
  const UpgradePage({super.key});

  @override
  State<UpgradePage> createState() => _UpgradePageState();
}

class _UpgradePageState extends State<UpgradePage> {
  
  // 功能列表数据
  final List<Map<String, dynamic>> _features = [
    {
      'icon': Icons.desktop_windows,
      'title': '桌面访问权限',
      'free': false,
      'pro': true,
    },
    {
      'icon': Icons.video_library,
      'title': '视频增强',
      'free': false,
      'pro': true,
    },
    {
      'icon': Icons.blur_on,
      'title': 'Background Blur',
      'free': false,
      'pro': true,
    },
    {
      'icon': Icons.color_lens,
      'title': 'Colors',
      'free': false,
      'pro': true,
    },
    {
      'icon': Icons.landscape,
      'title': 'Background Enhancer',
      'free': false,
      'pro': true,
    },
    {
      'icon': Icons.face_retouching_natural,
      'title': 'Face Retouch',
      'free': false,
      'pro': true,
    },
    {
      'icon': Icons.face,
      'title': 'Face Enhancer',
      'free': false,
      'pro': true,
    },
    {
      'icon': Icons.auto_awesome,
      'title': '更多AI照片',
      'free': true,
      'pro': true,
    },
    {
      'icon': Icons.filter_vintage,
      'title': '更多AI滤镜',
      'free': true,
      'pro': true,
    },
    {
      'icon': Icons.block,
      'title': '无广告',
      'free': false,
      'pro': true,
    },
    {
      'icon': Icons.arrow_downward,
      'title': '更多照片增强功能',
      'free': false,
      'pro': true,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // 顶部导航栏
          _buildTopBar(),
          
          // 可滚动内容
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // 营销卡片
                  _buildMarketingCard(),
                  
                  const SizedBox(height: 20),
                  
                  // 功能对比表
                  _buildFeatureComparison(),
                  
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
          
          // 底部升级按钮
          _buildUpgradeButton(),
        ],
      ),
    );
  }

  // 顶部导航栏
  Widget _buildTopBar() {
    return SafeArea(
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            // 关闭按钮
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: const Icon(
                Icons.close,
                color: Colors.black54,
                size: 24,
              ),
            ),
            
            // 标题
            const Expanded(
              child: Center(
                child: Text(
                  '升级套餐',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
            
            // 占位，保持标题居中
            const SizedBox(width: 24),
          ],
        ),
      ),
    );
  }

  // 营销卡片
  Widget _buildMarketingCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      height: 180,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFF6B9D),
            Color(0xFFFFB5C1),
            Color(0xFFFFC5D1),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.pink.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // 装饰性背景图案
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0.8, -0.5),
                    radius: 1.0,
                    colors: [
                      Colors.white.withOpacity(0.2),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          
          // 左侧文字内容
          Positioned(
            left: 24,
            top: 24,
            bottom: 24,
            right: 120,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  '消除限制',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: Colors.black26,
                        offset: Offset(0, 1),
                        blurRadius: 2,
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 8),
                
                const Text(
                  '升级到Pro',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                
                const SizedBox(height: 4),
                
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: const Text(
                    '¥30.00/周',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // 右侧人物剪影和装饰
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            width: 120,
            child: Stack(
              children: [
                // 人物剪影背景
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            Colors.white.withOpacity(0.1),
                            Colors.white.withOpacity(0.3),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                
                // 人物图标（更有设计感）
                Center(
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(40),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.4),
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.person,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),
                ),
                
                // PRO标签
                Positioned(
                  top: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF1744),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Text(
                      'PRO',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
                
                // 装饰性光点
                Positioned(
                  top: 40,
                  right: 30,
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                
                Positioned(
                  bottom: 50,
                  right: 45,
                  child: Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 功能对比表
  Widget _buildFeatureComparison() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          // 表头
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            child: Row(
              children: [
                const Expanded(
                  flex: 3,
                  child: Text(
                    '套餐内容',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                ),
                const Expanded(
                  flex: 1,
                  child: Text(
                    '现在',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                  ),
                ),
                const Expanded(
                  flex: 1,
                  child: Text(
                    'Pro',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // 功能列表
          ...List.generate(_features.length, (index) {
            final feature = _features[index];
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Colors.grey.shade200,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  // 功能名称和图标
                  Expanded(
                    flex: 3,
                    child: Row(
                      children: [
                        Icon(
                          feature['icon'] as IconData,
                          size: 20,
                          color: Colors.black54,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            feature['title'] as String,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // 免费版状态
                  Expanded(
                    flex: 1,
                    child: Center(
                      child: Icon(
                        feature['free'] as bool ? Icons.check : Icons.close,
                        size: 20,
                        color: feature['free'] as bool ? Colors.green : Colors.red,
                      ),
                    ),
                  ),
                  
                  // Pro版状态
                  Expanded(
                    flex: 1,
                    child: Center(
                      child: Icon(
                        feature['pro'] as bool ? Icons.check : Icons.close,
                        size: 20,
                        color: feature['pro'] as bool ? Colors.green : Colors.red,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // 底部升级按钮
  Widget _buildUpgradeButton() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 升级按钮
            GestureDetector(
              onTap: _handleUpgrade,
              child: Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: const Center(
                  child: Text(
                    '升级到Pro',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 12),
            
            // 价格信息
            const Text(
              '总价¥68.00/周',
              style: TextStyle(
                fontSize: 14,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 处理升级
  void _handleUpgrade() {
    // TODO: 实现升级逻辑
    debugPrint('用户点击升级');
    
    // 临时显示成功提示
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('升级功能待实现'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}
