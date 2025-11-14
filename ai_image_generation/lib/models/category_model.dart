class CategoryModel {
  final String id;
  final String title;
  final String emoji;
  final List<String> imageUrls;
  final CategoryType type;
  final bool showSeeAll;
  final String? aiPrompt; // AI生成提示词

  CategoryModel({
    required this.id,
    required this.title,
    required this.emoji,
    required this.imageUrls,
    required this.type,
    this.showSeeAll = true,
    this.aiPrompt,
  });

  // 静态数据工厂方法，用于创建模拟数据
  static List<CategoryModel> getDummyCategories() {
    return [
      // Photobooth photos - 多种拥抱效果
      CategoryModel(
        id: 'photobooth',
        title: 'Photobooth photos',
        emoji: '💕',
        imageUrls: [
          'assets/images/photobooth/classic_hug_preview.jpg',
          'assets/images/photobooth/side_hug_preview.jpg',
          'assets/images/photobooth/cheek_hug_preview.jpg',
          'assets/images/photobooth/back_hug_preview.jpg',
          'assets/images/photobooth/shoulder_hug_preview.jpg',
          'assets/images/photobooth/spinning_hug_preview.jpg',
          'assets/images/photobooth/sitting_hug_preview.jpg',
          'assets/images/photobooth/jumping_hug_preview.jpg',
          'assets/images/photobooth/handhold_hug_preview.jpg',
          'assets/images/photobooth/gentle_hug_preview.jpg',
        ],
        type: CategoryType.horizontal,
        showSeeAll: true,
      ),

      // Enhance - 保持空，由手机相册提供
      CategoryModel(
        id: 'enhance',
        title: 'Enhance',
        emoji: '✨',
        imageUrls: [], // 空数据，由相册获取
        type: CategoryType.grid,
        showSeeAll: true,
      ),

      // Art Toy - 使用本地滤镜缩略图（前8个）
      CategoryModel(
        id: 'art_toy',
        title: 'Art Toy',
        emoji: '🎨',
        imageUrls: [
          'assets/images/filters/art_toy_thumbnail.jpg', // Art Toy
          'assets/images/filters/oil_painting_thumbnail.jpg', // Oil Painting
          'assets/images/filters/watercolor_thumbnail.jpg', // Watercolor
          'assets/images/filters/sketch_thumbnail.jpg', // Sketch
          'assets/images/filters/pop_art_thumbnail.jpg', // Pop Art
          'assets/images/filters/abstract_art_thumbnail.jpg', // Abstract Art
          'assets/images/filters/vintage_film_thumbnail.jpg', // Vintage
          'assets/images/filters/neon_glow_thumbnail.jpg', // Cyberpunk
        ],
        type: CategoryType.horizontal,
        showSeeAll: true,
      ),

      // Sunset glow - 跳转自定义编辑页面
      CategoryModel(
        id: 'sunset_glow',
        title: 'Sunset glow',
        emoji: '🌇',
        imageUrls: [
          'assets/images/custom_ai_edit/preview_1.jpg',
          'assets/images/custom_ai_edit/preview_2.jpg',
          'assets/images/custom_ai_edit/preview_3.jpg',
          'assets/images/custom_ai_edit/preview_4.jpg',
          'assets/images/custom_ai_edit/preview_5.jpg',
          'assets/images/custom_ai_edit/preview_6.jpg',
        ], // 数据图片你来搞定
        type: CategoryType.horizontal,
        showSeeAll: true,
      ),

      // Fitness Model - 使用写真主题第1组数据（健身模特）
      CategoryModel(
        id: 'fitness_model_preview',
        title: 'Fitness Model',
        emoji: '🏋️',
        imageUrls: [
          'assets/images/photoshoot/fitness_model/preview_1.jpg',
          'assets/images/photoshoot/fitness_model/preview_2.jpg',
          'assets/images/photoshoot/fitness_model/preview_3.jpg',
          'assets/images/photoshoot/fitness_model/preview_4.jpg',
          'assets/images/photoshoot/fitness_model/preview_5.jpg',
          'assets/images/photoshoot/fitness_model/preview_6.jpg',
        ],
        type: CategoryType.horizontal,
        showSeeAll: true,
      ),

      // Beach Lifestyle - 使用写真主题第2组数据（海滩生活）
      CategoryModel(
        id: 'beach_lifestyle_preview',
        title: 'Beach Lifestyle',
        emoji: '🌊',
        imageUrls: [
          'assets/images/photoshoot/beach_lifestyle/preview_1.jpg',
          'assets/images/photoshoot/beach_lifestyle/preview_2.jpg',
          'assets/images/photoshoot/beach_lifestyle/preview_3.jpg',
          'assets/images/photoshoot/beach_lifestyle/preview_4.jpg',
          'assets/images/photoshoot/beach_lifestyle/preview_5.jpg',
          'assets/images/photoshoot/beach_lifestyle/preview_6.jpg',
        ],
        type: CategoryType.horizontal,
        showSeeAll: true,
      ),

      // Urban Fashion - 使用写真主题第3组数据（都市时尚）
      CategoryModel(
        id: 'urban_fashion_preview',
        title: 'Urban Fashion',
        emoji: '🏙️',
        imageUrls: [
          'assets/images/photoshoot/urban_fashion/preview_1.jpg',
          'assets/images/photoshoot/urban_fashion/preview_2.jpg',
          'assets/images/photoshoot/urban_fashion/preview_3.jpg',
          'assets/images/photoshoot/urban_fashion/preview_4.jpg',
          'assets/images/photoshoot/urban_fashion/preview_5.jpg',
          'assets/images/photoshoot/urban_fashion/preview_6.jpg',
        ],
        type: CategoryType.horizontal,
        showSeeAll: true,
      ),
    ];
  }
}

enum CategoryType {
  horizontal, // 横向滚动展示
  grid, // 网格展示
}
