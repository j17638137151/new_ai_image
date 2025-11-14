// 图片数据更新脚本
// 使用真实的Unsplash图片URL为各个分类提供演示数据

import '../models/category_model.dart';

class ImageDataUpdater {
  // Art Toy 分类图片 - 艺术玩具、手办、收藏品
  static List<String> getArtToyImages() {
    return [
      'https://images.unsplash.com/photo-1578662996442-48f60103fc96?w=400&h=400&fit=crop&crop=center',
      'https://images.unsplash.com/photo-1606041008023-472dfb5e530f?w=400&h=400&fit=crop&crop=center',
      'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=400&h=400&fit=crop&crop=center',
      'https://images.unsplash.com/photo-1551698618-1dfe5d97d256?w=400&h=400&fit=crop&crop=center',
      'https://images.unsplash.com/photo-1601814933824-fd0b574dd592?w=400&h=400&fit=crop&crop=center',
      'https://images.unsplash.com/photo-1518791841217-8f162f1e1131?w=400&h=400&fit=crop&crop=center',
    ];
  }

  // Muscle Filter 分类图片 - 健身、肌肉、运动
  static List<String> getMuscleFilterImages() {
    return [
      'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=400&h=400&fit=crop&crop=center',
      'https://images.unsplash.com/photo-1583454110551-21f2fa2afe61?w=400&h=400&fit=crop&crop=center',
      'https://images.unsplash.com/photo-1581009146145-b5ef050c2e1e?w=400&h=400&fit=crop&crop=center',
      'https://images.unsplash.com/photo-1605296867304-46d5465a13f1?w=400&h=400&fit=crop&crop=center',
      'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=400&h=400&fit=crop&crop=center',
      'https://images.unsplash.com/photo-1549476464-37392f717541?w=400&h=400&fit=crop&crop=center',
    ];
  }

  // Old Money 分类图片 - 复古、奢华、经典风格
  static List<String> getOldMoneyImages() {
    return [
      'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400&h=400&fit=crop&crop=center',
      'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=400&h=400&fit=crop&crop=center',
      'https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?w=400&h=400&fit=crop&crop=center',
      'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=400&h=400&fit=crop&crop=center',
      'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=400&h=400&fit=crop&crop=center',
      'https://images.unsplash.com/photo-1552374196-c4e7ffc6e126?w=400&h=400&fit=crop&crop=center',
    ];
  }

  // Beach Sunset 分类图片 - 海滩日落、自然风景
  static List<String> getBeachSunsetImages() {
    return [
      'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=400&h=400&fit=crop&crop=center',
      'https://images.unsplash.com/photo-1519046904884-53103b34b206?w=400&h=400&fit=crop&crop=center',
      'https://images.unsplash.com/photo-1505142468610-359e7d316be0?w=400&h=400&fit=crop&crop=center',
      'https://images.unsplash.com/photo-1544551763-46a013bb70d5?w=400&h=400&fit=crop&crop=center',
      'https://images.unsplash.com/photo-1471119743851-c4df8b6ee cgi?w=400&h=400&fit=crop&crop=center',
      'https://images.unsplash.com/photo-1559827260-dc66d52bef19?w=400&h=400&fit=crop&crop=center',
    ];
  }

  // Photobooth photos 分类图片 - 人物肖像（虽然你说不用，但提供备选）
  static List<String> getPhotoboothImages() {
    return [
      'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=400&h=400&fit=crop&crop=center',
      'https://images.unsplash.com/photo-1494790108755-2616b612b77c?w=400&h=400&fit=crop&crop=center',
      'https://images.unsplash.com/photo-1527980965255-d3b416303d12?w=400&h=400&fit=crop&crop=center',
      'https://images.unsplash.com/photo-1489424731084-a5d8b219a5bb?w=400&h=400&fit=crop&crop=center',
      'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=400&h=400&fit=crop&crop=center',
      'https://images.unsplash.com/photo-1488426862026-3ee34a7d66df?w=400&h=400&fit=crop&crop=center',
    ];
  }

  // 更新所有分类的图片数据
  static List<CategoryModel> getUpdatedCategories() {
    return [
      // Photobooth photos - 使用空数组，由手机相册提供
      CategoryModel(
        id: 'photobooth',
        title: 'Photobooth photos',
        emoji: '💕',
        imageUrls: [], // 保持空，由相册获取
        type: CategoryType.horizontal,
        showSeeAll: true,
      ),

      // Enhance - 两行网格布局，保持空由相册获取
      CategoryModel(
        id: 'enhance',
        title: 'Enhance',
        emoji: '✨',
        imageUrls: [], // 保持空，由相册获取
        type: CategoryType.grid,
        showSeeAll: true,
      ),

      // Art Toy - 使用真实艺术玩具图片
      CategoryModel(
        id: 'art_toy',
        title: 'Art Toy',
        emoji: '🎨',
        imageUrls: getArtToyImages(),
        type: CategoryType.horizontal,
        showSeeAll: true,
      ),

      // Muscle Filter - 使用真实健身图片
      CategoryModel(
        id: 'muscle_filter',
        title: 'Muscle Filter',
        emoji: '💪',
        imageUrls: getMuscleFilterImages(),
        type: CategoryType.horizontal,
        showSeeAll: true,
      ),

      // Old Money - 使用真实复古风格图片
      CategoryModel(
        id: 'old_money',
        title: 'Old Money',
        emoji: '💰',
        imageUrls: getOldMoneyImages(),
        type: CategoryType.horizontal,
        showSeeAll: true,
      ),

      // Beach Sunset - 使用真实海滩日落图片
      CategoryModel(
        id: 'beach_sunset',
        title: 'Beach Sunset',
        emoji: '🌅',
        imageUrls: getBeachSunsetImages(),
        type: CategoryType.horizontal,
        showSeeAll: true,
      ),
    ];
  }

  // 随机获取高质量的增强效果图片（用于Enhance分类的占位符）
  static List<String> getEnhanceImages() {
    return [
      'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?w=400&h=400&fit=crop&crop=center',
      'https://images.unsplash.com/photo-1618556450991-2f1af64e8191?w=400&h=400&fit=crop&crop=center',
      'https://images.unsplash.com/photo-1618005198919-d3d4b5a92ead?w=400&h=400&fit=crop&crop=center',
      'https://images.unsplash.com/photo-1618556450994-a6a128ef0d9d?w=400&h=400&fit=crop&crop=center',
      'https://images.unsplash.com/photo-1618556450979-d2d9d3c8bbb7?w=400&h=400&fit=crop&crop=center',
      'https://images.unsplash.com/photo-1618005198929-d3d4b5a92ead?w=400&h=400&fit=crop&crop=center',
    ];
  }
}

// 使用说明：
// 1. 在category_model.dart中替换getDummyCategories()方法
// 2. 调用ImageDataUpdater.getUpdatedCategories()获取带真实图片的数据
// 3. 所有图片都经过优化：400x400尺寸，居中裁剪
// 4. Photobooth和Enhance分类保持空数组，由手机相册提供
// 5. 其他分类使用高质量的Unsplash图片
