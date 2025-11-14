import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:permission_handler/permission_handler.dart';

class PhotoboothResultPage extends StatefulWidget {
  final String imagePath; // AI生成的图片路径

  const PhotoboothResultPage({super.key, required this.imagePath});

  @override
  State<PhotoboothResultPage> createState() => _PhotoboothResultPageState();
}

class _PhotoboothResultPageState extends State<PhotoboothResultPage>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    
    // 初始化滑入动画
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 1.0), // 从下方开始
      end: Offset.zero, // 到达正常位置
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutQuart,
    ));
    
    // 开始滑入动画
    _slideController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  // 返回上一页
  void _goBack() {
    Navigator.pop(context);
  }

  // 保存到画廊
  Future<void> _saveToGallery() async {
    if (_isSaving) return;
    
    setState(() {
      _isSaving = true;
    });

    try {
      // 检查存储权限
      var status = await Permission.storage.status;
      if (!status.isGranted) {
        status = await Permission.storage.request();
        if (!status.isGranted) {
          _showPermissionDialog();
          return;
        }
      }

      // 保存图片到相册
      final result = await ImageGallerySaver.saveFile(widget.imagePath);
      debugPrint('保存结果: $result');

      // 触觉反馈
      HapticFeedback.lightImpact();
      
      // 显示美观的成功提示
      if (mounted) {
        _showSuccessDialog();
      }
    } catch (e) {
      debugPrint('保存失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('保存失败: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }


  // 显示权限对话框
  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('需要存储权限'),
        content: const Text('请允许访问存储权限以保存图片到相册'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('去设置'),
          ),
        ],
      ),
    );
  }

  // 显示美观的成功提示弹窗
  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 成功图标
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 36,
                ),
              ),
              const SizedBox(height: 16),
              
              // 成功文字
              const Text(
                '保存成功！',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              
              const Text(
                '图片已保存到相册',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 20),
              
              // 确定按钮
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
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
      ),
    );
    
    // 2秒后自动关闭弹窗
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SlideTransition(
        position: _slideAnimation,
        child: SafeArea(
          child: Column(
            children: [
              // 顶部标题栏
              _buildHeader(),
              
              // 主要内容区域
              Expanded(
                child: _buildContent(),
              ),
              
              // 底部操作区域
              _buildBottomActions(),
            ],
          ),
        ),
      ),
    );
  }

  // 构建顶部标题栏
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // 返回按钮
          GestureDetector(
            onTap: _goBack,
            child: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
          
          // 标题
          const Expanded(
            child: Text(
              'Photobooth 📸',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          
          // 占位，保持对称
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  // 构建主要内容区域
  Widget _buildContent() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 图片展示区域
          Container(
            width: double.infinity,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.75,
              minHeight: MediaQuery.of(context).size.height * 0.5,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: File(widget.imagePath).existsSync()
                  ? Image.file(
                      File(widget.imagePath),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 400,
                          color: Colors.grey[800],
                          child: const Center(
                            child: Icon(
                              Icons.error,
                              color: Colors.white54,
                              size: 48,
                            ),
                          ),
                        );
                      },
                    )
                  : Container(
                      height: 400,
                      color: Colors.grey[800],
                      child: const Center(
                        child: Icon(
                          Icons.image,
                          color: Colors.white54,
                          size: 48,
                        ),
                      ),
                    ),
            ),
          ),
          
        ],
      ),
    );
  }

  // 构建底部操作区域
  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: GestureDetector(
        onTap: _saveToGallery,
        child: Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isSaving) ...[
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  '保存中...',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ] else ...[
                const Icon(
                  Icons.download,
                  color: Colors.black,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  '保存到画廊',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
