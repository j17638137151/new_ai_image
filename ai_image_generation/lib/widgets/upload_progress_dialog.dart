import 'package:flutter/material.dart';
import 'dart:async';

class UploadProgressDialog extends StatefulWidget {
  final VoidCallback onComplete;
  final int totalPhotos; // 总照片数量
  
  const UploadProgressDialog({
    super.key,
    required this.onComplete,
    required this.totalPhotos,
  });

  @override
  State<UploadProgressDialog> createState() => _UploadProgressDialogState();
}

class _UploadProgressDialogState extends State<UploadProgressDialog>
    with SingleTickerProviderStateMixin {
  int _currentProgress = 0;
  Timer? _progressTimer;
  
  late AnimationController _rotationController;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _startProgressSimulation();
  }

  void _initAnimations() {
    _rotationController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    
    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(_rotationController);
    
    // 开始旋转动画
    _rotationController.repeat();
  }

  void _startProgressSimulation() {
    _progressTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      setState(() {
        _currentProgress++;
      });
      
      if (_currentProgress >= widget.totalPhotos) {
        timer.cancel();
        // 延迟一下再调用完成回调
        Timer(const Duration(milliseconds: 800), () {
          widget.onComplete();
        });
      }
    });
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 280,
        height: 200,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Loading转圈
            AnimatedBuilder(
              animation: _rotationAnimation,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _rotationAnimation.value * 2.0 * 3.14159,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.grey[300]!,
                        width: 3,
                      ),
                    ),
                    child: CustomPaint(
                      painter: LoadingPainter(
                        progress: (_currentProgress / widget.totalPhotos).clamp(0.0, 1.0),
                      ),
                    ),
                  ),
                );
              },
            ),
            
            const SizedBox(height: 24),
            
            // 进度文字
            Text(
              '$_currentProgress/${widget.totalPhotos}',
              style: const TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            
            const SizedBox(height: 8),
            
            // 状态文字
            Text(
              '正在处理您的照片...',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 自定义Loading画笔
class LoadingPainter extends CustomPainter {
  final double progress;
  
  LoadingPainter({required this.progress});
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF6366F1)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 1.5;
    
    // 绘制进度弧线
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -3.14159 / 2, // 从顶部开始
      2 * 3.14159 * progress, // 根据进度绘制
      false,
      paint,
    );
  }
  
  @override
  bool shouldRepaint(LoadingPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
