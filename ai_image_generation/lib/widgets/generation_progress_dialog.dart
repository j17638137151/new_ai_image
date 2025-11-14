import 'package:flutter/material.dart';

class GenerationProgressDialog extends StatefulWidget {
  final VoidCallback? onDismiss;
  
  const GenerationProgressDialog({super.key, this.onDismiss});

  @override
  State<GenerationProgressDialog> createState() => _GenerationProgressDialogState();
}

class _GenerationProgressDialogState extends State<GenerationProgressDialog>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _scaleController;

  @override
  void initState() {
    super.initState();
    
    // 齿轮旋转动画
    _rotationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
    
    // 缩放动画
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _scaleController.forward();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: Tween<double>(begin: 0.8, end: 1.0).animate(
        CurvedAnimation(parent: _scaleController, curve: Curves.easeOutBack),
      ),
      child: Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 动画图标区域
              _buildAnimatedIcon(),
              
              const SizedBox(height: 24),
              
              // 标题
              const Text(
                '我们仍在生成您的效果',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              
              const SizedBox(height: 16),
              
              // 描述文本
              const Text(
                '您需要等待当前生成完成后才能请求其他内容。请稍后再试！',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              
              const SizedBox(height: 24),
              
              // 确认按钮
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  widget.onDismiss?.call();
                },
                child: Container(
                  width: double.infinity,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(25),
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
    );
  }

  Widget _buildAnimatedIcon() {
    return SizedBox(
      width: 120,
      height: 80,
      child: Stack(
        children: [
          // 背景装饰形状
          Positioned(
            left: 10,
            top: 10,
            child: Container(
              width: 100,
              height: 60,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFFFF8A65).withValues(alpha: 0.3),
                    const Color(0xFFFFAB91).withValues(alpha: 0.2),
                    const Color(0xFFFFCC02).withValues(alpha: 0.3),
                  ],
                ),
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
          
          // 左侧照片
          Positioned(
            left: 0,
            top: 15,
            child: Container(
              width: 48,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200&h=200&fit=crop&crop=face',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey.shade300,
                      child: const Icon(Icons.person, color: Colors.grey),
                    );
                  },
                ),
              ),
            ),
          ),
          
          // 右侧照片
          Positioned(
            right: 0,
            top: 5,
            child: Container(
              width: 48,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  'https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?w=200&h=200&fit=crop&crop=face',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey.shade300,
                      child: const Icon(Icons.person, color: Colors.grey),
                    );
                  },
                ),
              ),
            ),
          ),
          
          // 中心旋转齿轮
          Positioned(
            left: 35,
            top: 20,
            child: AnimatedBuilder(
              animation: _rotationController,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _rotationController.value * 2 * 3.14159,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.settings,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                );
              },
            ),
          ),
          
          // 小装饰齿轮
          Positioned(
            right: 15,
            bottom: 5,
            child: AnimatedBuilder(
              animation: _rotationController,
              builder: (context, child) {
                return Transform.rotate(
                  angle: -_rotationController.value * 1.5 * 3.14159,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF4757),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.settings,
                      color: Colors.white,
                      size: 10,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
