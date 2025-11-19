import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/generation_history_api_service.dart';

class AIResultPage extends StatefulWidget {
  final List<String> originalPhotoPaths; // 用户上传的原始照片路径
  final List<String?>? generatedPhotoPaths; // AI生成的照片路径（可为空）
  final String? themeId; // 写真主题ID

  const AIResultPage({
    super.key,
    required this.originalPhotoPaths,
    this.generatedPhotoPaths,
    this.themeId,
  });

  @override
  State<AIResultPage> createState() => _AIResultPageState();
}

class _AIResultPageState extends State<AIResultPage>
    with TickerProviderStateMixin {
  PageController _pageController = PageController();
  int _currentIndex = 0;

  // 模拟的AI生成照片（实际项目中这些会是AI生成的结果）
  List<String> _generatedPhotos = [];

  // 删除动画控制器
  late AnimationController _deleteAnimationController;
  late Animation<Offset> _deleteAnimation;

  @override
  void initState() {
    super.initState();
    _initializeGeneratedPhotos();

    // AI生成完成，立即同步所有图片到生成历史
    _syncGeneratedPhotosToHistory();

    // 初始化删除动画
    _deleteAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _deleteAnimation =
        Tween<Offset>(
          begin: Offset.zero,
          end: const Offset(-2.0, 0.0), // 往左边飞出
        ).animate(
          CurvedAnimation(
            parent: _deleteAnimationController,
            curve: Curves.easeInBack,
          ),
        );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _deleteAnimationController.dispose();
    super.dispose();
  }

  // 初始化生成的照片列表
  void _initializeGeneratedPhotos() {
    if (widget.generatedPhotoPaths != null) {
      // 使用实际生成的结果，过滤掉null值（失败的生成）
      _generatedPhotos = widget.generatedPhotoPaths!
          .where((path) => path != null)
          .cast<String>()
          .toList();

      debugPrint('🎯 AIResultPage: 使用实际生成结果，成功${_generatedPhotos.length}张');
    }

    // 如果没有生成结果或生成结果为空，使用原图作为fallback
    if (_generatedPhotos.isEmpty) {
      _generatedPhotos = List.from(widget.originalPhotoPaths);
      debugPrint(
        '⚠️ AIResultPage: AI生成失败或为空，使用原图作为fallback，共${_generatedPhotos.length}张',
      );
    }
  }

  // 同步所有生成的照片到历史
  void _syncGeneratedPhotosToHistory() {
    // 只同步真实AI生成的图片（不包括fallback的原图）
    if (widget.generatedPhotoPaths != null &&
        widget.generatedPhotoPaths!.isNotEmpty) {
      for (final imagePath in _generatedPhotos) {
        unawaited(
          GenerationHistoryApiService.syncGenerationResult(
            localFilePath: imagePath,
            type: 'photoshoot',
            effectId: widget.themeId,
          ).catchError((e, stack) {
            debugPrint('同步写真历史失败: $e');
          }),
        );
      }
      debugPrint('✅ 已同步${_generatedPhotos.length}张写真照片到历史');
    }
  }

  // 返回首页
  void _returnToHome() {
    // 清除所有页面栈，回到首页
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  // 删除当前照片
  void _deleteCurrentPhoto() {
    if (_generatedPhotos.isEmpty) return;

    // 如果是最后一张，弹出确认弹窗
    if (_generatedPhotos.length == 1) {
      _showCloseConfirmDialog();
      return;
    }

    // 执行删除动画
    _performDeleteAnimation();
  }

  // 执行删除动画
  void _performDeleteAnimation() async {
    // 开始删除动画
    await _deleteAnimationController.forward();

    if (mounted) {
      setState(() {
        _generatedPhotos.removeAt(_currentIndex);

        // 调整当前索引
        if (_currentIndex >= _generatedPhotos.length &&
            _generatedPhotos.isNotEmpty) {
          _currentIndex = _generatedPhotos.length - 1;
        }

        // 重置动画
        _deleteAnimationController.reset();

        // 跳转到新的当前页
        if (_generatedPhotos.isNotEmpty) {
          _pageController.animateToPage(
            _currentIndex,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      });

      // 如果没有照片了，返回首页
      if (_generatedPhotos.isEmpty) {
        _returnToHome();
      }
    }
  }

  // 一键全部下载
  void _downloadAllPhotos() async {
    if (_generatedPhotos.isEmpty) return;

    try {
      // 请求权限
      final permission = await _requestStoragePermission();
      if (!permission) {
        _showBeautifulDialog('需要相册权限才能保存图片', isError: true);
        return;
      }

      // 显示进度对话框
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  const Text(
                    '正在保存所有图片...',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          );
        },
      );

      int successCount = 0;
      int totalCount = _generatedPhotos.length;

      // 逐个保存图片
      for (int i = 0; i < _generatedPhotos.length; i++) {
        String imagePath = _generatedPhotos[i];

        try {
          // 检查文件是否存在
          File imageFile = File(imagePath);
          if (!await imageFile.exists()) {
            debugPrint('⚠️ 图片文件不存在: $imagePath');
            continue;
          }

          // 保存到相册
          final result = await ImageGallerySaver.saveFile(
            imagePath,
            name:
                'ai_photoshoot_batch_${DateTime.now().millisecondsSinceEpoch}_${i + 1}',
          );

          if (result['isSuccess'] == true) {
            successCount++;
            debugPrint('✅ 图片${i + 1}保存成功');
          } else {
            debugPrint('❌ 图片${i + 1}保存失败');
          }
        } catch (e) {
          debugPrint('❌ 图片${i + 1}保存异常: $e');
        }

        // 添加小延迟，避免过于频繁的保存操作
        if (i < _generatedPhotos.length - 1) {
          await Future.delayed(const Duration(milliseconds: 200));
        }
      }

      // 关闭进度对话框
      if (mounted) {
        Navigator.of(context).pop();
      }

      // 触觉反馈
      HapticFeedback.lightImpact();

      // 显示结果
      if (successCount == totalCount) {
        _showBeautifulDialog('成功保存所有 $totalCount 张图片到相册');
      } else if (successCount > 0) {
        _showBeautifulDialog('成功保存 $successCount/$totalCount 张图片到相册');
      } else {
        _showBeautifulDialog('保存失败，请重试', isError: true);
      }
    } catch (e) {
      // 关闭可能存在的进度对话框
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      debugPrint('❌ 批量保存失败: $e');
      _showBeautifulDialog('批量保存失败: ${e.toString()}', isError: true);
    }
  }

  // 下载当前照片
  void _downloadCurrentPhoto() async {
    if (_generatedPhotos.isEmpty) return;

    try {
      // 请求权限
      final permission = await _requestStoragePermission();
      if (!permission) {
        return;
      }

      // 获取当前照片路径
      String currentImagePath = _generatedPhotos[_currentIndex];

      // 读取文件
      File imageFile = File(currentImagePath);
      if (!await imageFile.exists()) {
        return;
      }

      // 保存到相册
      final result = await ImageGallerySaver.saveFile(
        currentImagePath,
        name: 'ai_photoshoot_${DateTime.now().millisecondsSinceEpoch}',
      );

      // 触觉反馈
      HapticFeedback.lightImpact();

      // 显示保存结果弹窗
      if (result['isSuccess'] == true) {
        _showBeautifulDialog('图片已保存到相册');
      } else {
        _showBeautifulDialog('保存失败，请重试', isError: true);
      }
      debugPrint('保存结果: $result');
    } catch (e) {
      debugPrint('保存失败: $e');
      _showBeautifulDialog('保存失败: ${e.toString()}', isError: true);
    }
  }

  // 请求存储权限
  Future<bool> _requestStoragePermission() async {
    if (Platform.isAndroid) {
      final androidInfo = await Permission.storage.status;
      if (androidInfo != PermissionStatus.granted) {
        final result = await Permission.storage.request();
        return result == PermissionStatus.granted;
      }
      return true;
    } else if (Platform.isIOS) {
      final iosInfo = await Permission.photosAddOnly.status;
      if (iosInfo != PermissionStatus.granted) {
        final result = await Permission.photosAddOnly.request();
        return result == PermissionStatus.granted;
      }
      return true;
    }
    return false;
  }

  // 分享功能
  void _sharePhoto() {
    // TODO: 实现分享功能
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('分享功能开发中...'),
        backgroundColor: Colors.blue,
        duration: Duration(seconds: 2),
      ),
    );
  }

  // 显示漂亮的弹窗消息 - 参考图片增强页面的实现
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
                  style: const TextStyle(fontSize: 14, color: Colors.black54),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 20),

                // 确认按钮
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isError ? Colors.red : Colors.green,
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
                        fontWeight: FontWeight.w600,
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
  }

  // 显示关闭确认弹窗
  void _showCloseConfirmDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 320,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 关闭按钮
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(
                      Icons.close,
                      color: Colors.black,
                      size: 24,
                    ),
                  ),
                  const Spacer(),
                ],
              ),

              const SizedBox(height: 16),

              // 标题
              const Text(
                '你确定吗？',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 16),

              // 内容
              const Text(
                '您还没有查看所有的效果。您想先保存剩余的照片吗？',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 16, height: 1.4),
              ),

              const SizedBox(height: 32),

              // 按钮组
              Column(
                children: [
                  // 全部保存按钮
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context); // 关闭弹窗
                        _saveAllPhotos();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text(
                        '是的，全部保存',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // 全部丢弃按钮
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () {
                        Navigator.pop(context); // 关闭弹窗
                        _discardAllPhotos();
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.grey,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text(
                        '全部丢弃',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
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

  // 保存所有照片
  void _saveAllPhotos() {
    // TODO: 实现保存所有照片的逻辑
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('正在保存所有照片...'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );

    // 保存完成后返回首页
    Future.delayed(const Duration(seconds: 1), () {
      _returnToHome();
    });
  }

  // 丢弃所有照片
  void _discardAllPhotos() {
    // 直接返回首页
    _returnToHome();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _generatedPhotos.isEmpty ? _buildEmptyState() : _buildPhotoViewer(),
    );
  }

  // 空状态页面
  Widget _buildEmptyState() {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'AI写真结果',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.photo_library_outlined,
              color: Colors.grey,
              size: 80,
            ),
            const SizedBox(height: 20),
            const Text(
              'AI生成失败',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              '网络连接或AI服务可能出现问题',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.refresh),
              label: const Text('重新尝试'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => _returnToHome(),
              child: const Text(
                '返回首页',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 照片查看器
  Widget _buildPhotoViewer() {
    return Stack(
      children: [
        // 照片区域
        PageView.builder(
          controller: _pageController,
          onPageChanged: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          itemCount: _generatedPhotos.length,
          itemBuilder: (context, index) {
            return _buildPhotoItem(_generatedPhotos[index]);
          },
        ),

        // 顶部导航栏
        _buildTopNavigation(),

        // 底部操作栏
        _buildBottomActions(),
      ],
    );
  }

  // 单张照片项
  Widget _buildPhotoItem(String imagePath) {
    return SlideTransition(
      position: _deleteAnimation,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.7,
              maxWidth: MediaQuery.of(context).size.width * 0.9,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Stack(
              children: [
                // 照片卡片
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.file(
                    File(imagePath),
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                ),

                // 左上角关闭按钮（在图片上）
                Positioned(
                  top: 12,
                  left: 12,
                  child: GestureDetector(
                    onTap: _showCloseConfirmDialog,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),

                // 右下角水印 - 暂时注释，后续会更换
                /*
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Remini',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Generated with AI',
                          style: TextStyle(color: Colors.white70, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                ),
                */
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 顶部导航栏
  Widget _buildTopNavigation() {
    return SafeArea(
      child: Container(
        height: 60,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            // 左侧：返回首页按钮
            GestureDetector(
              onTap: _returnToHome,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.keyboard_arrow_down,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),

            const Spacer(),

            // 右侧：一键全部下载按钮
            GestureDetector(
              onTap: _downloadAllPhotos,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.download,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 底部操作栏
  Widget _buildBottomActions() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Container(
          height: 100,
          padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 删除按钮
              GestureDetector(
                onTap: _deleteCurrentPhoto,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.delete_outline,
                    color: Colors.red,
                    size: 28,
                  ),
                ),
              ),

              // 中间：照片计数（显示当前剩余数量）
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_generatedPhotos.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              // 下载按钮
              GestureDetector(
                onTap: _downloadCurrentPhoto,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.download,
                    color: Colors.black,
                    size: 28,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
