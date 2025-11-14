import 'dart:async';
import 'package:flutter/material.dart';
import '../models/photoshoot_theme_model.dart';
import '../data/photoshoot_themes.dart';
import 'photo_upload_guide_page.dart';

class PhotoGalleryPage extends StatefulWidget {
  final String initialCategoryId;

  const PhotoGalleryPage({super.key, this.initialCategoryId = 'fitness_model'});

  @override
  State<PhotoGalleryPage> createState() => _PhotoGalleryPageState();
}

class _PhotoGalleryPageState extends State<PhotoGalleryPage> {
  late PageController _pageController;
  late ScrollController _scrollController;
  String _selectedCategoryId = 'fitness_model';
  bool _showPresetDialog = false;
  String? _selectedImageUrl;
  String? _selectedThemeId;

  // 写真主题数据
  List<PhotoshootTheme> _themes = [];

  @override
  void initState() {
    super.initState();

    // 加载写真主题数据
    _themes = PhotoshootThemes.getAllThemes();

    // 设置初始选中的分类
    if (_themes.any((theme) => theme.id == widget.initialCategoryId)) {
      _selectedCategoryId = widget.initialCategoryId;
    } else {
      _selectedCategoryId = _themes.isNotEmpty
          ? _themes.first.id
          : 'fitness_model';
    }

    _pageController = PageController();
    _scrollController = ScrollController();

    // 延迟显示预设选择弹窗 - 使用postFrameCallback确保在build完成后执行
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Timer(const Duration(milliseconds: 500), () {
        if (mounted) {
          // 根据initialCategoryId设置默认显示的图片
          _setDefaultPreviewImage();
          setState(() {
            _showPresetDialog = true;
          });
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 主要内容
          Column(
            children: [
              // 状态栏占位
              Container(
                height: MediaQuery.of(context).padding.top,
                color: Colors.black,
              ),

              // 顶部导航栏 - 只显示照片
              _buildTopNavigation(),

              // 横向分类滚动栏
              _buildCategoryTabs(),

              // 内容区域
              Expanded(child: _buildContentArea()),
            ],
          ),

          // 预设选择弹窗
          if (_showPresetDialog) _buildPresetDialog(),
        ],
      ),
    );
  }

