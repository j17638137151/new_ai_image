import 'package:flutter/foundation.dart';
import '../data/photoshoot_themes.dart';
import 'ai_model_service.dart';

/// 写真AI服务 - 负责批量处理写真照片
class PhotoshootAIService {
  /// 生成写真套组
  ///
  /// [themeId] 写真主题ID
  /// [userPhotos] 用户上传的照片路径列表
  /// [onProgress] 进度回调 (当前处理索引, 总数, 当前处理结果)
  ///
  /// 返回处理结果列表，null表示处理失败
  static Future<List<String?>> generatePhotoshoot({
    required String themeId,
    required List<String> userPhotos,
    Function(int current, int total, String? currentResult)? onProgress,
  }) async {
    debugPrint('🎬 开始生成写真套组，共${userPhotos.length}张照片');
    debugPrint('📋 主题ID: $themeId');
    debugPrint('📸 照片数量: ${userPhotos.length}');

    if (userPhotos.isEmpty) {
      debugPrint('❌ PhotoshootAIService: 用户照片列表为空');
      return [];
    }

    if (!PhotoshootThemes.themeExists(themeId)) {
      debugPrint('❌ PhotoshootAIService: 主题不存在: $themeId');
      return List.filled(userPhotos.length, null);
    }

    final aiPrompt = PhotoshootThemes.getAIPrompt(themeId);
    if (aiPrompt.isEmpty) {
      debugPrint('❌ PhotoshootAIService: 主题提示词为空: $themeId');
      return List.filled(userPhotos.length, null);
    }

    debugPrint(
      '📝 使用AI提示词: ${aiPrompt.substring(0, aiPrompt.length > 100 ? 100 : aiPrompt.length)}...',
    );

    final results = <String?>[];
    int successCount = 0;

    for (int i = 0; i < userPhotos.length; i++) {
      final photoPath = userPhotos[i];
      debugPrint('🔄 处理第${i + 1}/${userPhotos.length}张照片: $photoPath');

      try {
        final result = await AIModelService.processSingleImage(
          imagePath: photoPath,
          prompt: aiPrompt,
        );

        results.add(result);

        if (result != null) {
          successCount++;
          debugPrint('✅ 第${i + 1}张照片处理成功');
        } else {
          debugPrint('❌ 第${i + 1}张照片处理失败');
        }

        // 调用进度回调
        onProgress?.call(i + 1, userPhotos.length, result);

        // 处理间隔，避免请求过于频繁
        if (i < userPhotos.length - 1) {
          debugPrint('⏳ 等待1秒后处理下一张照片...');
          await Future.delayed(const Duration(milliseconds: 1000));
        }
      } catch (e) {
        debugPrint('❌ 第${i + 1}张照片处理异常: $e');
        results.add(null);
        onProgress?.call(i + 1, userPhotos.length, null);
      }
    }

    debugPrint('🎉 写真套组生成完成!');
    debugPrint('📊 处理统计: $successCount/${userPhotos.length}张成功');
    debugPrint(
      '📈 成功率: ${(successCount / userPhotos.length * 100).toStringAsFixed(1)}%',
    );

    return results;
  }
}
