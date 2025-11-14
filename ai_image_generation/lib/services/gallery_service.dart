import 'package:photo_manager/photo_manager.dart';
import 'package:flutter/foundation.dart';

class GalleryService extends ChangeNotifier {
  static final GalleryService _instance = GalleryService._internal();
  factory GalleryService() => _instance;
  GalleryService._internal();

  List<AssetEntity> _allImages = [];
  List<String?> _displayedImageUrls = []; // 当前显示的图片URL，null表示占位符
  bool _isLoading = false;
  bool _hasPermission = false;
  int _loadedCount = 0; // 已加载的图片数量

  List<AssetEntity> get allImages => _allImages;
  List<String?> get displayedImageUrls => _displayedImageUrls;
  bool get isLoading => _isLoading;
  bool get hasPermission => _hasPermission;
  int get loadedCount => _loadedCount;
  int get totalCount => _allImages.length;

  // 初始化并获取相册图片
  Future<void> initialize() async {
    if (_isLoading) return;

    _isLoading = true;
    notifyListeners();

    try {
      // 请求相册权限
      final permission = await PhotoManager.requestPermissionExtend();
      _hasPermission = permission.isAuth || permission.hasAccess;

      debugPrint('相册权限状态: $permission, hasPermission: $_hasPermission');

      if (!_hasPermission) {
        debugPrint('相册权限被拒绝');
        _isLoading = false;
        notifyListeners();
        return;
      }

      // 获取所有相册
      final albums = await PhotoManager.getAssetPathList(
        type: RequestType.image,
        onlyAll: true, // 只获取"所有照片"相册
      );

      if (albums.isNotEmpty) {
        // 获取所有图片，不限制数量
        final recentAlbum = albums.first;
        _allImages = await recentAlbum.getAssetListPaged(
          page: 0,
          size: await recentAlbum.assetCountAsync, // 获取相册中所有图片
        );

        debugPrint('成功加载 ${_allImages.length} 张相册图片');

        // 预先创建占位符数组，长度等于总图片数
        _displayedImageUrls = List.filled(_allImages.length, null);

        // 立即加载前20张图片
        await _loadMoreImages(20);
      }
    } catch (e) {
      debugPrint('获取相册图片失败: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 获取图片的缩略图URL (用于显示)
  Future<String?> getImageUrl(AssetEntity asset) async {
    try {
      // 获取缩略图文件
      final file = await asset.file;
      return file?.path;
    } catch (e) {
      debugPrint('获取图片URL失败: $e');
      return null;
    }
  }

  // 分批加载更多图片 - 交替分配到两行
  Future<void> _loadMoreImages(int count) async {
    if (_loadedCount >= _allImages.length) return;

    final endIndex = (_loadedCount + count).clamp(0, _allImages.length);

    for (int i = _loadedCount; i < endIndex; i++) {
      try {
        final asset = _allImages[i];
        final file = await asset.file;
        if (file != null && file.path.isNotEmpty) {
          // 计算应该放在数组中的哪个位置 - 交替分配
          final targetIndex = _calculateTargetIndex(i);
          if (targetIndex < _displayedImageUrls.length) {
            _displayedImageUrls[targetIndex] = file.path;
          }
        }
      } catch (e) {
        // 跳过无法获取的图片，保持占位符
        continue;
      }
    }

    _loadedCount = endIndex;
    notifyListeners();
  }

  // 计算目标索引 - 让图片交替分配到两行
  int _calculateTargetIndex(int sourceIndex) {
    final totalHalf = _allImages.length ~/ 2;

    if (sourceIndex % 2 == 0) {
      // 偶数索引放第一行
      return sourceIndex ~/ 2;
    } else {
      // 奇数索引放第二行
      return totalHalf + (sourceIndex ~/ 2);
    }
  }

  // 加载下一批图片 (每次20张)
  Future<void> loadNextBatch() async {
    if (_loadedCount < _allImages.length) {
      await _loadMoreImages(20);
    }
  }

  // 刷新相册数据 - 完全重新加载
  Future<void> refresh() async {
    _loadedCount = 0;
    await initialize();
  }

  // 添加用户手动选择的图片到显示列表中
  Future<void> addSelectedImages(List<String> imagePaths) async {
    try {
      debugPrint('添加 ${imagePaths.length} 张选中的图片到列表');
      
      // 将新选择的图片路径添加到显示列表的末尾
      for (String imagePath in imagePaths) {
        // 检查是否已经存在，避免重复添加
        if (!_displayedImageUrls.contains(imagePath)) {
          _displayedImageUrls.add(imagePath);
          debugPrint('添加图片: $imagePath');
        } else {
          debugPrint('图片已存在，跳过: $imagePath');
        }
      }
      
      // 通知监听者更新UI
      notifyListeners();
      
      debugPrint('成功添加图片，当前显示列表总数: ${_displayedImageUrls.length}');
    } catch (e) {
      debugPrint('添加选中图片失败: $e');
    }
  }

  // 在部分授权状态下，拉起iOS权限扩展界面
  Future<void> presentLimitedLibraryPicker() async {
    try {
      debugPrint('拉起iOS权限扩展界面');
      await PhotoManager.presentLimited();
      debugPrint('权限扩展界面已关闭');
    } catch (e) {
      debugPrint('拉起权限扩展界面失败: $e');
    }
  }
}
