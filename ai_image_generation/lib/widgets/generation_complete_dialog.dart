import 'package:flutter/material.dart';
import 'dart:async';

class GenerationCompleteDialog extends StatefulWidget {
  final VoidCallback? onViewResults;
  final VoidCallback? onMaybeLater;

  const GenerationCompleteDialog({
    super.key,
    this.onViewResults,
    this.onMaybeLater,
  });

  @override
  State<GenerationCompleteDialog> createState() => _GenerationCompleteDialogState();
}

class _GenerationCompleteDialogState extends State<GenerationCompleteDialog>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _bounceController;
  Timer? _autoCloseTimer;

  @override
  void initState() {
    super.initState();
    
    // 弹窗缩放动画
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    // 图片弹跳动画
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _scaleController.forward();
    
    // 延迟启动弹跳动画
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        _bounceController.repeat(reverse: true);
      }
    });
    
    // 设置1分钟后自动关闭
    _autoCloseTimer = Timer(const Duration(minutes: 1), () {
      if (mounted) {
        _closeDialog();
      }
    });
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _bounceController.dispose();
    _autoCloseTimer?.cancel(); // 清理定时器
    super.dispose();
  }

  // 关闭弹窗的统一方法
  void _closeDialog() {
    _autoCloseTimer?.cancel(); // 取消定时器
    Navigator.pop(context);
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
              // 装饰图片区域
              _buildDecorativeImages(),
              
              const SizedBox(height: 24),
              
              // 标题
              const Text(
                '您的包裹已经准备好了！',
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
                '我们已经根据您选择的预设生成了一组AI照片。',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              
              const SizedBox(height: 24),
              
              // 按钮区域
              Row(
                children: [
                  // 也许以后按钮
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        _closeDialog();
                        widget.onMaybeLater?.call();
                      },
                      child: Container(
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: const Center(
                          child: Text(
                            '也许以后',
                            style: TextStyle(
                              color: Colors.black54,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(width: 12),
                  
                  // 看一看按钮
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        _closeDialog();
                        widget.onViewResults?.call();
                      },
                      child: Container(
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: const Center(
                          child: Text(
                            '看一看',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDecorativeImages() {
    return AnimatedBuilder(
      animation: _bounceController,
      builder: (context, child) {
        final bounceValue = Tween<double>(begin: 0.0, end: 8.0).animate(
          CurvedAnimation(parent: _bounceController, curve: Curves.easeInOut),
        ).value;
        
        return SizedBox(
          width: 140,
          height: 90,
          child: Stack(
            children: [
              // 背景装饰形状
              Positioned(
                left: 20,
                top: 15,
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
              
              // 左侧装饰照片
              Positioned(
                left: 0,
                top: 20 - bounceValue,
                child: Transform.rotate(
                  angle: -0.1,
                  child: Container(
                    width: 50,
                    height: 65,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        'https://images.unsplash.com/photo-1494790108755-2616c96afe86?w=200&h=200&fit=crop&crop=face',
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
              ),
              
              // 右侧装饰照片
              Positioned(
                right: 0,
                top: 10 + bounceValue,
                child: Transform.rotate(
                  angle: 0.1,
                  child: Container(
                    width: 50,
                    height: 65,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        'https://images.unsplash.com/photo-1488426862026-3ee34a7d66df?w=200&h=200&fit=crop&crop=face',
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
              ),
              
              // 装饰小元素 - 左下角
              Positioned(
                left: 25,
                bottom: 5,
                child: Transform.rotate(
                  angle: 0.2,
                  child: Container(
                    width: 12,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
              ),
              
              // 装饰小元素 - 右上角
              Positioned(
                right: 20,
                top: 0,
                child: Transform.rotate(
                  angle: -0.3,
                  child: Container(
                    width: 10,
                    height: 6,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF4757),
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
