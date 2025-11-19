import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:async';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:permission_handler/permission_handler.dart';
import 'effect_preview_page.dart';
import '../services/generation_history_api_service.dart';

// 处理状态枚举
enum ProcessingState {
  initial, // 初始状态，显示原图和增强按钮
  uploading, // 正在上传照片
  processing, // 正在重构细节
  showingTip, // 显示面部修饰提示
  completed, // 处理完成，显示对比结果
}

class ImageEnhancePage extends StatefulWidget {
  final String? imagePath;
  final String? enhancedImagePath;

  const ImageEnhancePage({
    super.key,
    required this.imagePath,
    this.enhancedImagePath,
  });

  @override
  State<ImageEnhancePage> createState() => _ImageEnhancePageState();
}

class _ImageEnhancePageState extends State<ImageEnhancePage>
    with TickerProviderStateMixin {
  late AnimationController _loadingController;
  double _sliderPosition = 0.5; // 分割线位置，0.0-1.0
  bool _showTipDialog = true; // 控制是否显示提示弹窗
  bool _isProcessingTool = false; // 是否正在处理工具效果
  String _selectedToolId = 'face_retouch'; // 当前选中的工具ID
  String? _processedImagePath; // 处理后的图片路径

  @override
  void initState() {
    super.initState();

    // 加载动画控制器
    _loadingController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    // 如果有增强后的图片，立即同步到生成历史
    if (widget.enhancedImagePath != null) {
      unawaited(
        GenerationHistoryApiService.syncGenerationResult(
          localFilePath: widget.enhancedImagePath!,
          type: 'enhance',
        ).catchError((e, stack) {
          debugPrint('同步增强历史失败: $e');
        }),
      );
    }
  }

  @override
  void dispose() {
    _loadingController.dispose();
    super.dispose();
  }

  // 关闭提示弹窗
  void _dismissTipDialog() {
    setState(() {
      _showTipDialog = false;
    });
  }

  // 下载图片到相册
  Future<void> _downloadImage() async {
    try {
      // 优先下载处理后的图片，如果没有则下载原图
      final String? imageToDownload =
          _processedImagePath ?? widget.enhancedImagePath ?? widget.imagePath;

      if (imageToDownload == null) {
        _showBeautifulDialog('没有可下载的图片', isError: true);
        return;
      }

      // 请求存储权限
      PermissionStatus permission;
      if (Platform.isAndroid) {
        permission = await Permission.storage.request();
      } else {
        permission = await Permission.photos.request();
      }

      if (permission != PermissionStatus.granted) {
        _showBeautifulDialog('需要相册权限才能保存图片', isError: true);
        return;
      }

      // 读取图片文件
      final File imageFile = File(imageToDownload);
      if (!await imageFile.exists()) {
        _showBeautifulDialog('图片文件不存在', isError: true);
        return;
      }

      // 保存到相册
      final result = await ImageGallerySaver.saveFile(
        imageToDownload,
        name: 'remini_enhanced_${DateTime.now().millisecondsSinceEpoch}',
      );

      if (result['isSuccess'] == true) {
        _showBeautifulDialog('图片已保存到相册');
      } else {
        _showBeautifulDialog('保存失败，请重试', isError: true);
      }
    } catch (e) {
      debugPrint('下载图片失败: $e');
      _showBeautifulDialog('保存失败: ${e.toString()}', isError: true);
    }
  }

  // 显示漂亮的弹窗消息
  void _showBeautifulDialog(String message, {bool isError = false}) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 图标
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: isError
                        ? Colors.red.withOpacity(0.1)
                        : Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Icon(
                    isError ? Icons.error_outline : Icons.check_circle_outline,
                    color: isError ? Colors.red : Colors.green,
                    size: 30,
                  ),
                ),

                const SizedBox(height: 16),

                // 标题
                Text(
                  isError ? '操作失败' : '保存成功',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),

                const SizedBox(height: 8),

                // 消息内容
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                    height: 1.4,
                  ),
                ),

                const SizedBox(height: 20),

                // 确定按钮
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isError ? Colors.red : Colors.green,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      '确定',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    // 3秒后自动关闭（仅成功时）
    if (!isError) {
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted && Navigator.canPop(context)) {
          Navigator.of(context).pop();
        }
      });
    }
  }

  // 开始工具处理
  void _startToolProcessing(String toolId) async {
    setState(() {
      _selectedToolId = toolId;
      _isProcessingTool = true;
    });

    _loadingController.repeat();

    // 模拟处理时间（3秒）
    await Future.delayed(const Duration(seconds: 3));

    if (mounted) {
      _loadingController.stop();
      setState(() {
        _isProcessingTool = false;
      });

      // 跳转到效果预览页面并等待返回结果
      final result = await Navigator.push<String>(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              EffectPreviewPage(
                imagePath:
                    _processedImagePath ??
                    widget.enhancedImagePath ??
                    widget.imagePath!, // 🔥 使用当前显示的图片
                effectType: toolId,
              ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0); // 从右侧滑入
            const end = Offset.zero;
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
          transitionDuration: const Duration(milliseconds: 300),
        ),
      );

      // 处理返回的结果
      if (result != null && result.isNotEmpty) {
        debugPrint('✅ 接收到处理后的图片: $result');
        setState(() {
          _processedImagePath = result; // 更新处理后的图片路径
        });
      }
    }
  }

  // 取消工具处理
  void _cancelToolProcessing() {
    _loadingController.stop();
    setState(() {
      _isProcessingTool = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 背景遮罩
          Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.black.withOpacity(0.8),
          ),

          // 主要内容 - 直接显示完成状态的对比页面
          _buildCompletedView(),

          // 底部处理进度栏
          if (_isProcessingTool) _buildProcessingBar(),

          // 面部修饰提示弹窗 - 进入时立即显示
          if (_showTipDialog) _buildTipDialog(),
        ],
      ),
    );
  }

  // 完成视图：显示对比结果
  Widget _buildCompletedView() {
    return Column(
      children: [
        // 顶部操作栏
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // 关闭按钮
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),

                const Spacer(),

                // 效果标题
                const Text(
                  '效果',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const Spacer(),

                // 下载按钮
                GestureDetector(
                  onTap: _downloadImage,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.download,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // 对比图片区域
        Expanded(child: _buildComparisonView()),

        // 底部功能栏
        _buildBottomToolbar(),
      ],
    );
  }

  // 对比视图：可拖动分割线
  Widget _buildComparisonView() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            // 左右两张完整的图片
            Row(
              children: [
                // 左侧：原图（保持真实色彩）
                Expanded(
                  flex: (_sliderPosition * 100).round(),
                  child: widget.imagePath != null
                      ? Image.file(
                          File(widget.imagePath!),
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                        )
                      : Container(color: Colors.grey.shade700),
                ),

                // 右侧：处理后图片
                Expanded(
                  flex: ((1 - _sliderPosition) * 100).round(),
                  child: _processedImagePath != null
                      ? Image.file(
                          File(_processedImagePath!), // 🔥 优先显示工具处理后的图片
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                        )
                      : (widget.enhancedImagePath != null
                            ? Image.file(
                                File(
                                  widget.enhancedImagePath!,
                                ), // 🎯 次选AI增强后的图片
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                              )
                            : (widget.imagePath != null
                                  ? Image.file(
                                      File(widget.imagePath!), // 最后回退到原图
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      height: double.infinity,
                                    )
                                  : Container(color: Colors.grey.shade800))),
                ),
              ],
            ),

            // 标签
            Positioned(
              top: 20,
              left: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Text(
                  '处理前',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ),

            Positioned(
              top: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Text(
                  '处理后',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ),

            // 中间分割线
            Positioned(
              left:
                  (MediaQuery.of(context).size.width - 40) * _sliderPosition -
                  1,
              top: 0,
              bottom: 0,
              width: 2,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 0),
                    ),
                  ],
                ),
              ),
            ),

            // 拖动手柄
            Positioned(
              left:
                  (MediaQuery.of(context).size.width - 40) * _sliderPosition -
                  20,
              top: MediaQuery.of(context).size.height * 0.4,
              child: GestureDetector(
                onPanUpdate: (details) {
                  setState(() {
                    final screenWidth = MediaQuery.of(context).size.width - 40;
                    final newPosition =
                        (details.globalPosition.dx - 20) / screenWidth;
                    _sliderPosition = newPosition.clamp(
                      0.1,
                      0.9,
                    ); // 限制在10%-90%之间
                  });
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.compare_arrows,
                    color: Colors.black,
                    size: 20,
                  ),
                ),
              ),
            ),

            // 全屏拖动区域（透明）
            Positioned.fill(
              child: GestureDetector(
                onPanUpdate: (details) {
                  setState(() {
                    final screenWidth = MediaQuery.of(context).size.width - 40;
                    final newPosition =
                        (details.globalPosition.dx - 20) / screenWidth;
                    _sliderPosition = newPosition.clamp(0.1, 0.9);
                  });
                },
                child: Container(color: Colors.transparent),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 底部工具栏
  Widget _buildBottomToolbar() {
    final tools = [
      {
        'id': 'background_blur',
        'icon': Icons.blur_on,
        'label': 'Background\nBlur',
      },
      {'id': 'colors', 'icon': Icons.color_lens, 'label': 'Colors'},
      {
        'id': 'background_enhancer',
        'icon': Icons.landscape,
        'label': 'Background\nEnhancer',
      },
      {
        'id': 'face_retouch',
        'icon': Icons.face_retouching_natural,
        'label': 'Face\nRetouch',
      },
      {'id': 'face_enhancer', 'icon': Icons.face, 'label': 'Face\nEnhancer'},
    ];

    return SafeArea(
      child: Container(
        height: 80,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: tools.map((tool) {
            final toolId = tool['id'] as String;
            final isSelected = toolId == _selectedToolId;
            return GestureDetector(
              onTap: () {
                if (!_isProcessingTool) {
                  _startToolProcessing(toolId);
                }
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white54, width: 1),
                    ),
                    child: Icon(
                      tool['icon'] as IconData,
                      color: isSelected ? Colors.black : Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    tool['label'] as String,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white70,
                      fontSize: 10,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // 底部处理进度栏
  Widget _buildProcessingBar() {
    return Positioned(
      bottom: 100, // 位于工具栏上方
      left: 0,
      right: 0,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.8),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            // 进度条
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 进度条
                  Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: AnimatedBuilder(
                      animation: _loadingController,
                      builder: (context, child) {
                        return FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: _loadingController.value,
                          child: Container(
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 8),

                  // 加工文字
                  const Text(
                    '加工...',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 16),

            // 关闭按钮
            GestureDetector(
              onTap: _cancelToolProcessing,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 面部修饰提示弹窗
  Widget _buildTipDialog() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.5),
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 40),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 图标
                Container(
                  width: 80,
                  height: 80,
                  decoration: const BoxDecoration(
                    color: Colors.pink,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(40),
                      topRight: Radius.circular(40),
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(40),
                    ),
                  ),
                  child: const Icon(Icons.face, color: Colors.white, size: 40),
                ),

                const SizedBox(height: 16),

                // 标题
                const Text(
                  '面部修饰',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),

                const SizedBox(height: 12),

                // 说明文字
                const Text(
                  '面部修饰是一个受欢迎的功能，但仅负责任地使用。\n\n如果你发现这些增强功能影响了你的自我形象或自信心，请知道你可以随时在设置中的增强工具偏好关闭面部修饰功能。\n\n你的形象，你做主。',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 24),

                // 确认按钮
                GestureDetector(
                  onTap: _dismissTipDialog,
                  child: Container(
                    width: double.infinity,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Center(
                      child: Text(
                        '好的，我知道了',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
