import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/filter_model.dart';
import '../services/filter_service.dart';
import 'ai_filter_result_page.dart';

class AiFilterPage extends StatefulWidget {
  final String? defaultFilterId; // 默认选中的滤镜ID

  const AiFilterPage({super.key, this.defaultFilterId});

  @override
  State<AiFilterPage> createState() => _AiFilterPageState();
}

class _AiFilterPageState extends State<AiFilterPage> {
  String? _selectedFilterId;
  final List<FilterModel> _filters = FilterModel.getAllFilters();

  @override
  void initState() {
    super.initState();
    // 使用传入的默认滤镜ID，如果没有传入则使用'art_toy'作为默认
    _selectedFilterId = widget.defaultFilterId ?? 'art_toy';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // 顶部导航栏
            _buildTopBar(),

            // 可滚动内容
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    const SizedBox(height: 40),

                    // 示例图片展示
                    _buildExampleImages(),

                    const SizedBox(height: 30),

                    // 营销文案
                    _buildMarketingText(),

                    const SizedBox(height: 40),

                    // 选择照片按钮
                    _buildSelectPhotoButton(),

                    const SizedBox(height: 60),

                    // 版本标识
                    _buildVersionLabel(),

                    const SizedBox(height: 20),

                    // 滤镜网格
                    _buildFilterGrid(),

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
                'AI滤镜',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          // 设置按钮
          GestureDetector(
            onTap: () {
              debugPrint('设置按钮点击');
            },
            child: const Icon(
              Icons.settings_outlined,
              color: Colors.white,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  // 示例图片展示
  Widget _buildExampleImages() {
    return Container(
      height: 140,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 第一张图片（原图）- 在下层，向左倾斜
          Positioned(
            left: 40,
            top: 10,
            child: Transform.rotate(
              angle: -0.15, // 向左倾斜
              child: Container(
                width: 85,
                height: 105,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: Colors.grey[800],
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(2, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.asset(
                    'assets/images/demo/original_demo.jpg', // 🖼️ 原图路径
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[800],
                        child: const Icon(
                          Icons.person,
                          color: Colors.white54,
                          size: 35,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),

          // 第二张图片（效果图）- 在上层，向右倾斜，与第一张重叠
          Positioned(
            right: 50,
            top: 25,
            child: Transform.rotate(
              angle: 0.12, // 向右倾斜
              child: Container(
                width: 85,
                height: 105,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: Colors.grey[800],
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(2, 6),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.asset(
                    'assets/images/demo/processed_demo.jpg', // 🖼️ 处理后图片路径
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[800],
                        child: const Icon(
                          Icons.image,
                          color: Colors.white54,
                          size: 35,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 营销文案
  Widget _buildMarketingText() {
    return Column(
      children: [
        const Text(
          '选择一张照片，将其变成一件艺术品',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),

        const SizedBox(height: 8),

        // 调色盘图标
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            gradient: LinearGradient(
              colors: [
                Color(0xFFFF6B35),
                Color(0xFFFF4757),
                Color(0xFFE91E63),
                Color(0xFF9C27B0),
              ],
            ),
          ),
          child: const Icon(Icons.palette, color: Colors.white, size: 16),
        ),
      ],
    );
  }

  // 选择照片按钮
  Widget _buildSelectPhotoButton() {
    return GestureDetector(
      onTap: _selectPhoto,
      child: Container(
        width: double.infinity,
        height: 56,
        margin: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '选择一张照片',
              style: TextStyle(
                color: Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(width: 8),
            Icon(Icons.add, color: Colors.black, size: 20),
          ],
        ),
      ),
    );
  }

  // 版本标识
  Widget _buildVersionLabel() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          '不同版',
          style: TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ),
    );
  }

  // 滤镜网格
  Widget _buildFilterGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 0.8,
        crossAxisSpacing: 12,
        mainAxisSpacing: 16,
      ),
      itemCount: _filters.length,
      itemBuilder: (context, index) {
        final filter = _filters[index];
        final isSelected = filter.id == _selectedFilterId;

        return GestureDetector(
          onTap: () => _selectFilter(filter.id),
          child: Column(
            children: [
              // 滤镜缩略图
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: isSelected
                        ? Border.all(color: Colors.white, width: 2)
                        : null,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.asset(
                      filter.thumbnailUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (context, error, stackTrace) {
                        debugPrint(
                          '滤镜缩略图加载失败: ${filter.thumbnailUrl}, 错误: $error',
                        );
                        return Container(
                          color: Colors.grey[800],
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.image,
                                color: Colors.grey,
                                size: 30,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                filter.name,
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 6),

              // 滤镜名称
              Text(
                filter.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }

  // 选择滤镜
  void _selectFilter(String filterId) {
    setState(() {
      _selectedFilterId = filterId;
    });
    debugPrint('选择了滤镜: $filterId');
  }

  // 选择照片
  Future<void> _selectPhoto() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image != null) {
        debugPrint('选择了图片: ${image.path}');

        // 显示照片预览弹窗
        _showPhotoPreviewDialog(image.path);
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

  // 显示照片预览弹窗
  void _showPhotoPreviewDialog(String imagePath) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => _PhotoPreviewDialog(
        imagePath: imagePath,
        filterId: _selectedFilterId ?? 'muscles',
      ),
    );
  }
}

// 照片预览弹窗组件
class _PhotoPreviewDialog extends StatefulWidget {
  final String imagePath;
  final String filterId;

  const _PhotoPreviewDialog({required this.imagePath, required this.filterId});

  @override
  State<_PhotoPreviewDialog> createState() => _PhotoPreviewDialogState();
}

class _PhotoPreviewDialogState extends State<_PhotoPreviewDialog>
    with TickerProviderStateMixin {
  bool _isProcessing = false;
  late AnimationController _loadingController;

  @override
  void initState() {
    super.initState();
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
  Future<void> _startProcessing() async {
    if (_isProcessing) return; // 防止重复点击

    setState(() {
      _isProcessing = true;
    });

    // 开始加载动画
    _loadingController.repeat();

    try {
      // 使用真实的滤镜服务处理
      final result = await FilterService.applyFilter(
        imagePath: widget.imagePath,
        filterId: widget.filterId,
        onProgressUpdate: (message) {
          debugPrint('滤镜处理进度: $message');
        },
      );

      if (mounted) {
        // 停止动画
        _loadingController.stop();

        // 关闭当前弹窗
        Navigator.pop(context);

        if (result != null) {
          // 处理成功，跳转到结果页面，传递处理后的图片路径
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AiFilterResultPage(
                originalImagePath: widget.imagePath,
                filterId: widget.filterId,
                processedImagePath: result, // 传递AI处理后的图片路径
              ),
            ),
          );
        } else {
          // 处理失败，显示错误提示
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('滤镜处理失败，请重试'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        _loadingController.stop();
        setState(() {
          _isProcessing = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('处理过程中发生错误: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 30),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 350),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 图片预览区域
            Stack(
              children: [
                // 图片容器
                Container(
                  width: double.infinity,
                  height: 300, // 从400减小到300
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                    child: _isProcessing
                        ? _buildLoadingView()
                        : Image.file(
                            File(widget.imagePath),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey[300],
                                child: const Icon(
                                  Icons.error,
                                  color: Colors.grey,
                                  size: 50,
                                ),
                              );
                            },
                          ),
                  ),
                ),

                // 关闭按钮
                if (!_isProcessing)
                  Positioned(
                    top: 16,
                    left: 16,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
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
                          size: 20,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            // 底部按钮
            Padding(
              padding: const EdgeInsets.all(20),
              child: _isProcessing
                  ? _buildProcessingView()
                  : _buildUploadButton(),
            ),
          ],
        ),
      ),
    );
  }

  // 上传按钮
  Widget _buildUploadButton() {
    return GestureDetector(
      onTap: _startProcessing,
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(28),
        ),
        child: const Center(
          child: Text(
            '上传自拍照',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  // 加载视图 - 在照片背景上显示加载动画
  Widget _buildLoadingView() {
    return Stack(
      fit: StackFit.expand,
      children: [
        // 背景显示选择的照片
        Image.file(
          File(widget.imagePath),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.grey[300],
              child: const Icon(Icons.error, color: Colors.grey, size: 50),
            );
          },
        ),

        // 半透明遮罩
        Container(color: Colors.black.withOpacity(0.6)),

        // 加载动画
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 旋转的齿轮图标
              AnimatedBuilder(
                animation: _loadingController,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _loadingController.value * 2.0 * 3.14159,
                    child: const Icon(
                      Icons.settings,
                      color: Colors.white,
                      size: 50,
                    ),
                  );
                },
              ),

              const SizedBox(height: 20),

              const Text(
                '正在处理您的照片...',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 处理中底部视图
  Widget _buildProcessingView() {
    return Column(
      children: [
        // 进度条
        LinearProgressIndicator(
          backgroundColor: Colors.grey[300],
          valueColor: const AlwaysStoppedAnimation<Color>(Colors.black),
        ),
        const SizedBox(height: 16),
        const Text(
          '正在上传照片...',
          style: TextStyle(color: Colors.black54, fontSize: 14),
        ),
      ],
    );
  }
}
