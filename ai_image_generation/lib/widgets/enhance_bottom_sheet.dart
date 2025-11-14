import 'dart:io';
import 'package:flutter/material.dart';
import '../pages/image_enhance_page.dart';

class EnhanceBottomSheet extends StatefulWidget {
  final String imagePath;
  
  const EnhanceBottomSheet({super.key, required this.imagePath});
  
  @override
  State<EnhanceBottomSheet> createState() => _EnhanceBottomSheetState();
}

class _EnhanceBottomSheetState extends State<EnhanceBottomSheet>
    with TickerProviderStateMixin {
  
  bool _isProcessing = false; // 是否正在处理
  String _processingText = '正在上传照片...'; // 处理文案
  late AnimationController _loadingController;
  
  @override
  void initState() {
    super.initState();
    
    // 加载动画控制器
    _loadingController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
  }
  
  @override
  void dispose() {
    _loadingController.dispose();
    super.dispose();
  }
  
  // 开始处理
  void _startProcessing() async {
    setState(() {
      _isProcessing = true;
      _processingText = '正在上传照片...';
    });
    
    _loadingController.repeat();
    
    // 模拟上传阶段
    await Future.delayed(const Duration(seconds: 2));
    
    if (mounted) {
      setState(() {
        _processingText = '正在重构细节...';
      });
    }
    
    // 模拟处理阶段
    await Future.delayed(const Duration(seconds: 3));
    
    if (mounted) {
      _loadingController.stop();
      // 处理完成，跳转到全屏增强页面
      Navigator.pop(context); // 关闭底部sheet
      // 延迟一下确保底部sheet完全关闭
      await Future.delayed(const Duration(milliseconds: 100));
      if (mounted) {
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                ImageEnhancePage(imagePath: widget.imagePath),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              const begin = Offset(0.0, 1.0);
              const end = Offset.zero;
              const curve = Curves.easeInOut;

              var tween = Tween(begin: begin, end: end).chain(
                CurveTween(curve: curve),
              );

              return SlideTransition(
                position: animation.drive(tween),
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 400),
          ),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
        height: MediaQuery.of(context).size.height * 0.5, // 占屏幕50%高度（一半）
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Stack(
          children: [
            // 图片区域 - 不填满，底部留白
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: MediaQuery.of(context).size.height * 0.5 - 60, // 预留底部60px空间
              child: Stack(
                children: [
                  // 图片
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                    child: Image.file(
                      File(widget.imagePath),
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  ),
                  
                  // 处理时的暗色遮罩
                  if (_isProcessing)
                    Container(
                      width: double.infinity,
                      height: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                      ),
                    ),
                  
                  // 处理时的加载动画和文案
                  if (_isProcessing)
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // 粉色加载点动画
                          AnimatedBuilder(
                            animation: _loadingController,
                            builder: (context, child) {
                              return Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: Colors.pink.withOpacity(
                                    0.5 + 0.5 * _loadingController.value,
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              );
                            },
                          ),
                          
                          const SizedBox(height: 20),
                          
                          // 处理文案
                          Text(
                            _processingText,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            
            // 底部留白区域
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 60,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                ),
                child: _isProcessing 
                    ? Center(
                        child: Text(
                          '增强处理可能需要数秒钟，请不要退出应用。',
                          style: TextStyle(
                            color: Colors.black.withOpacity(0.7),
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      )
                    : null,
              ),
            ),
            
            // 左上角关闭按钮 - 浮在图片上
            if (!_isProcessing) // 处理时隐藏关闭按钮
              Positioned(
                top: 20,
                left: 20,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),
            
            // 增强按钮 - 跨越图片和留白区域
            if (!_isProcessing) // 处理时隐藏增强按钮
              Positioned(
                bottom: 30, // 距离底部30px，让按钮一半在图片上，一半在留白上
                left: 20,
                right: 20,
                child: GestureDetector(
                  onTap: _startProcessing,
                  child: Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '增强',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.white,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
  }
}
