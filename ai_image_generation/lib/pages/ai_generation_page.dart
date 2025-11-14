import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../widgets/index.dart';
import '../services/photoshoot_ai_service.dart';
import '../services/ai_model_service.dart';
import '../data/photoshoot_themes.dart';
import 'ai_result_page.dart';

class AIGenerationPage extends StatefulWidget {
  final List<String> photoPaths;
  final String? themeId; // 写真主题ID

  const AIGenerationPage({super.key, required this.photoPaths, this.themeId});

  @override
  State<AIGenerationPage> createState() => _AIGenerationPageState();
}

class _AIGenerationPageState extends State<AIGenerationPage>
    with TickerProviderStateMixin {
  late AnimationController _loadingController;
  late Animation<double> _rotationAnimation;

  Timer? _countdownTimer; // 倒计时定时器（保留用于清理）

  // AI处理相关状态
  List<String?> _generatedResults = []; // AI生成的结果列表
  int _currentProcessing = 0; // 当前处理的照片索引
  bool _isProcessing = false; // 是否正在处理

  @override
  void initState() {
    super.initState();
    _initAnimations();

    // 使用postFrameCallback确保在build完成后再开始AI处理
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startAIProcessing(); // 启动AI处理而不是倒计时
    });
  }

  void _initAnimations() {
    _loadingController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(_loadingController);

    _loadingController.repeat();
  }

  // 启动AI处理
  void _startAIProcessing() async {
    debugPrint('🔍 AIGenerationPage: 接收到的参数检查');
    debugPrint('🔍 主题ID: ${widget.themeId}');
    debugPrint('🔍 照片路径数量: ${widget.photoPaths.length}');
    debugPrint('🔍 照片路径列表: ${widget.photoPaths}');

    if (widget.themeId == null || widget.photoPaths.isEmpty) {
      debugPrint('❌ AIGenerationPage: 缺少主题ID或照片路径');
      debugPrint('❌ 主题ID为null: ${widget.themeId == null}');
      debugPrint('❌ 照片路径为空: ${widget.photoPaths.isEmpty}');
      // 延迟导航，避免在build期间调用
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) _navigateToResultPage();
      });
      return;
    }

    // 获取AI提示词
    final aiPrompt = PhotoshootThemes.getAIPrompt(widget.themeId!);
    if (aiPrompt.isEmpty) {
      debugPrint('❌ AIGenerationPage: 主题提示词为空');
      // 延迟导航，避免在build期间调用
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) _navigateToResultPage();
      });
      return;
    }

    debugPrint('🎬 开始AI写真生成，主题: ${widget.themeId}');
    debugPrint('📸 照片路径列表: ${widget.photoPaths}');
    debugPrint('📝 完整提示词长度: ${aiPrompt.length}字符');
    debugPrint(
      '📝 提示词前200字符: ${aiPrompt.substring(0, aiPrompt.length > 200 ? 200 : aiPrompt.length)}...',
    );

    // 1. 测试API连接
    debugPrint('🧪 开始测试API连接...');
    final apiConnected = await AIModelService.testConnection();
    debugPrint('🧪 API连接测试结果: $apiConnected');

    if (!apiConnected) {
      debugPrint('❌ API连接失败，将使用原图作为fallback');
    }

    // 2. 验证照片文件是否存在
    for (int i = 0; i < widget.photoPaths.length; i++) {
      final photoPath = widget.photoPaths[i];
      final file = File(photoPath);
      final exists = await file.exists();
      debugPrint('📷 照片${i + 1}: $photoPath - 存在: $exists');
      if (exists) {
        final fileSize = await file.length();
        debugPrint(
          '📏 照片${i + 1}大小: ${(fileSize / 1024).toStringAsFixed(1)}KB',
        );
      }
    }

    setState(() {
      _isProcessing = true;
      _currentProcessing = 0;
      _generatedResults = [];
    });

    try {
      // 调用PhotoshootAIService进行批量处理，添加超时控制
      final results =
          await PhotoshootAIService.generatePhotoshoot(
            themeId: widget.themeId!,
            userPhotos: widget.photoPaths,
            onProgress: (current, total, currentResult) {
              if (mounted) {
                setState(() {
                  _currentProcessing = current;
                  // 更新结果列表
                  if (_generatedResults.length < current) {
                    _generatedResults.add(currentResult);
                  } else if (_generatedResults.length >= current) {
                    _generatedResults[current - 1] = currentResult;
                  }
                });
              }
            },
          ).timeout(
            Duration(minutes: widget.photoPaths.length * 2), // 每张照片最多2分钟
            onTimeout: () {
              debugPrint('❌ AI写真生成超时');
              throw Exception('AI处理超时，请检查网络连接后重试');
            },
          );

      // 处理完成
      setState(() {
        _isProcessing = false;
        _generatedResults = results;
      });

      debugPrint(
        '🎉 AI写真生成完成，成功: ${results.where((r) => r != null).length}/${results.length}',
      );

      // 跳转到结果页面
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) _navigateToResultPage();
      });
    } catch (e) {
      debugPrint('❌ AI写真生成异常: $e');
      setState(() {
        _isProcessing = false;
      });
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) _navigateToResultPage();
      });
    }
  }

  // 跳转到AI生成结果页面
  void _navigateToResultPage() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => AIResultPage(
          originalPhotoPaths: widget.photoPaths,
          generatedPhotoPaths: _generatedResults, // 传递生成结果
          themeId: widget.themeId, // 传递主题ID
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.0, 1.0); // 从下方开始
          const end = Offset.zero; // 到达正常位置
          const curve = Curves.easeInOut;

          var tween = Tween(
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
  }

  @override
  void dispose() {
    _loadingController.dispose();
    _countdownTimer?.cancel(); // 取消倒计时定时器
    super.dispose();
  }

  // 处理增强功能 - 复用首页的增强功能
  Future<void> _handleEnhanceAction() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image != null) {
        debugPrint('选择了图片用于增强: ${image.path}');
        // 调用首页相同的增强底部sheet
        _showEnhanceBottomSheet(image.path);
      }
    } catch (e) {
      debugPrint('选择图片失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('选择图片失败：$e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // 显示增强功能的底部半屏 - 复用首页的实现
  void _showEnhanceBottomSheet(String imagePath) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // 允许控制高度
      backgroundColor: Colors.transparent,
      builder: (context) => EnhanceBottomSheet(imagePath: imagePath),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // 顶部导航栏
            _buildTopNavigation(),

            // 主要内容
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    const SizedBox(height: 20),

                    // 顶部横幅
                    _buildPromotionBanner(),

                    const SizedBox(height: 80),

                    // Loading区域
                    _buildLoadingArea(),

                    const Spacer(),

                    // 底部按钮
                    _buildNotificationButton(),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 顶部导航栏
  Widget _buildTopNavigation() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // 左侧下拉按钮
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(
              Icons.keyboard_arrow_down,
              color: Colors.white,
              size: 28,
            ),
          ),

          // 中央标题
          const Expanded(
            child: Center(
              child: Text(
                'AI照片',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          const SizedBox(width: 28), // 保持对称
        ],
      ),
    );
  }

  // 推广横幅
  Widget _buildPromotionBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // 左侧头像 - 使用Art Toy本地图片
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              image: const DecorationImage(
                image: AssetImage(
                  'assets/images/filters/art_toy_thumbnail.jpg',
                ),
                fit: BoxFit.cover,
              ),
            ),
          ),

          const SizedBox(width: 16),

          // 中间文字
          const Expanded(
            child: Text(
              '同时，一键即可增强照片！',
              style: TextStyle(
                color: Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          // 右侧按钮
          GestureDetector(
            onTap: _handleEnhanceAction,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                '增强',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Loading区域
  Widget _buildLoadingArea() {
    return Column(
      children: [
        // Loading转圈
        AnimatedBuilder(
          animation: _rotationAnimation,
          builder: (context, child) {
            return Transform.rotate(
              angle: _rotationAnimation.value * 2.0 * 3.14159,
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey[800]!, width: 3),
                ),
                child: CustomPaint(painter: AILoadingPainter()),
              ),
            );
          },
        ),

        const SizedBox(height: 40),

        // 状态文字
        const Text(
          '我们正在生成您的\n照片...',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
            height: 1.3,
          ),
        ),

        const SizedBox(height: 20),

        // 预计时间
        Text(
          _isProcessing
              ? '正在处理第 $_currentProcessing/${widget.photoPaths.length} 张照片...'
              : '准备开始处理...',
          style: TextStyle(color: Colors.grey[400], fontSize: 16),
        ),
      ],
    );
  }

  // 底部通知按钮（已隐藏）
  Widget _buildNotificationButton() {
    return const SizedBox.shrink(); // 隐藏按钮
  }
}

// AI Loading画笔
class AILoadingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color =
          const Color(0xFFEF4444) // 红色
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 1.5;

    // 绘制部分圆弧（模拟loading效果）
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -3.14159 / 2, // 从顶部开始
      3.14159 * 1.2, // 绘制3/4圆
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(AILoadingPainter oldDelegate) => false;
}
