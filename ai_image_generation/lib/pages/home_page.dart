import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import '../widgets/index.dart';
import '../models/category_model.dart';
import '../models/photobooth_model.dart';
import '../services/generation_service.dart';
import '../services/gallery_service.dart';
import '../services/enhance_service.dart';
import '../services/auth_guard.dart';
import '../widgets/generation_status_bar.dart';
import '../widgets/expandable_fab.dart';
import 'photo_gallery_page.dart';
import 'ai_photo_intro_page.dart';
import 'image_enhance_page.dart';
import 'ai_filter_page.dart';
import 'custom_ai_edit_page.dart';
import 'photo_upload_page.dart';
import 'photobooth_result_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  // int _selectedTabIndex = 0; // 暂时注释，因为移除了Photos/Videos标签
  late List<CategoryModel> _categories;
  late ScrollController _scrollController;
  late GenerationService _generationService;
  late GalleryService _galleryService;
  bool _isProgressDialogShowing = false; // 跟踪进度弹窗是否正在显示
  Timer? _batchLoadTimer; // 分批加载定时器
  bool _hasJumpedToSettings = false; // 跳转设置标记
  PermissionStatus _photoPermissionStatus = PermissionStatus.denied; // 权限状态

  @override
  void initState() {
    super.initState();
    _categories = CategoryModel.getDummyCategories();
    _scrollController = ScrollController();
    _generationService = GenerationService();
    _galleryService = GalleryService();

    // 添加生命周期监听器
    WidgetsBinding.instance.addObserver(this);

    // 监听生成完成事件，自动弹出完成对话框
    _generationService.addListener(_onGenerationStatusChanged);

    // 监听相册变化
    _galleryService.addListener(_onGalleryChanged);

    // 初始化滚动监听
    _scrollController.addListener(() {
      // 滚动监听逻辑
    });

    // 初始化权限检查和相册
    _initializePermissionsAndGallery();
  }

  @override
  void dispose() {
    // 移除生命周期监听器
    WidgetsBinding.instance.removeObserver(this);

    _scrollController.dispose();
    _generationService.removeListener(_onGenerationStatusChanged);
    _galleryService.removeListener(_onGalleryChanged);
    _batchLoadTimer?.cancel();
    super.dispose();
  }

  // 生命周期状态变化监听
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _hasJumpedToSettings) {
      // 从设置返回，执行应用重启
      _hasJumpedToSettings = false;
      Phoenix.rebirth(context);
    }
  }

  // 初始化权限检查和相册
  Future<void> _initializePermissionsAndGallery() async {
    try {
      // 检查权限状态
      _photoPermissionStatus = await Permission.photos.status;
      debugPrint('当前权限状态: $_photoPermissionStatus');

      // 如果是第一次使用（未询问状态），主动请求权限
      if (_photoPermissionStatus == PermissionStatus.denied) {
        // 检查是否是真正拒绝还是未询问
        final shouldRequestPermission =
            await Permission.photos.shouldShowRequestRationale == false;
        if (shouldRequestPermission) {
          debugPrint('首次访问，主动请求相册权限');
          final requestResult = await Permission.photos.request();
          debugPrint('权限请求结果: $requestResult');
          _photoPermissionStatus = requestResult;
        } else {
          debugPrint('权限已被永久拒绝');
        }
      }

      // 根据权限状态初始化相册
      if (_photoPermissionStatus == PermissionStatus.granted) {
        await _galleryService.initialize();
        if (_galleryService.hasPermission) {
          _startBatchLoadTimer();
        }
      } else if (_photoPermissionStatus == PermissionStatus.limited) {
        // 部分授权时也需要初始化相册服务
        await _galleryService.initialize();
        if (_galleryService.hasPermission) {
          _startBatchLoadTimer();
          debugPrint('部分授权状态下启动分批加载定时器');
        }
      }

      // 更新UI
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint('初始化权限和相册失败: $e');
      // 如果权限检查失败，默认为拒绝状态
      _photoPermissionStatus = PermissionStatus.denied;
      if (mounted) {
        setState(() {});
      }
    }
  }

  // 选择图片用于增强功能 - 拉起权限扩展界面
  Future<void> _selectImageForEnhance() async {
    try {
      // 在部分授权状态下，拉起iOS权限扩展界面
      if (_photoPermissionStatus == PermissionStatus.limited) {
        debugPrint('部分授权状态，拉起权限扩展界面');
        await _galleryService.presentLimitedLibraryPicker();

        // 权限界面关闭后，重新初始化相册服务以获取最新的授权图片
        await _galleryService.refresh();

        // 刷新UI
        if (mounted) {
          setState(() {});
        }
      } else {
        // 其他状态使用普通图片选择器
        final ImagePicker picker = ImagePicker();
        final List<XFile> images = await picker.pickMultiImage(
          maxWidth: 1920,
          maxHeight: 1920,
          imageQuality: 85,
        );

        if (images.isNotEmpty) {
          debugPrint('选择了 ${images.length} 张图片');

          // 将选中的图片添加到相册服务中
          final List<String> imagePaths = images
              .map((image) => image.path)
              .toList();
          await _galleryService.addSelectedImages(imagePaths);

          // 刷新UI
          if (mounted) {
            setState(() {});
          }
        }
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

  // 相册数据变化监听
  void _onGalleryChanged() {
    // 使用postFrameCallback延迟执行，避免在build期间调用setState
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          // 触发界面重建，显示新加载的图片
        });
      }
    });
  }

  // 启动分批加载定时器
  void _startBatchLoadTimer() {
    _batchLoadTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      await _galleryService.loadNextBatch();

      // 如果已经加载完所有图片，停止定时器
      if (_galleryService.loadedCount >= _galleryService.totalCount) {
        timer.cancel();
        debugPrint('所有相册图片加载完成');
      }
    });
  }

  // 生成状态变化监听
  void _onGenerationStatusChanged() {
    if (_generationService.status == GenerationStatus.completed) {
      // 使用postFrameCallback延迟执行，避免在build期间调用
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          // 如果进度弹窗正在显示，先关闭它
          if (_isProgressDialogShowing) {
            Navigator.pop(context); // 关闭进度弹窗
            _isProgressDialogShowing = false;
          }

          // 自动弹出完成对话框
          _showGenerationCompleteDialog();
        }
      });
    }
  }

  // 显示生成完成对话框
  void _showGenerationCompleteDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => GenerationCompleteDialog(
        onViewResults: () {
          // 跳转到Photobooth结果页面
          debugPrint('查看生成结果: ${_generationService.generatedResults}');
          if (_generationService.generatedResults.isNotEmpty) {
            Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    PhotoboothResultPage(
                      imagePath: _generationService.generatedResults.first,
                    ),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                      const begin = Offset(0.0, 1.0); // 从下方开始
                      const end = Offset.zero; // 到达正常位置
                      const curve = Curves.easeOutQuart;

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
          }
        },
        onMaybeLater: () {
          // 保持完成状态，不清除
          debugPrint('也许以后查看');
        },
      ),
    );
  }

  // 处理生成状态栏点击
  void _onGenerationStatusBarTap() {
    if (_generationService.status == GenerationStatus.generating) {
      // 显示进度对话框
      _isProgressDialogShowing = true;
      showDialog(
        context: context,
        barrierDismissible: false, // 防止用户手动关闭
        builder: (context) => GenerationProgressDialog(
          onDismiss: () {
            _isProgressDialogShowing = false;
          },
        ),
      ).then((_) {
        // 弹窗关闭时重置状态
        _isProgressDialogShowing = false;
      });
    } else if (_generationService.status == GenerationStatus.completed) {
      // 点击粉色状态块时清除完成状态，让状态栏消失
      _generationService.clearCompletedTask();
      debugPrint('用户点击粉色状态块，已清除完成状态');
    }
  }

  // 处理操作按钮点击
  Future<void> _onActionButtonTapped(String action) async {
    debugPrint('点击了操作按钮: $action');

    // 所有生成相关操作前统一鉴权
    final loggedIn = await AuthGuard.ensureLoggedIn(context);
    if (!loggedIn) {
      debugPrint('未登录，已中断操作: $action');
      return;
    }

    switch (action) {
      case 'enhance':
        await _handleEnhanceAction();
        break;
      case 'ai_photo':
        await _handleAiPhotoAction();
        break;
      case 'ai_filter':
        await _handleAiFilterAction();
        break;
      case 'text_edit':
        await _handleCustomAiEditAction();
        break;
    }
  }

  // 处理增强功能
  Future<void> _handleEnhanceAction() async {
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
        // 调用现有的增强底部sheet
        _showEnhanceBottomSheet(image.path);
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

  // 处理AI照片功能
  Future<void> _handleAiPhotoAction() async {
    debugPrint('启动AI照片功能');

    // 跳转到AI照片介绍页面
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const AiPhotoIntroPage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
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
  }

  // 处理AI滤镜功能
  Future<void> _handleAiFilterAction() async {
    debugPrint('启动AI滤镜功能');

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AiFilterPage()),
    );
  }

  Future<void> _handleCustomAiEditAction() async {
    debugPrint('启动自定义AI编辑功能');

    // 直接跳转到自定义AI编辑页面
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CustomAiEditPage()),
    );
  }

  // 构建权限引导卡片 - 完全拒绝状态
  Widget _buildDeniedPermissionCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // 左侧灰色照片图标
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.photo_library_outlined,
              color: Colors.grey[600],
              size: 24,
            ),
          ),

          const SizedBox(width: 16),

          // 中间文案
          const Expanded(
            child: Text(
              '未授予Remini照片访问权限。',
              style: TextStyle(
                color: Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          const SizedBox(width: 16),

          // 右侧黑色按钮
          GestureDetector(
            onTap: () => _requestPermission(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                '授予访问权限',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 构建权限引导卡片 - 部分授权状态
  Widget _buildLimitedPermissionCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // 左侧照片缩略图
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.grey[200],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child:
                  _galleryService.displayedImageUrls.isNotEmpty &&
                      _galleryService.displayedImageUrls.first != null
                  ? Image.file(
                      File(_galleryService.displayedImageUrls.first!),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          Icons.photo,
                          color: Colors.grey[600],
                          size: 24,
                        );
                      },
                    )
                  : Icon(Icons.photo, color: Colors.grey[600], size: 24),
            ),
          ),

          const SizedBox(width: 16),

          // 中间文案
          const Expanded(
            child: Text(
              '只授予了Remini选定照片的访问权限。',
              style: TextStyle(
                color: Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          const SizedBox(width: 16),

          // 右侧黑色"更改"按钮
          GestureDetector(
            onTap: () => _requestPermission(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                '更改',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 请求权限 - 直接跳转设置，无弹窗
  Future<void> _requestPermission() async {
    try {
      _hasJumpedToSettings = true;
      await openAppSettings();
    } catch (e) {
      debugPrint('跳转设置失败: $e');
    }
  }

  // 构建部分授权时的照片网格和导入功能 - 两排横向滚动
  Widget _buildLimitedPhotosGrid() {
    // 过滤掉null值，只获取实际加载成功的图片
    final List<String> actualImageUrls = _galleryService.displayedImageUrls
        .where((url) => url != null)
        .cast<String>()
        .toList();

    debugPrint(
      '部分授权网格 - 实际图片数量: ${actualImageUrls.length}, 总数量: ${_galleryService.displayedImageUrls.length}',
    );

    // 准备图片URL列表：第一个是null(表示导入组件)，后面是已授权的照片
    final List<String?> imageUrlsWithImport = [];

    // 第一个位置：null表示导入组件
    imageUrlsWithImport.add(null);

    // 后面：只添加非null的图片URL
    imageUrlsWithImport.addAll(actualImageUrls);

    return _LimitedPhotoHorizontalGrid(
      imageUrls: imageUrlsWithImport,
      onItemTap: (index) {
        if (index == 0) {
          // 第一个是导入组件
          _selectImageForEnhance();
        } else {
          // 后面的是相册图片，需要找到实际的图片索引
          final actualImageIndex = index - 1; // 减1因为第一个是导入组件
          if (actualImageIndex < actualImageUrls.length) {
            _onImageTapped(
              _categories.firstWhere((cat) => cat.id == 'enhance'),
              actualImageIndex,
            );
          }
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 主要内容区域
          SafeArea(
            child: Column(
              children: [
                // 固定在顶部的导航栏
                const TopNavigationBar(),

                // 可滚动的内容区域
                Expanded(
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    child: Column(
                      children: [
                        const SizedBox(height: 20),

                        // 动态分类内容
                        ..._buildCategorySections(),

                        // 底部额外间距，适应底部标签栏
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 生成状态栏 - 位于底部标签栏上方
          Positioned(
            bottom: 80, // 适应底部标签栏高度
            left: 0,
            right: 0,
            child: GenerationStatusBar(
              generationService: _generationService,
              onTap: _onGenerationStatusBarTap,
            ),
          ),

          // 新的扇形展开FAB
          Positioned.fill(
            child: ExpandableFab(onActionTapped: _onActionButtonTapped),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildCategorySections() {
    List<Widget> sections = [];

    for (int i = 0; i < _categories.length; i++) {
      final category = _categories[i];

      sections.add(_buildCategorySection(category));

      // 添加间距（除了最后一个）
      if (i < _categories.length - 1) {
        sections.add(const SizedBox(height: 30));
      }
    }

    return sections;
  }

  Widget _buildCategorySection(CategoryModel category) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 分类标题
        SectionHeader(
          title: category.title,
          emoji: category.emoji,
          showSeeAll: category.showSeeAll,
          onSeeAllPressed: () => _onSeeAllPressed(category),
        ),

        const SizedBox(height: 15),

        // 根据类型渲染不同的内容
        _buildCategoryContent(category),
      ],
    );
  }

  Widget _buildCategoryContent(CategoryModel category) {
    switch (category.type) {
      case CategoryType.horizontal:
        return _buildHorizontalSection(category);
      case CategoryType.grid:
        return _buildGridSection(category);
    }
  }

  Widget _buildHorizontalSection(CategoryModel category) {
    String placeholderIcon = 'image'; // 默认图标

    // 根据分类ID设置不同的占位符图标
    switch (category.id) {
      case 'art_toy':
        placeholderIcon = 'palette';
        break;
      case 'sunset_glow':
        placeholderIcon = 'image';
        break;
      case 'muscle_filter':
        placeholderIcon = 'fitness';
        break;
      case 'old_money':
        placeholderIcon = 'person';
        break;
      case 'beach_sunset':
        placeholderIcon = 'landscape';
        break;
      default:
        placeholderIcon = 'image';
    }

    return HorizontalImageList(
      imageUrls: category.imageUrls,
      showAvatars: category.id == 'photobooth', // 只有photobooth显示头像
      placeholderIcon: placeholderIcon,
      onItemTap: (index) => _onImageTapped(category, index),
    );
  }

  Widget _buildGridSection(CategoryModel category) {
    // 对于Enhance分类，根据权限状态显示不同内容
    if (category.id == 'enhance') {
      debugPrint('构建Enhance分类，权限状态: $_photoPermissionStatus');
      return Column(
        children: [
          // 根据权限状态显示不同内容
          if (_photoPermissionStatus == PermissionStatus.denied ||
              _photoPermissionStatus == PermissionStatus.permanentlyDenied) ...[
            // 完全拒绝权限 - 显示引导卡片
            _buildDeniedPermissionCard(),

            const SizedBox(height: 16),

            // 底部说明文案
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  Text(
                    '首先，Remini需要获取照片访问权限，',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    '你也可以从设备中选择一张照片。',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 24),

                  Text(
                    '从设备增强照片',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ] else if (_photoPermissionStatus == PermissionStatus.limited) ...[
            // 部分授权 - 显示限制权限卡片
            _buildLimitedPermissionCard(),

            const SizedBox(height: 16),

            // 显示已选择的照片网格和导入照片功能
            _buildLimitedPhotosGrid(),
          ] else if (_photoPermissionStatus == PermissionStatus.granted) ...[
            // 完全授权 - 显示正常的照片网格
            PhotoHorizontalGrid(
              imageUrls: _galleryService.displayedImageUrls,
              showQRCode: false,
              onItemTap: (index) => _onImageTapped(category, index),
            ),
          ] else ...[
            // 默认情况（包括初始状态）- 显示拒绝权限卡片
            _buildDeniedPermissionCard(),

            const SizedBox(height: 16),

            // 底部说明文案
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  Text(
                    '首先，Remini需要获取照片访问权限，',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    '你也可以从设备中选择一张照片。',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 24),

                  Text(
                    '从设备增强照片',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ],
      );
    }

    // 非Enhance分类的正常显示
    return Column(
      children: [
        PhotoHorizontalGrid(
          imageUrls: category.imageUrls,
          showQRCode: false,
          onItemTap: (index) => _onImageTapped(category, index),
        ),
      ],
    );
  }

  void _onSeeAllPressed(CategoryModel category) {
    // TODO: 导航到对应分类的详细页面
    debugPrint('查看更多: ${category.title}');
  }

  Future<void> _onImageTapped(CategoryModel category, int index) async {
    // 所有点击卡片进入生成流程前统一鉴权
    final loggedIn = await AuthGuard.ensureLoggedIn(context);
    if (!loggedIn) {
      debugPrint('未登录，已中断分类点击: ${category.id}, index: $index');
      return;
    }

    if (category.id == 'photobooth') {
      // Photobooth分类点击跳转到PhotoUploadPage，传递effectId
      final effects = PhotoboothModel.getAllEffects();
      String? effectId;
      if (index < effects.length) {
        effectId = effects[index].id;
        debugPrint(
          '🎯 选择了 Photobooth 效果: ${effects[index].title} (ID: $effectId)',
        );
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PhotoUploadPage(effectId: effectId),
        ),
      );
    } else if (category.id == 'enhance') {
      // Enhance分类点击弹出底部半屏
      final galleryImages = _galleryService.displayedImageUrls;
      if (index < galleryImages.length && galleryImages[index] != null) {
        _showEnhanceBottomSheet(galleryImages[index]!);
      }
    } else if (category.id == 'art_toy') {
      // Art Toy分类点击跳转到AI滤镜页面，根据图片索引选择对应滤镜（前8个）
      final filterIds = [
        'art_toy', // 第0张图片 → Art Toy滤镜
        'oil_painting', // 第1张图片 → Oil Painting滤镜
        'watercolor', // 第2张图片 → Watercolor滤镜
        'sketch', // 第3张图片 → Sketch滤镜
        'pop_art', // 第4张图片 → Pop Art滤镜
        'abstract_art', // 第5张图片 → Abstract Art滤镜
        'vintage_film', // 第6张图片 → Vintage滤镜
        'neon_glow', // 第7张图片 → Cyberpunk滤镜
      ];

      // 根据点击的图片索引选择对应的滤镜ID
      final selectedFilterId = index < filterIds.length
          ? filterIds[index]
          : 'art_toy';

      debugPrint(
        '点击了 ${category.title} 的第 $index 张图片，默认选中滤镜: $selectedFilterId',
      );
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AiFilterPage(defaultFilterId: selectedFilterId),
        ),
      );
    } else if (category.id == 'sunset_glow') {
      // Sunset glow分类点击跳转到自定义AI编辑页面
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const CustomAiEditPage()),
      );
    } else if (category.id == 'fitness_model_preview') {
      // Fitness Model写真预览 - 跳转到写真主题页面，聚焦健身模特
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const PhotoGalleryPage(initialCategoryId: 'fitness_model'),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
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
    } else if (category.id == 'beach_lifestyle_preview') {
      // Beach Lifestyle写真预览 - 跳转到写真主题页面，聚焦海滩生活
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const PhotoGalleryPage(initialCategoryId: 'beach_lifestyle'),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
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
    } else if (category.id == 'urban_fashion_preview') {
      // Urban Fashion写真预览 - 跳转到写真主题页面，聚焦都市时尚
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const PhotoGalleryPage(initialCategoryId: 'urban_fashion'),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
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
    } else {
      // 其他分类的点击处理
      // TODO: 其他分类的具体处理逻辑
    }
  }

  // 显示增强功能的底部半屏
  void _showEnhanceBottomSheet(String imagePath) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // 允许控制高度
      backgroundColor: Colors.transparent,
      builder: (context) => _EnhanceBottomSheetContent(imagePath: imagePath),
    );
  }
}

// 增强功能底部弹窗内容组件
class _EnhanceBottomSheetContent extends StatefulWidget {
  final String imagePath;

  const _EnhanceBottomSheetContent({required this.imagePath});

  @override
  State<_EnhanceBottomSheetContent> createState() =>
      _EnhanceBottomSheetContentState();
}

class _EnhanceBottomSheetContentState extends State<_EnhanceBottomSheetContent>
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

  // 开始真实AI处理
  void _startProcessing() async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
      _processingText = '正在上传照片...';
    });

    _loadingController.repeat();

    try {
      debugPrint('🎨 开始AI图片增强: ${widget.imagePath}');

      // 调用真实的AI增强服务
      final enhancedPath = await EnhanceService.basicEnhance(
        imagePath: widget.imagePath,
        onProgressUpdate: (progress) {
          if (mounted) {
            setState(() {
              _processingText = progress;
            });
          }
        },
      );

      if (mounted) {
        _loadingController.stop();

        if (enhancedPath != null) {
          // 处理成功，跳转到增强结果页面
          debugPrint('✅ AI增强成功: $enhancedPath');
          Navigator.pop(context); // 关闭底部sheet
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  ImageEnhancePage(
                    imagePath: widget.imagePath, // 原图路径
                    enhancedImagePath: enhancedPath, // 增强后图片路径
                  ),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                    const begin = Offset(0.0, 1.0);
                    const end = Offset.zero;
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
        } else {
          // AI处理失败
          debugPrint('❌ AI增强失败');
          setState(() {
            _processingText = 'AI增强失败，请重试';
            _isProcessing = false;
          });

          // 3秒后自动关闭弹窗
          Future.delayed(const Duration(seconds: 3), () {
            if (mounted) {
              Navigator.pop(context);
            }
          });
        }
      }
    } catch (e) {
      debugPrint('❌ AI增强异常: $e');
      if (mounted) {
        _loadingController.stop();
        setState(() {
          _processingText = '网络错误，请重试';
          _isProcessing = false;
        });

        // 3秒后自动关闭弹窗
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            Navigator.pop(context);
          }
        });
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
                  child: const Icon(Icons.close, color: Colors.white, size: 24),
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

// 部分授权专用的两排横向滚动组件
class _LimitedPhotoHorizontalGrid extends StatelessWidget {
  final List<String?> imageUrls;
  final Function(int)? onItemTap;

  const _LimitedPhotoHorizontalGrid({required this.imageUrls, this.onItemTap});

  @override
  Widget build(BuildContext context) {
    const double itemWidth = 120;
    const double itemHeight = 120;
    const double spacing = 12.0;

    // 部分授权只显示实际的图片数量，不需要很多占位符
    final int totalItems = imageUrls.length;

    // 优化分配：确保上排至少有2张图片
    int firstRowCount;
    int secondRowCount;

    if (totalItems <= 2) {
      // 总数不超过2张，全部放上排
      firstRowCount = totalItems;
      secondRowCount = 0;
    } else if (totalItems == 3) {
      // 3张图片：上排2张，下排1张
      firstRowCount = 2;
      secondRowCount = 1;
    } else {
      // 4张及以上：上排至少2张，剩余均匀分配
      firstRowCount = (totalItems + 1) ~/ 2; // 向上取整，确保上排不少于下排
      if (firstRowCount < 2) firstRowCount = 2; // 确保至少2张
      secondRowCount = totalItems - firstRowCount;
    }

    final List<int> firstRowItems = List.generate(
      firstRowCount,
      (index) => index,
    );
    final List<int> secondRowItems = List.generate(
      secondRowCount,
      (index) => index + firstRowCount,
    );

    return SizedBox(
      height: secondRowCount > 0 ? (itemHeight * 2) + spacing : itemHeight,
      child: Column(
        children: [
          // 第一行
          _buildHorizontalRow(firstRowItems, 0, itemWidth, itemHeight, spacing),

          // 第二行（如果有内容才显示）
          if (secondRowCount > 0) ...[
            const SizedBox(height: spacing),
            _buildHorizontalRow(
              secondRowItems,
              firstRowCount,
              itemWidth,
              itemHeight,
              spacing,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHorizontalRow(
    List<int> rowItems,
    int startIndex,
    double itemWidth,
    double itemHeight,
    double spacing,
  ) {
    return Expanded(
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(left: 20),
        itemCount: rowItems.length,
        itemBuilder: (context, index) {
          final actualIndex = startIndex + index;
          return _buildPhotoItem(
            context,
            actualIndex,
            itemWidth,
            itemHeight,
            spacing,
          );
        },
      ),
    );
  }

  Widget _buildPhotoItem(
    BuildContext context,
    int index,
    double itemWidth,
    double itemHeight,
    double spacing,
  ) {
    return GestureDetector(
      onTap: () => onItemTap?.call(index),
      child: Container(
        width: itemWidth,
        height: itemHeight,
        margin: EdgeInsets.only(right: spacing),
        decoration: BoxDecoration(
          color: index == 0
              ? const Color(0xFF404040)
              : const Color(0xFF2F2F2F), // 上传组件用浅灰色
          borderRadius: BorderRadius.circular(12),
        ),
        child: _buildItemContent(index),
      ),
    );
  }

  Widget _buildItemContent(int index) {
    // 第一个位置：导入组件
    if (index == 0) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.add, color: Colors.white, size: 24),
          const SizedBox(height: 4),
          const Text(
            '导入照片',
            style: TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    // 其他位置：图片或占位符
    if (imageUrls.isNotEmpty && index < imageUrls.length) {
      final imageUrl = imageUrls[index];

      if (imageUrl == null) {
        return _buildPlaceholder();
      }

      final isLocalFile =
          imageUrl.startsWith('/') || imageUrl.startsWith('file://');
      final isAsset = imageUrl.startsWith('assets/');

      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: isAsset
            ? Image.asset(
                imageUrl,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                cacheWidth: 400, // 首页缩略图缓存限制
                cacheHeight: 400, // 首页缩略图缓存限制
                errorBuilder: (context, error, stackTrace) {
                  debugPrint('首页assets图片加载失败: $imageUrl, 错误: $error');
                  return _buildPlaceholder();
                },
              )
            : isLocalFile
            ? Image.file(
                File(imageUrl),
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                cacheWidth: 400, // 首页缩略图缓存限制
                cacheHeight: 400, // 首页缩略图缓存限制
                errorBuilder: (context, error, stackTrace) {
                  return _buildPlaceholder();
                },
              )
            : Image.network(
                imageUrl,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return _buildPlaceholder();
                },
                errorBuilder: (context, error, stackTrace) {
                  return _buildPlaceholder();
                },
              ),
      );
    }

    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF404040),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(Icons.photo, color: Colors.white54, size: 30),
    );
  }
}
