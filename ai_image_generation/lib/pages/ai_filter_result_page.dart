import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:async';
import 'package:image_picker/image_picker.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/filter_model.dart';
import '../services/filter_service.dart';
import '../services/generation_history_api_service.dart';

class AiFilterResultPage extends StatefulWidget {
  final String originalImagePath;
  final String filterId;
  final String? processedImagePath; // 已处理的图片路径

  const AiFilterResultPage({
    super.key,
    required this.originalImagePath,
    required this.filterId,
    this.processedImagePath, // 可选参数
  });

  @override
  State<AiFilterResultPage> createState() => _AiFilterResultPageState();
}

class _AiFilterResultPageState extends State<AiFilterResultPage>
    with TickerProviderStateMixin {
  double _sliderPosition = 0.5; // 分割线位置 (0.0 - 1.0)
  String? _selectedFilterId;
  final List<FilterModel> _filters = FilterModel.getAllFilters();

  // Loading状态管理
  bool _isFilterChanging = false; // 滤镜切换loading
  bool _isPhotoChanging = false; // 照片切换loading
  late AnimationController _loadingController;
  String _currentImagePath = ''; // 当前显示的图片路径

  @override
  void initState() {
    super.initState();
    _selectedFilterId = widget.filterId;

    // 如果已经有处理后的图片，直接使用；否则使用原图
    _currentImagePath = widget.processedImagePath ?? widget.originalImagePath;

    // 初始化动画控制器
    _loadingController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    // 只有在没有处理后图片时，才需要重新处理
    if (widget.processedImagePath == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _applyInitialFilter();
      });
    }
  }

  // 应用初始滤镜效果
  Future<void> _applyInitialFilter() async {
    try {
      setState(() {
        _isFilterChanging = true;
      });

      _loadingController.repeat();

      // 应用当前滤镜到原图
      final result = await FilterService.applyFilter(
        imagePath: widget.originalImagePath,
        filterId: widget.filterId,
        onProgressUpdate: (message) {
          debugPrint('初始滤镜应用进度: $message');
        },
      );

      if (mounted) {
        if (result != null) {
          setState(() {
            _currentImagePath = result; // 更新为AI处理后的图片
            _isFilterChanging = false;
          });

          // 滤镜应用成功，立即同步到生成历史
          unawaited(
            GenerationHistoryApiService.syncGenerationResult(
              localFilePath: result,
              type: 'filter',
              effectId: widget.filterId,
            ).catchError((e, stack) {
              debugPrint('同步滤镜历史失败: $e');
            }),
          );
        } else {
          setState(() {
            _isFilterChanging = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('滤镜应用失败，显示原图'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        _loadingController.stop();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isFilterChanging = false;
        });
        _loadingController.stop();
        debugPrint('初始滤镜应用失败: $e');
      }
    }
  }

  @override
  void dispose() {
    _loadingController.dispose();
    super.dispose();
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

            // 主要对比区域
            Expanded(child: _buildComparisonView()),

            // 底部操作区域
            _buildBottomSection(),
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

          const SizedBox(width: 16),

          // 刷新按钮
          GestureDetector(
            onTap: _refreshResult,
            child: _isFilterChanging
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: AnimatedBuilder(
                      animation: _loadingController,
                      builder: (context, child) {
                        return Transform.rotate(
                          angle: _loadingController.value * 2.0 * 3.14159,
                          child: const Icon(
                            Icons.refresh,
                            color: Colors.white70,
                            size: 24,
                          ),
                        );
                      },
                    ),
                  )
                : const Icon(Icons.refresh, color: Colors.white, size: 24),
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

          // 下载按钮
          GestureDetector(
            onTap: _downloadResult,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.download, color: Colors.black, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  // 对比视图
  Widget _buildComparisonView() {
    return Container(
      margin: const EdgeInsets.all(20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // 背景图片（AI处理后的效果）
            Positioned.fill(
              child: Image.file(
                File(_currentImagePath), // AI处理后的图片
                fit: BoxFit.cover,
                cacheWidth: 1024, // 限制缓存宽度，防止内存爆炸
                cacheHeight: 1024, // 限制缓存高度，防止内存爆炸
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[300],
                    child: const Center(child: Text('处理后图片加载失败')),
                  );
                },
              ),
            ),

            // 前景图片（原图），使用ClipPath裁剪
            Positioned.fill(
              child: ClipPath(
                clipper: _SliderClipper(_sliderPosition),
                child: Image.file(
                  File(widget.originalImagePath), // 原图
                  fit: BoxFit.cover,
                  cacheWidth: 1024, // 限制缓存宽度，防止内存爆炸
                  cacheHeight: 1024, // 限制缓存高度，防止内存爆炸
                ),
              ),
            ),

            // 分割线和控制器
            Positioned.fill(
              child: GestureDetector(
                onPanUpdate: (details) {
                  setState(() {
                    final RenderBox box =
                        context.findRenderObject() as RenderBox;
                    final localPosition = details.localPosition;
                    _sliderPosition = (localPosition.dx / box.size.width).clamp(
                      0.0,
                      1.0,
                    );
                  });
                },
                child: CustomPaint(painter: _SliderPainter(_sliderPosition)),
              ),
            ),

            // 左侧标签
            Positioned(
              left: 16,
              top: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text(
                  '处理前',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),

            // 右侧标签
            Positioned(
              right: 16,
              top: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text(
                  '处理后',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),

            // mini水印
            Positioned(
              right: 16,
              bottom: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'mini',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            // Loading覆盖层
            if (_isFilterChanging || _isPhotoChanging)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
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
                                size: 40,
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _isFilterChanging ? '正在应用滤镜...' : '正在处理新照片...',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // 底部操作区域
  Widget _buildBottomSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 新照片按钮
          GestureDetector(
            onTap: _selectNewPhoto,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white24),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.image, color: Colors.white, size: 16),
                  SizedBox(width: 6),
                  Text(
                    '新照片',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 版本标识
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '不同版',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),

          const SizedBox(height: 12),

          // 滤镜选择网格
          _buildFilterGrid(),
        ],
      ),
    );
  }

  // 滤镜网格
  Widget _buildFilterGrid() {
    return Container(
      height: 200,
      child: GridView.builder(
        scrollDirection: Axis.horizontal,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.8,
          crossAxisSpacing: 8,
          mainAxisSpacing: 12,
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
                      borderRadius: BorderRadius.circular(6),
                      border: isSelected
                          ? Border.all(color: Colors.white, width: 2)
                          : null,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Image.asset(
                        filter.thumbnailUrl,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        errorBuilder: (context, error, stackTrace) {
                          debugPrint(
                            '结果页滤镜缩略图加载失败: ${filter.thumbnailUrl}, 错误: $error',
                          );
                          return Container(
                            color: Colors.grey[800],
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.image,
                                  color: Colors.white54,
                                  size: 16,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  filter.name,
                                  style: const TextStyle(
                                    color: Colors.white54,
                                    fontSize: 8,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 4),

                // 滤镜名称
                Text(
                  filter.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
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
      ),
    );
  }

  // 选择滤镜
  Future<void> _selectFilter(String filterId) async {
    if (_isFilterChanging || _isPhotoChanging) return; // 防止重复点击

    setState(() {
      _selectedFilterId = filterId;
      _isFilterChanging = true;
    });

    // 开始loading动画
    _loadingController.repeat();

    debugPrint('切换到滤镜: $filterId');

    try {
      // 始终基于原图应用新滤镜，避免在已处理图片上叠加效果
      final result = await FilterService.applyFilter(
        imagePath: widget.originalImagePath, // 🔧 修复：始终使用原图
        filterId: filterId,
        onProgressUpdate: (message) {
          debugPrint('滤镜切换进度: $message');
        },
      );

      if (mounted) {
        if (result != null) {
          setState(() {
            _currentImagePath = result;
            _isFilterChanging = false;
          });
        } else {
          setState(() {
            _isFilterChanging = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('滤镜应用失败，请重试'),
              backgroundColor: Colors.red,
            ),
          );
        }
        _loadingController.stop();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isFilterChanging = false;
        });
        _loadingController.stop();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('滤镜处理异常: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // 刷新结果
  Future<void> _refreshResult() async {
    if (_isFilterChanging || _isPhotoChanging) return; // 防止重复点击

    debugPrint('刷新处理结果 - 滤镜ID: $_selectedFilterId');

    setState(() {
      _isFilterChanging = true;
    });

    // 开始loading动画
    _loadingController.repeat();

    try {
      // 使用当前选中的滤镜重新处理原图
      final currentFilterId = _selectedFilterId ?? widget.filterId;
      final result = await FilterService.applyFilter(
        imagePath: widget.originalImagePath, // 始终使用原图
        filterId: currentFilterId,
        onProgressUpdate: (message) {
          debugPrint('刷新处理进度: $message');
        },
      );

      if (mounted) {
        if (result != null) {
          setState(() {
            _currentImagePath = result; // 更新为新生成的图片
            _isFilterChanging = false;
          });
        } else {
          setState(() {
            _isFilterChanging = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('刷新失败，请重试'),
              backgroundColor: Colors.red,
            ),
          );
        }
        _loadingController.stop();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isFilterChanging = false;
        });
        _loadingController.stop();

        debugPrint('刷新处理异常: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('刷新异常: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // 下载结果 - 真实实现
  Future<void> _downloadResult() async {
    try {
      debugPrint('开始下载处理结果到相册');

      // 获取要下载的图片路径（处理后的图片）
      final imageToDownload = _currentImagePath;

      if (imageToDownload.isEmpty) {
        _showErrorDialog('没有可下载的图片');
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
        _showErrorDialog('需要相册权限才能保存图片');
        return;
      }

      // 检查文件是否存在
      final File imageFile = File(imageToDownload);
      if (!await imageFile.exists()) {
        _showErrorDialog('图片文件不存在');
        return;
      }

      // 保存到相册
      final result = await ImageGallerySaver.saveFile(
        imageToDownload,
        name:
            'ai_filter_${_selectedFilterId}_${DateTime.now().millisecondsSinceEpoch}',
      );

      if (result['isSuccess'] == true) {
        _showSuccessDialog();
      } else {
        _showErrorDialog('保存失败，请重试');
      }
    } catch (e) {
      debugPrint('下载图片失败: $e');
      _showErrorDialog('保存失败: ${e.toString()}');
    }
  }

  // 显示错误弹窗
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
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
              // 错误图标
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 30,
                ),
              ),

              const SizedBox(height: 16),

              const Text(
                '下载失败',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),

              const SizedBox(height: 8),

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

              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    '确定',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ),
              ),
            ],
          ),
        ),
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
                style: TextStyle(fontSize: 14, color: Colors.grey),
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
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
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

  // 选择新照片
  Future<void> _selectNewPhoto() async {
    if (_isFilterChanging || _isPhotoChanging) return; // 防止重复点击

    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _isPhotoChanging = true;
        });

        // 开始loading动画
        _loadingController.repeat();

        debugPrint('选择了新照片: ${image.path}');

        // 使用当前选中的滤镜处理新照片
        final currentFilter = _selectedFilterId ?? widget.filterId;
        final result = await FilterService.applyFilter(
          imagePath: image.path,
          filterId: currentFilter,
          onProgressUpdate: (message) {
            debugPrint('新照片处理进度: $message');
          },
        );

        if (mounted) {
          if (result != null) {
            setState(() {
              _currentImagePath = result;
              _isPhotoChanging = false;
            });
          } else {
            setState(() {
              _currentImagePath = image.path; // 失败时使用原图
              _isPhotoChanging = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('新照片滤镜处理失败，显示原图'),
                backgroundColor: Colors.orange,
              ),
            );
          }
          _loadingController.stop();
        }
      }
    } catch (e) {
      debugPrint('选择照片失败: $e');
      if (mounted) {
        setState(() {
          _isPhotoChanging = false;
        });
        _loadingController.stop();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('选择照片失败：$e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}

// 分割线裁剪器
class _SliderClipper extends CustomClipper<Path> {
  final double sliderPosition;

  _SliderClipper(this.sliderPosition);

  @override
  Path getClip(Size size) {
    final path = Path();
    final splitX = size.width * sliderPosition;

    path.addRect(Rect.fromLTWH(0, 0, splitX, size.height));
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) {
    return true;
  }
}

// 分割线绘制器
class _SliderPainter extends CustomPainter {
  final double sliderPosition;

  _SliderPainter(this.sliderPosition);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2;

    final splitX = size.width * sliderPosition;

    // 绘制垂直分割线
    canvas.drawLine(Offset(splitX, 0), Offset(splitX, size.height), paint);

    // 绘制中心拖动按钮
    final buttonPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final buttonCenter = Offset(splitX, size.height / 2);
    canvas.drawCircle(buttonCenter, 16, buttonPaint);

    // 绘制拖动图标
    final iconPaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    // 左箭头
    canvas.drawLine(
      Offset(splitX - 6, size.height / 2 - 3),
      Offset(splitX - 3, size.height / 2),
      iconPaint,
    );
    canvas.drawLine(
      Offset(splitX - 6, size.height / 2 + 3),
      Offset(splitX - 3, size.height / 2),
      iconPaint,
    );

    // 右箭头
    canvas.drawLine(
      Offset(splitX + 3, size.height / 2),
      Offset(splitX + 6, size.height / 2 - 3),
      iconPaint,
    );
    canvas.drawLine(
      Offset(splitX + 3, size.height / 2),
      Offset(splitX + 6, size.height / 2 + 3),
      iconPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
