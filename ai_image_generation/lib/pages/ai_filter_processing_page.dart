import 'package:flutter/material.dart';
import 'dart:io';
import 'ai_filter_result_page.dart';

class AiFilterProcessingPage extends StatefulWidget {
  final String imagePath;
  final String filterId;

  const AiFilterProcessingPage({
    super.key,
    required this.imagePath,
    required this.filterId,
  });

  @override
  State<AiFilterProcessingPage> createState() => _AiFilterProcessingPageState();
}

class _AiFilterProcessingPageState extends State<AiFilterProcessingPage>
    with TickerProviderStateMixin {
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    
    // 初始化动画控制器
    _progressController = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    );
    
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOut,
    ));

    // 自动显示处理模态框
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showProcessingModal();
    });
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  '准备处理您的照片...',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // 显示选中的图片
                Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    image: DecorationImage(
                      image: FileImage(File(widget.imagePath)),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                
                const SizedBox(height: 20),
                
                Text(
                  '滤镜: ${widget.filterId}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 显示处理模态框
  void _showProcessingModal() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _ProcessingModal(
        imagePath: widget.imagePath,
        onUploadComplete: _onUploadComplete,
        onCancel: _onCancel,
        progressAnimation: _progressAnimation,
      ),
    );

    // 开始处理
    _startProcessing();
  }

  // 开始处理
  Future<void> _startProcessing() async {
    // 开始进度动画
    _progressController.forward();

    // 模拟处理时间（5秒）
    await Future.delayed(const Duration(seconds: 5));

    if (mounted) {
      _onUploadComplete();
    }
  }

  // 处理完成
  void _onUploadComplete() {
    if (mounted) {
      Navigator.pop(context); // 关闭模态框
      
      // 跳转到结果页面
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => AiFilterResultPage(
            originalImagePath: widget.imagePath,
            filterId: widget.filterId,
          ),
        ),
      );
    }
  }

  // 取消处理
  void _onCancel() {
    _progressController.stop();
    
    if (mounted) {
      Navigator.pop(context); // 关闭模态框
      Navigator.pop(context); // 返回上一页
    }
  }
}

// 处理模态框组件
class _ProcessingModal extends StatelessWidget {
  final String imagePath;
  final VoidCallback onUploadComplete;
  final VoidCallback onCancel;
  final Animation<double> progressAnimation;

  const _ProcessingModal({
    required this.imagePath,
    required this.onUploadComplete,
    required this.onCancel,
    required this.progressAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 关闭按钮
            Align(
              alignment: Alignment.topLeft,
              child: GestureDetector(
                onTap: onCancel,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // 图片预览
            Container(
              width: 200,
              height: 250,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                image: DecorationImage(
                  image: FileImage(File(imagePath)),
                  fit: BoxFit.cover,
                ),
              ),
              child: Stack(
                children: [
                  // 红色进度点动画
                  Positioned(
                    top: 20,
                    right: 20,
                    child: AnimatedBuilder(
                      animation: progressAnimation,
                      builder: (context, child) {
                        return Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        );
                      },
                    ),
                  ),
                  
                  // 中间处理文字
                  const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '正在上传照片...',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            shadows: [
                              Shadow(
                                color: Colors.black54,
                                offset: Offset(0, 1),
                                blurRadius: 2,
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          '取消',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            shadows: [
                              Shadow(
                                color: Colors.black54,
                                offset: Offset(0, 1),
                                blurRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // 上传按钮
            GestureDetector(
              onTap: onUploadComplete,
              child: Container(
                width: double.infinity,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Center(
                  child: Text(
                    '上传自照',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // 提示文字
            const Text(
              '这可能需要数秒钟，请不要退出应用。',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.black54,
                fontSize: 12,
              ),
            ),
            
            const SizedBox(height: 8),
            
            // 进度条
            AnimatedBuilder(
              animation: progressAnimation,
              builder: (context, child) {
                return LinearProgressIndicator(
                  value: progressAnimation.value,
                  backgroundColor: Colors.grey[300],
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.red),
                  minHeight: 3,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
