class FilterModel {
  final String id;
  final String name;
  final String thumbnailUrl;
  final bool isPro;
  final String category;

  const FilterModel({
    required this.id,
    required this.name,
    required this.thumbnailUrl,
    this.isPro = false,
    required this.category,
  });

  // 获取所有40种滤镜
  static List<FilterModel> getAllFilters() {
    return [
      // ==================== 🎭 艺术风格类 (10个) ====================
      const FilterModel(
        id: 'art_toy',
        name: 'Art Toy',
        thumbnailUrl:
            'assets/images/filters/art_toy_thumbnail.jpg', // 🖼️ 预留图片位置
        category: 'artistic',
      ),
      const FilterModel(
        id: 'oil_painting',
        name: 'Oil Painting',
        thumbnailUrl:
            'assets/images/filters/oil_painting_thumbnail.jpg', // 🖼️ 预留图片位置
        category: 'artistic',
      ),
      const FilterModel(
        id: 'watercolor',
        name: 'Watercolor',
        thumbnailUrl:
            'assets/images/filters/watercolor_thumbnail.jpg', // 🖼️ 预留图片位置
        category: 'artistic',
      ),
      const FilterModel(
        id: 'sketch',
        name: 'Sketch',
        thumbnailUrl:
            'assets/images/filters/sketch_thumbnail.jpg', // 🖼️ 预留图片位置
        category: 'artistic',
      ),
      const FilterModel(
        id: 'pop_art',
        name: 'Pop Art',
        thumbnailUrl:
            'assets/images/filters/pop_art_thumbnail.jpg', // 🖼️ 预留图片位置
        category: 'artistic',
      ),
      const FilterModel(
        id: 'abstract_art',
        name: 'Abstract Art',
        thumbnailUrl:
            'assets/images/filters/abstract_art_thumbnail.jpg', // 🖼️ 预留图片位置
        category: 'artistic',
      ),
      const FilterModel(
        id: 'vintage_film',
        name: 'Vintage Film',
        thumbnailUrl:
            'assets/images/filters/vintage_film_thumbnail.jpg', // 🖼️ 预留图片位置
        category: 'artistic',
      ),
      const FilterModel(
        id: 'neon_glow',
        name: 'Neon Glow',
        thumbnailUrl:
            'assets/images/filters/neon_glow_thumbnail.jpg', // 🖼️ 预留图片位置
        category: 'artistic',
      ),
      const FilterModel(
        id: 'graffiti',
        name: 'Graffiti',
        thumbnailUrl:
            'assets/images/filters/graffiti_thumbnail.jpg', // 🖼️ 预留图片位置
        category: 'artistic',
      ),
      const FilterModel(
        id: 'digital_art',
        name: 'Digital Art',
        thumbnailUrl:
            'assets/images/filters/digital_art_thumbnail.jpg', // 🖼️ 预留图片位置
        category: 'artistic',
      ),

      // ==================== 🦸 人物增强类 (8个) ====================
      const FilterModel(
        id: 'muscles',
        name: 'Muscles',
        thumbnailUrl:
            'assets/images/filters/muscles_thumbnail.jpg', // 🖼️ 预留图片位置
        category: 'body',
      ),
      const FilterModel(
        id: 'face_retouch',
        name: 'Face Retouch',
        thumbnailUrl:
            'assets/images/filters/face_retouch_thumbnail.jpg', // 🖼️ 预留图片位置
        category: 'body',
      ),
      const FilterModel(
        id: 'body_sculpt',
        name: 'Body Sculpt',
        thumbnailUrl:
            'assets/images/filters/body_sculpt_thumbnail.jpg', // 🖼️ 预留图片位置
        category: 'body',
      ),
      const FilterModel(
        id: 'skin_smooth',
        name: 'Skin Smooth',
        thumbnailUrl:
            'assets/images/filters/skin_smooth_thumbnail.jpg', // 🖼️ 预留图片位置
        category: 'body',
      ),
      const FilterModel(
        id: 'hair_enhance',
        name: 'Hair Enhance',
        thumbnailUrl:
            'assets/images/filters/hair_enhance_thumbnail.jpg', // 🖼️ 预留图片位置
        category: 'body',
      ),
      const FilterModel(
        id: 'eye_bright',
        name: 'Eye Bright',
        thumbnailUrl:
            'assets/images/filters/eye_bright_thumbnail.jpg', // 🖼️ 预留图片位置
        category: 'body',
      ),
      const FilterModel(
        id: 'smile_perfect',
        name: 'Smile Perfect',
        thumbnailUrl:
            'assets/images/filters/smile_perfect_thumbnail.jpg', // 🖼️ 预留图片位置
        category: 'body',
      ),
      const FilterModel(
        id: 'posture_fix',
        name: 'Posture Fix',
        thumbnailUrl:
            'assets/images/filters/posture_fix_thumbnail.jpg', // 🖼️ 预留图片位置
        category: 'body',
      ),

      // ==================== 🌈 视觉效果类 (8个) ====================
      const FilterModel(
        id: '3d_photos',
        name: '3D Photos',
        thumbnailUrl:
            'assets/images/filters/3d_photos_thumbnail.jpg', // 🖼️ 预留图片位置
        category: 'effects',
      ),
      const FilterModel(
        id: 'flash',
        name: 'Flash',
        thumbnailUrl: 'assets/images/filters/flash_thumbnail.jpg', // 🖼️ 预留图片位置
        category: 'effects',
      ),
      const FilterModel(
        id: 'glow',
        name: 'Glow',
        thumbnailUrl: 'assets/images/filters/glow_thumbnail.jpg', // 🖼️ 预留图片位置
        category: 'effects',
      ),
      const FilterModel(
        id: 'sparkle',
        name: 'Sparkle',
        thumbnailUrl:
            'assets/images/filters/sparkle_thumbnail.jpg', // 🖼️ 预留图片位置
        category: 'effects',
      ),
      const FilterModel(
        id: 'rainbow',
        name: 'Rainbow',
        thumbnailUrl:
            'assets/images/filters/rainbow_thumbnail.jpg', // 🖼️ 预留图片位置
        category: 'effects',
      ),
      const FilterModel(
        id: 'holographic',
        name: 'Holographic',
        thumbnailUrl:
            'assets/images/filters/holographic_thumbnail.jpg', // 🖼️ 预留图片位置
        category: 'effects',
      ),
      const FilterModel(
        id: 'crystal',
        name: 'Crystal',
        thumbnailUrl:
            'assets/images/filters/crystal_thumbnail.jpg', // 🖼️ 预留图片位置
        category: 'effects',
      ),
      const FilterModel(
        id: 'metal_shine',
        name: 'Metal Shine',
        thumbnailUrl:
            'assets/images/filters/metal_shine_thumbnail.jpg', // 🖼️ 预留图片位置
        category: 'effects',
      ),

      // ==================== 🎪 卡通动漫类 (8个) ====================
      const FilterModel(
        id: 'fairy_toon',
        name: 'Fairy Toon',
        thumbnailUrl:
            'assets/images/filters/fairy_toon_thumbnail.jpg', // 🖼️ 预留图片位置
        category: 'cartoon',
      ),
      const FilterModel(
        id: 'anime_style',
        name: 'Anime Style',
        thumbnailUrl:
            'assets/images/filters/anime_style_thumbnail.jpg', // 🖼️ 预留图片位置
        category: 'cartoon',
      ),
      const FilterModel(
        id: 'disney_style',
        name: 'Disney Style',
        thumbnailUrl:
            'assets/images/filters/disney_style_thumbnail.jpg', // 🖼️ 预留图片位置
        category: 'cartoon',
      ),
      const FilterModel(
        id: 'pixar_3d',
        name: 'Pixar 3D',
        thumbnailUrl:
            'assets/images/filters/pixar_3d_thumbnail.jpg', // 🖼️ 预留图片位置
        category: 'cartoon',
      ),
      const FilterModel(
        id: 'chibi',
        name: 'Chibi',
        thumbnailUrl: 'assets/images/filters/chibi_thumbnail.jpg', // 🖼️ 预留图片位置
        category: 'cartoon',
      ),
      const FilterModel(
        id: 'comic_book',
        name: 'Comic Book',
        thumbnailUrl:
            'assets/images/filters/comic_book_thumbnail.jpg', // 🖼️ 预留图片位置
        category: 'cartoon',
      ),
      const FilterModel(
        id: 'superhero',
        name: 'Superhero',
        thumbnailUrl:
            'assets/images/filters/superhero_thumbnail.jpg', // 🖼️ 预留图片位置
        category: 'cartoon',
      ),
      const FilterModel(
        id: 'cute_animal',
        name: 'Cute Animal',
        thumbnailUrl:
            'assets/images/filters/cute_animal_thumbnail.jpg', // 🖼️ 预留图片位置
        category: 'cartoon',
      ),

      // ==================== 🌟 材质纹理类 (6个) ====================
      const FilterModel(
        id: 'clay',
        name: 'Clay',
        thumbnailUrl: 'assets/images/filters/clay_thumbnail.jpg', // 🖼️ 预留图片位置
        category: 'texture',
      ),
      const FilterModel(
        id: 'marble',
        name: 'Marble',
        thumbnailUrl:
            'assets/images/filters/marble_thumbnail.jpg', // 🖼️ 预留图片位置
        category: 'texture',
      ),
      const FilterModel(
        id: 'wood',
        name: 'Wood',
        thumbnailUrl: 'assets/images/filters/wood_thumbnail.jpg', // 🖼️ 预留图片位置
        category: 'texture',
      ),
      const FilterModel(
        id: 'fabric',
        name: 'Fabric',
        thumbnailUrl:
            'assets/images/filters/fabric_thumbnail.jpg', // 🖼️ 预留图片位置
        category: 'texture',
      ),
      const FilterModel(
        id: 'ice_crystal',
        name: 'Ice Crystal',
        thumbnailUrl:
            'assets/images/filters/ice_crystal_thumbnail.jpg', // 🖼️ 预留图片位置
        category: 'texture',
      ),
      const FilterModel(
        id: 'fire_effect',
        name: 'Fire Effect',
        thumbnailUrl:
            'assets/images/filters/fire_effect_thumbnail.jpg', // 🖼️ 预留图片位置
        category: 'texture',
      ),
    ];
  }

  // 获取免费滤镜
  static List<FilterModel> getFreeFilters() {
    return getAllFilters().where((filter) => !filter.isPro).toList();
  }

  // 获取付费滤镜
  static List<FilterModel> getProFilters() {
    return getAllFilters().where((filter) => filter.isPro).toList();
  }

  // 根据分类获取滤镜
  static List<FilterModel> getFiltersByCategory(String category) {
    return getAllFilters()
        .where((filter) => filter.category == category)
        .toList();
  }
}
