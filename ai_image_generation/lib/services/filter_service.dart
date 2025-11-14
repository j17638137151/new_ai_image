import 'package:flutter/foundation.dart';
import 'ai_model_service.dart';
import 'filter_prompt_service.dart';

/// 滤镜处理服务
/// 专门处理Art Toy分类的40种滤镜效果
class FilterService {
  // 私有构造函数，防止实例化
  FilterService._();

  /// 应用滤镜效果
  /// [imagePath] 图片路径
  /// [filterId] 滤镜ID
  /// [onProgressUpdate] 进度回调
  static Future<String?> applyFilter({
    required String imagePath,
    required String filterId,
    Function(String)? onProgressUpdate,
  }) async {
    try {
      debugPrint('🎨 FilterService: 开始应用滤镜 - $filterId');
      onProgressUpdate?.call('正在应用滤镜效果...');
      
      // 获取滤镜提示词
      final prompt = FilterPromptService.getFilterPrompt(filterId);
      
      // 调用AI处理
      final result = await AIModelService.processImages(
        imagePaths: [imagePath],
        prompt: prompt,
      );
      
      if (result != null) {
        debugPrint('✅ FilterService: 滤镜应用成功 - $filterId');
        onProgressUpdate?.call('滤镜应用完成');
      } else {
        debugPrint('❌ FilterService: 滤镜应用失败 - $filterId');
      }
      
      return result;
    } catch (e) {
      debugPrint('❌ FilterService: 滤镜处理异常 - $e');
      return null;
    }
  }

  /// 预览滤镜效果（低质量快速处理）
  /// [imagePath] 图片路径
  /// [filterId] 滤镜ID
  /// [onProgressUpdate] 进度回调
  static Future<String?> previewFilter({
    required String imagePath,
    required String filterId,
    Function(String)? onProgressUpdate,
  }) async {
    try {
      debugPrint('👀 FilterService: 开始预览滤镜 - $filterId');
      onProgressUpdate?.call('正在生成预览...');
      
      // 获取预览版提示词
      final prompt = FilterPromptService.getFilterPreviewPrompt(filterId);
      
      // 调用AI处理
      final result = await AIModelService.processImages(
        imagePaths: [imagePath],
        prompt: prompt,
      );
      
      if (result != null) {
        debugPrint('✅ FilterService: 滤镜预览成功 - $filterId');
        onProgressUpdate?.call('预览生成完成');
      } else {
        debugPrint('❌ FilterService: 滤镜预览失败 - $filterId');
      }
      
      return result;
    } catch (e) {
      debugPrint('❌ FilterService: 滤镜预览异常 - $e');
      return null;
    }
  }

  /// 获取滤镜分类列表
  static List<String> getFilterCategories() {
    return ['artistic', 'body', 'effects', 'cartoon', 'texture'];
  }

  /// 根据分类获取滤镜列表
  static List<String> getFiltersByCategory(String category) {
    switch (category) {
      case 'artistic':
        return ['art_toy', 'oil_painting', 'watercolor', 'sketch', 'pop_art', 'abstract_art', 'vintage_film', 'neon_glow', 'graffiti', 'digital_art'];
      case 'body':
        return ['muscles', 'face_retouch', 'body_sculpt', 'skin_smooth', 'hair_enhance', 'eye_bright', 'smile_perfect', 'posture_fix'];
      case 'effects':
        return ['3d_photos', 'flash', 'glow', 'sparkle', 'rainbow', 'holographic', 'crystal', 'metal_shine'];
      case 'cartoon':
        return ['fairy_toon', 'anime_style', 'disney_style', 'pixar_3d', 'chibi', 'comic_book', 'superhero', 'cute_animal'];
      case 'texture':
        return ['clay', 'marble', 'wood', 'fabric', 'ice_crystal', 'fire_effect'];
      default:
        return [];
    }
  }

  /// 获取滤镜中文名称
  static String getFilterDisplayName(String filterId) {
    const displayNames = {
      // 🎭 艺术风格类
      'art_toy': '3D玩具',
      'oil_painting': '油画',
      'watercolor': '水彩画',
      'sketch': '素描',
      'pop_art': '波普艺术',
      'abstract_art': '抽象艺术',
      'vintage_film': '复古胶片',
      'neon_glow': '霓虹发光',
      'graffiti': '涂鸦',
      'digital_art': '数字艺术',
      
      // 🦸 人物增强类
      'muscles': '肌肉增强',
      'face_retouch': '面部美颜',
      'body_sculpt': '身材雕塑',
      'skin_smooth': '肌肤光滑',
      'hair_enhance': '头发增强',
      'eye_bright': '眼部明亮',
      'smile_perfect': '完美笑容',
      'posture_fix': '姿态矫正',
      
      // 🌈 视觉效果类
      '3d_photos': '3D立体',
      'flash': '闪光特效',
      'glow': '柔和发光',
      'sparkle': '闪闪发光',
      'rainbow': '彩虹色彩',
      'holographic': '全息效果',
      'crystal': '水晶质感',
      'metal_shine': '金属光泽',
      
      // 🎪 卡通动漫类
      'fairy_toon': '仙女卡通',
      'anime_style': '动漫风格',
      'disney_style': '迪士尼',
      'pixar_3d': '皮克斯3D',
      'chibi': 'Q版可爱',
      'comic_book': '漫画书',
      'superhero': '超级英雄',
      'cute_animal': '萌宠',
      
      // 🌟 材质纹理类
      'clay': '粘土',
      'marble': '大理石',
      'wood': '木质',
      'fabric': '织物',
      'ice_crystal': '冰晶',
      'fire_effect': '火焰',
    };
    
    return displayNames[filterId] ?? filterId;
  }

  /// 获取分类中文名称
  static String getCategoryDisplayName(String category) {
    const categoryNames = {
      'artistic': '🎭 艺术风格',
      'body': '🦸 人物增强', 
      'effects': '🌈 视觉效果',
      'cartoon': '🎪 卡通动漫',
      'texture': '🌟 材质纹理',
    };
    
    return categoryNames[category] ?? category;
  }
}
