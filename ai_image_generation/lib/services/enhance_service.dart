import 'package:flutter/foundation.dart';
// import 'gemini_service.dart';
import 'ai_model_service.dart';
import 'prompt_service.dart';

/// 图片增强服务
/// 专门处理第二分类Enhance功能和ImageEnhancePage的工具
class EnhanceService {
  // 私有构造函数，防止实例化
  EnhanceService._();

  /// 基础图片增强（第二分类主功能）
  /// [imagePath] 图片路径
  /// [onProgressUpdate] 进度回调
  static Future<String?> basicEnhance({
    required String imagePath,
    Function(String)? onProgressUpdate,
  }) async {
    try {
      debugPrint('🎨 EnhanceService: 开始基础图片增强');
      onProgressUpdate?.call('正在AI智能增强中...');
      
      // 获取基础增强提示词
      final prompt = PromptService.getPromptByToolId('basic_enhance');
      
      // 调用OpenAI格式AI处理
      final result = await AIModelService.processImages(
        imagePaths: [imagePath],
        prompt: prompt,
      );
      
      if (result != null) {
        debugPrint('✅ EnhanceService: 基础增强成功');
        onProgressUpdate?.call('增强完成');
      } else {
        debugPrint('❌ EnhanceService: 基础增强失败');
      }
      
      return result;
    } catch (e) {
      debugPrint('❌ EnhanceService: 增强异常 - $e');
      return null;
    }
  }

  /// ImageEnhancePage底部工具处理
  /// [imagePath] 图片路径
  /// [toolId] 工具ID: 'background_blur', 'colors', 'background_enhancer', 'face_retouch', 'face_enhancer'
  /// [onProgressUpdate] 进度回调
  static Future<String?> processWithTool({
    required String imagePath,
    required String toolId,
    Function(String)? onProgressUpdate,
  }) async {
    try {
      debugPrint('🔧 EnhanceService: 开始工具处理 - $toolId');
      onProgressUpdate?.call('正在AI处理中...');
      
      // 获取对应工具的提示词
      final prompt = PromptService.getPromptByToolId(toolId);
      
      // 调用OpenAI格式AI处理
      final result = await AIModelService.processImages(
        imagePaths: [imagePath],
        prompt: prompt,
      );
      
      if (result != null) {
        debugPrint('✅ EnhanceService: 工具处理成功 - $toolId');
        onProgressUpdate?.call('处理完成');
      } else {
        debugPrint('❌ EnhanceService: 工具处理失败 - $toolId');
      }
      
      return result;
    } catch (e) {
      debugPrint('❌ EnhanceService: 工具处理异常 - $e');
      return null;
    }
  }

  /// 使用自定义提示词处理图片
  /// [imagePath] 图片路径
  /// [prompt] 自定义提示词
  /// [onProgressUpdate] 进度回调
  static Future<String?> processWithCustomPrompt({
    required String imagePath,
    required String prompt,
    Function(String)? onProgressUpdate,
  }) async {
    try {
      debugPrint('🎯 EnhanceService: 开始自定义提示词处理');
      onProgressUpdate?.call('正在AI处理中...');
      
      // 调用AI处理
      final result = await AIModelService.processImages(
        imagePaths: [imagePath],
        prompt: prompt,
      );
      
      if (result != null) {
        debugPrint('✅ EnhanceService: 自定义处理成功');
        onProgressUpdate?.call('处理完成');
      } else {
        debugPrint('❌ EnhanceService: 自定义处理失败');
      }
      
      return result;
    } catch (e) {
      debugPrint('❌ EnhanceService: 自定义处理异常 - $e');
      return null;
    }
  }
}
