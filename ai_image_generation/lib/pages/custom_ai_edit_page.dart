import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:photo_manager/photo_manager.dart';
import 'custom_ai_edit_chat_page.dart';

class CustomAiEditPage extends StatefulWidget {
  const CustomAiEditPage({super.key});

  @override
  State<CustomAiEditPage> createState() => _CustomAiEditPageState();
}

class _CustomAiEditPageState extends State<CustomAiEditPage>
    with TickerProviderStateMixin {
  // 动画控制器
  late AnimationController _typewriterController;
  late AnimationController _buttonController;
  late AnimationController _imageController;

  // 动画
  late Animation<double> _buttonPulseAnimation;
  late Animation<double> _imageOpacityAnimation;

  // 当前演示状态
  int _currentDemoIndex = 0;
  String _displayedText = '';
  Timer? _autoSwitchTimer;
  Timer? _typewriterTimer;

  // 默认图片路径
  String? _defaultImagePath;

  // 演示数据
  final List<DemoData> _demoList = [
    DemoData(
      text: 'Neutral background',
      backgroundColor: Color(0xFFE8F4F8),
      hasSparkles: true,
      filterType: FilterType.neutral,
    ),
    DemoData(
      text: 'Professional outfit',
      backgroundColor: Color(0xFFF0F8FF),
      hasSparkles: false,
      filterType: FilterType.professional,
    ),
    DemoData(
      text: 'Anime style',
      backgroundColor: Color(0xFFFFF8E7),
      hasSparkles: false,
      filterType: FilterType.anime,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadDefaultImage();
    _startDemoLoop();
  }

  // 加载相册第一张图片作为默认图片
  Future<void> _loadDefaultImage() async {
    try {
      // 请求相册权限
      final PermissionState permission =
          await PhotoManager.requestPermissionExtend();
      if (permission.isAuth) {
        // 获取相册列表
        final List<AssetPathEntity> albums =
            await PhotoManager.getAssetPathList(
              type: RequestType.image,
              onlyAll: true,
            );

        if (albums.isNotEmpty) {
          // 获取第一个相册（通常是所有照片）
          final AssetPathEntity album = albums.first;
          // 获取相册中的第一张照片
          final List<AssetEntity> assets = await album.getAssetListPaged(
            page: 0,
            size: 1,
          );

          if (assets.isNotEmpty) {
            final AssetEntity asset = assets.first;
            final File? file = await asset.file;
            if (file != null && mounted) {
              setState(() {
                _defaultImagePath = file.path;
              });
              debugPrint('成功加载默认图片: ${file.path}');
            }
          }
        }
      } else {
        debugPrint('没有相册权限，使用默认背景');
      }
    } catch (e) {
      debugPrint('加载默认图片失败: $e');
    }
  }

  void _initializeAnimations() {
    // 打字机动画控制器
    _typewriterController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // 按钮脉动动画控制器
    _buttonController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _buttonPulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _buttonController, curve: Curves.easeInOut),
    );

    // 图片切换动画控制器
    _imageController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _imageOpacityAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _imageController, curve: Curves.easeInOut),
    );
  }

  void _startDemoLoop() {
    _showCurrentDemo();
    _autoSwitchTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      _switchToNextDemo();
    });
  }

  void _showCurrentDemo() {
    final currentDemo = _demoList[_currentDemoIndex];
    _startTypewriterAnimation(currentDemo.text);
  }

  void _startTypewriterAnimation(String text) {
    _displayedText = '';
    _typewriterController.reset();

    int charIndex = 0;
    _typewriterTimer?.cancel();
    _typewriterTimer = Timer.periodic(const Duration(milliseconds: 80), (
      timer,
    ) {
      if (charIndex < text.length) {
        setState(() {
          _displayedText = text.substring(0, charIndex + 1);
        });
        charIndex++;
      } else {
        timer.cancel();
        _typewriterController.forward();
        Future.delayed(const Duration(milliseconds: 2000), () {
          if (mounted) {
            _triggerButtonAnimation();
          }
        });
      }
    });
  }

  void _triggerButtonAnimation() {
    _buttonController.forward().then((_) {
      _buttonController.reverse();
    });
  }

  // 修改切换方法，只改变滤镜效果，不重新加载图片
  Future<void> _switchToNextDemo() async {
    // 切换到下一个演示（只改变滤镜效果）
    setState(() {
      _currentDemoIndex = (_currentDemoIndex + 1) % _demoList.length;
    });

    // 开始新的演示
    _showCurrentDemo();
  }

  @override
  void dispose() {
    _typewriterController.dispose();
    _buttonController.dispose();
    _imageController.dispose();
    _autoSwitchTimer?.cancel();
    _typewriterTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentDemo = _demoList[_currentDemoIndex];

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // 顶部导航栏
            _buildTopBar(),

            const SizedBox(height: 20),

            // 主演示区域
            Expanded(flex: 2, child: _buildDemoArea(currentDemo)),

            const SizedBox(height: 30),

            // 底部描述和按钮区域
            Expanded(flex: 1, child: _buildBottomArea()),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          // 关闭按钮
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(Icons.close, color: Colors.white, size: 24),
          ),

          // 标题
          const Expanded(
            child: Center(
              child: Text(
                '自定义 AI 编辑',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          // 占位
          const SizedBox(width: 24),
        ],
      ),
    );
  }

  Widget _buildDemoArea(DemoData demo) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // 背景图片
            Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: demo.backgroundColor,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                // child: FadeTransition(
                //   opacity: ReverseAnimation(_imageOpacityAnimation),
                //   child: _buildFilteredImage(demo),
                // ),
                child: _buildFilteredImage(demo), // 直接显示，去掉动画
              ),
            ),

            // 星光效果（仅第一个演示显示）
            if (demo.hasSparkles) _buildSparkleEffect(),

            // 底部文字和按钮一体容器 - 简化版本
            Positioned(
              left: 24,
              right: 24,
              bottom: 24,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Row(
                  children: [
                    // 文字区域 - 恢复动态显示
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(
                          left: 12,
                          top: 8,
                          bottom: 8,
                        ),
                        child: Text(
                          _displayedText,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    // 装饰性按钮 - 恢复动画
                    ScaleTransition(
                      scale: _buttonPulseAnimation,
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: const Icon(
                          Icons.arrow_forward,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 构建带滤镜效果的图片 - 恢复滤镜效果
  Widget _buildFilteredImage(DemoData demo) {
    return ColorFiltered(
      colorFilter: _getColorFilter(demo.filterType),
      child: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(color: demo.backgroundColor),
        child: _defaultImagePath != null
            ? Image.file(
                File(_defaultImagePath!),
                fit: BoxFit.cover,
                key: const ValueKey('gallery_image'),
              )
            : Container(
                color: demo.backgroundColor,
                child: const Center(
                  child: Text(
                    '正在加载相册图片...',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                ),
              ),
      ),
    );
  }

  // 始终可见的内容（避免空白）
  Widget _buildAlwaysVisibleContent(DemoData demo) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      child: Stack(
        children: [
          // 中心人物图标
          Center(
            child: Container(
              width: 120,
              height: 150,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(60),
              ),
              child: const Icon(Icons.person, size: 60, color: Colors.white54),
            ),
          ),
          // 装饰元素
          Positioned(
            top: 80,
            right: 60,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: 100,
            left: 70,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 根据滤镜类型获取ColorFilter
  ColorFilter _getColorFilter(FilterType filterType) {
    switch (filterType) {
      case FilterType.neutral:
        // 原图，轻微增强对比度
        return const ColorFilter.matrix([
          1.1,
          0,
          0,
          0,
          0,
          0,
          1.1,
          0,
          0,
          0,
          0,
          0,
          1.1,
          0,
          0,
          0,
          0,
          0,
          1,
          0,
        ]);
      case FilterType.professional:
        // 专业风格：增加对比度和饱和度
        return const ColorFilter.matrix([
          1.2,
          0,
          0,
          0,
          10,
          0,
          1.2,
          0,
          0,
          10,
          0,
          0,
          1.2,
          0,
          10,
          0,
          0,
          0,
          1,
          0,
        ]);
      case FilterType.anime:
        // 动漫风格：高饱和度，偏暖色调
        return const ColorFilter.matrix([
          1.3,
          0.1,
          0,
          0,
          20,
          0,
          1.2,
          0.1,
          0,
          0,
          0,
          0,
          1.4,
          0,
          0,
          0,
          0,
          0,
          1,
          0,
        ]);
    }
  }

  Widget _buildSparkleEffect() {
    return Positioned.fill(child: CustomPaint(painter: SparklePainter()));
  }

  Widget _buildBottomArea() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          // 标题和描述
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '自定义 AI 编辑',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('💬', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),

          const SizedBox(height: 12),

          const Text(
            '直接向 Remini 请求对照片的任何编辑，比以往更加简单',
            style: TextStyle(color: Colors.white70, fontSize: 17, height: 1.4),
            textAlign: TextAlign.center,
          ),

          const Spacer(),

          // 上传图片按钮
          GestureDetector(
            onTap: _uploadImage,
            child: Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
              ),
              child: const Center(
                child: Text(
                  '上传图片',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Future<void> _uploadImage() async {
    final ImagePicker picker = ImagePicker();
    
    try {
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      
      if (image != null && mounted) {
        // 跳转到聊天页面
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CustomAiEditChatPage(
              userImagePath: image.path,
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('选择图片失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('选择图片失败：$e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

// 滤镜类型枚举
enum FilterType {
  neutral, // 原图
  professional, // 专业风格
  anime, // 动漫风格
}

// 演示数据模型
class DemoData {
  final String text;
  final Color backgroundColor;
  final bool hasSparkles;
  final FilterType filterType;

  DemoData({
    required this.text,
    required this.backgroundColor,
    required this.hasSparkles,
    required this.filterType,
  });
}

// 星光效果绘制器
class SparklePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    // 绘制多个星光
    final sparkles = [
      Offset(size.width * 0.2, size.height * 0.15),
      Offset(size.width * 0.8, size.height * 0.25),
      Offset(size.width * 0.15, size.height * 0.4),
      Offset(size.width * 0.85, size.height * 0.6),
      Offset(size.width * 0.25, size.height * 0.75),
      Offset(size.width * 0.75, size.height * 0.8),
    ];

    for (final sparkle in sparkles) {
      _drawSparkle(canvas, paint, sparkle, 8);
    }
  }

  void _drawSparkle(Canvas canvas, Paint paint, Offset center, double size) {
    // 画十字星光
    canvas.drawLine(
      Offset(center.dx - size / 2, center.dy),
      Offset(center.dx + size / 2, center.dy),
      paint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - size / 2),
      Offset(center.dx, center.dy + size / 2),
      paint,
    );

    // 画对角线
    canvas.drawLine(
      Offset(center.dx - size / 3, center.dy - size / 3),
      Offset(center.dx + size / 3, center.dy + size / 3),
      paint,
    );
    canvas.drawLine(
      Offset(center.dx + size / 3, center.dy - size / 3),
      Offset(center.dx - size / 3, center.dy + size / 3),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