  // 顶部导航栏
  Widget _buildTopNavigation() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      color: Colors.black,
      child: Row(
        children: [
          // 左侧返回按钮
          GestureDetector(
            onTap: () {
              Navigator.pop(context);
            },
            child: Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(shape: BoxShape.circle),
              child: const Icon(
                Icons.keyboard_arrow_down,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),

          // 中央标题
          const Expanded(
            child: Center(
              child: Text(
                '照片',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          // 右侧占位（保持对称）
          const SizedBox(width: 32),
        ],
      ),
    );
  }

  // 横向分类滚动栏
  Widget _buildCategoryTabs() {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(vertical: 8),
      color: Colors.black,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _themes.length + 1, // +1 for user avatar
        itemBuilder: (context, index) {
          if (index == 0) {
            // 用户头像
            return Container(
              margin: const EdgeInsets.only(right: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Center(
                      child: Text('👨', style: TextStyle(fontSize: 20)),
                    ),
                  ),
                ],
              ),
            );
          }

          final theme = _themes[index - 1];
          final isSelected = theme.id == _selectedCategoryId;

          return GestureDetector(
            onTap: () => _selectCategory(theme.id),
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 分类标签
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(25),
                      border: isSelected
                          ? null
                          : Border.all(color: Colors.grey[600]!, width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          theme.title,
                          style: TextStyle(
                            color: isSelected ? Colors.black : Colors.white,
                            fontSize: 14,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(theme.emoji, style: const TextStyle(fontSize: 16)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // 内容区域
  Widget _buildContentArea() {
    return SingleChildScrollView(
      controller: _scrollController,
      child: Column(
        children: _themes.map((theme) => _buildThemeSection(theme)).toList(),
      ),
    );
  }

  // 写真主题内容块
  Widget _buildThemeSection(PhotoshootTheme theme) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题行
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    theme.emoji,
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            theme.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.trending_up,
                          color: Colors.orange,
                          size: 16,
                        ),
                      ],
                    ),
                    Text(
                      theme.subtitle,
                      style: TextStyle(color: Colors.grey[400], fontSize: 14),
                    ),
                  ],
                ),
              ),
              Text(
                '${theme.photoCount}',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (context, animation, secondaryAnimation) =>
                          PhotoUploadGuidePage(selectedThemeId: theme.id),
                      transitionsBuilder:
                          (context, animation, secondaryAnimation, child) {
                            const begin = Offset(0.0, 1.0); // 从下方开始
                            const end = Offset.zero; // 到达正常位置
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
                      transitionDuration: const Duration(milliseconds: 400),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    '获取完整包',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // 照片网格
          SizedBox(
            height: 160, // 两行照片的高度
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 1.0,
              ),
              itemCount: theme.previewImages.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedImageUrl = theme.previewImages[index];
                      _selectedThemeId = theme.id; // 保存选中的主题ID
                      _showPresetDialog = true;
                    });
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      theme.previewImages[index],
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[800],
                          child: const Icon(Icons.error, color: Colors.white54),
                        );
                      },
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

  // 预设选择弹窗
  Widget _buildPresetDialog() {
    final selectedTheme = _selectedThemeId != null
        ? PhotoshootThemes.getThemeById(_selectedThemeId!)
        : null;

    return Container(
      color: Colors.black.withOpacity(0.8),
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 图片区域 + 关闭按钮
              Stack(
                children: [
                  // 图片占满顶部
                  Container(
                    width: double.infinity,
                    height: 400,
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                      child: _selectedImageUrl != null
                          ? Image.asset(
                              _selectedImageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey[300],
                                  child: const Icon(
                                    Icons.error,
                                    color: Colors.grey,
                                  ),
                                );
                              },
                            )
                          : Container(
                              color: Colors.grey[300],
                              child: const Icon(
                                Icons.image,
                                color: Colors.grey,
                              ),
                            ),
                    ),
                  ),

                  // 左上角关闭按钮
                  Positioned(
                    top: 16,
                    left: 16,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _showPresetDialog = false;
                          _selectedImageUrl = null; // 清除选中的图片
                        });
                      },
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
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

                  // 图片底部提示文字
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.7),
                          ],
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.info_outline,
                              color: Colors.grey[700],
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              selectedTheme != null
                                  ? '${selectedTheme.title} - ${selectedTheme.subtitle}'
                                  : '我们将使用此预设的风格和构图来生成您的照片',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // 底部白色空白区域
              const SizedBox(height: 24),

              // 黑色按钮
              Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 24),
                child: ElevatedButton(
                  onPressed: () {
                    // 先保存当前选中的主题ID，避免在清除状态时丢失
                    final currentThemeId = _selectedThemeId;

                    setState(() {
                      _showPresetDialog = false;
                      _selectedImageUrl = null;
                      _selectedThemeId = null;
                    });

                    // 跳转到照片上传引导页面，传递保存的主题ID
                    Navigator.push(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (context, animation, secondaryAnimation) =>
                            PhotoUploadGuidePage(
                              selectedThemeId: currentThemeId,
                            ),
                        transitionsBuilder:
                            (context, animation, secondaryAnimation, child) {
                              const begin = Offset(0.0, 1.0); // 从下方开始
                              const end = Offset.zero; // 到达正常位置
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
                        transitionDuration: const Duration(milliseconds: 400),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '使用此预设',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward, color: Colors.white, size: 18),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // 选择分类
  void _selectCategory(String categoryId) {
    setState(() {
      _selectedCategoryId = categoryId;
    });

    // 滚动到对应分类
    final index = _themes.indexWhere((theme) => theme.id == categoryId);
    if (index != -1) {
      _scrollController.animateTo(
        index * 400.0, // 估算每个分类块的高度
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  // 根据initialCategoryId设置默认预览图片
  void _setDefaultPreviewImage() {
    // 查找对应的主题
    final theme = _themes.firstWhere(
      (theme) => theme.id == widget.initialCategoryId,
      orElse: () => _themes.first, // 如果找不到，使用第一个主题
    );

    // 设置该主题的第一张预览图
    if (theme.previewImages.isNotEmpty) {
      _selectedImageUrl = theme.previewImages.first;
      _selectedThemeId = theme.id;

      debugPrint('🖼️ PhotoGalleryPage: 设置默认预览图片');
      debugPrint('🎯 主题ID: ${theme.id}');
      debugPrint('🖼️ 预览图片: $_selectedImageUrl');
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
