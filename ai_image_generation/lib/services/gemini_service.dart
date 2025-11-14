import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;

/// Gemini AI调用服务
/// 专门用于调用Google Gemini API进行图片处理
class GeminiService {
  // Gemini API配置
  static const String _baseUrl =
      'https://api.xianfeiglobal.com'; // TODO: 填写您的baseUrl
  // 'https://api.llmone.net';
  static const String _apiKey =
      // 'sk-HkXDf42oyNw7Vg1RONR2PIKGHsE6ovyiTlDIKuUpw5uMSuVI'; // TODO: 填写您的apiKey
      'sk-qaCC5kdfVU3PJOHoArPU8U5Zh88U3g6inDAq04D7j8nGElId';
  // 'sk-eb7665c25ae84440abffaebbee0f4dc0';
  static const String _modelName =
      'gemini-2.5-flash-image-preview'; // TODO: 填写模型名称，如 gpt-4-vision-preview

  /// 使用Gemini处理图片
  /// [imagePaths] 输入图片路径列表
  /// [prompt] 处理提示词
  /// [onProgressUpdate] 进度更新回调
  ///
  /// 返回处理后的图片文件路径，失败返回null
  static Future<String?> processImages({
    required List<String> imagePaths,
    required String prompt,
    Function(String)? onProgressUpdate,
  }) async {
    try {
      // 验证输入参数
      if (imagePaths.isEmpty || prompt.trim().isEmpty) {
        debugPrint('❌ GeminiService: 输入参数无效');
        return null;
      }

      if (_apiKey == 'YOUR_GEMINI_API_KEY' || _apiKey.isEmpty) {
        debugPrint('❌ GeminiService: 请先配置Gemini API Key');
        return null;
      }

      debugPrint('🚀 GeminiService: 开始处理 ${imagePaths.length} 张图片');
      onProgressUpdate?.call('正在准备图片...');

      // 1. 验证图片文件
      final List<String> validImagePaths = [];
      for (String imagePath in imagePaths) {
        final file = File(imagePath);
        if (await file.exists()) {
          validImagePaths.add(imagePath);
        } else {
          debugPrint('⚠️ GeminiService: 图片文件不存在: $imagePath');
        }
      }

      if (validImagePaths.isEmpty) {
        debugPrint('❌ GeminiService: 没有有效的图片文件');
        return null;
      }

      onProgressUpdate?.call('正在上传到AI服务器...');

      // 2. 构造multipart/form-data请求（与AIModelService相同格式）
      final endpoint = '$_baseUrl/v1/images/edits';
      debugPrint('🔍 GeminiService: 使用端点: $endpoint');

      final request = http.MultipartRequest('POST', Uri.parse(endpoint));

      // 设置请求头
      request.headers['Authorization'] = 'Bearer $_apiKey';

      // 添加基本参数
      request.fields['prompt'] = prompt;
      request.fields['model'] = _modelName;
      request.fields['response_format'] = 'b64_json';
      request.fields['size'] = '1024x1824';
      request.fields['n'] = '1';

      debugPrint('🔍 GeminiService: 请求参数: ${request.fields}');

      // 3. 添加图片文件
      for (int i = 0; i < validImagePaths.length; i++) {
        final imagePath = validImagePaths[i];
        final fileName = path.basename(imagePath);

        debugPrint('🔍 GeminiService: 添加第${i + 1}张图片: $fileName');

        const fieldName = 'image[]';
        request.files.add(
          await http.MultipartFile.fromPath(fieldName, imagePath),
        );
      }

      debugPrint('📤 GeminiService: 发送API请求到 $endpoint');
      onProgressUpdate?.call('正在AI智能处理中...');

      // 4. 发送请求
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      debugPrint('📥 GeminiService: 收到响应 ${response.statusCode}');

      onProgressUpdate?.call('正在处理AI响应...');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        debugPrint('✅ GeminiService: API调用成功');

        // 4. 解析响应并保存图片（与AIModelService相同逻辑）
        if (responseData['data'] != null && responseData['data'].isNotEmpty) {
          final imageData = responseData['data'][0];

          if (imageData['b64_json'] != null) {
            onProgressUpdate?.call('正在保存处理结果...');

            // 解码base64图片
            final base64String = imageData['b64_json'] as String;
            final bytes = base64Decode(base64String);

            // 保存到文件
            final fileName =
                'gemini_processed_${DateTime.now().millisecondsSinceEpoch}.png';
            final directory = Directory.systemTemp;
            final filePath = '${directory.path}/$fileName';

            final file = File(filePath);
            await file.writeAsBytes(bytes);

            debugPrint('✅ GeminiService: 图片已保存到 $filePath');
            return filePath;
          }
        }

        debugPrint('⚠️ GeminiService: 响应格式异常');
        debugPrint(
          '🔍 GeminiService: 响应内容: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}',
        );
        return null;
      } else {
        final errorData = jsonDecode(response.body);
        debugPrint('❌ GeminiService: API调用失败: ${response.statusCode}');
        debugPrint('❌ GeminiService: 错误详情: $errorData');

        if (response.statusCode == 400) {
          onProgressUpdate?.call('请求参数错误');
        } else if (response.statusCode == 401) {
          onProgressUpdate?.call('API Key验证失败');
        } else if (response.statusCode == 429) {
          onProgressUpdate?.call('请求频率超限，请稍后重试');
        } else if (response.statusCode >= 500) {
          onProgressUpdate?.call('服务器错误，请稍后重试');
        } else {
          onProgressUpdate?.call('处理失败，请重试');
        }

        return null;
      }
    } catch (e) {
      debugPrint('❌ GeminiService: 处理异常: $e');
      onProgressUpdate?.call('网络错误，请检查网络连接');
      return null;
    }
  }

  /// 单张图片处理的便捷方法
  static Future<String?> processSingleImage({
    required String imagePath,
    required String prompt,
    Function(String)? onProgressUpdate,
  }) async {
    return processImages(
      imagePaths: [imagePath],
      prompt: prompt,
      onProgressUpdate: onProgressUpdate,
    );
  }

  /// 检查Gemini服务配置
  static bool isConfigured() {
    return _apiKey.isNotEmpty && _apiKey != 'YOUR_GEMINI_API_KEY';
  }

  /// 获取支持的图片格式
  static List<String> getSupportedFormats() {
    return ['.jpg', '.jpeg', '.png', '.gif', '.webp', '.bmp'];
  }

  /// 验证图片文件格式
  static bool isSupportedImageFormat(String filePath) {
    final extension = path.extension(filePath).toLowerCase();
    return getSupportedFormats().contains(extension);
  }

  /// 图片分析专用方法（仅获取分析结果，不生成新图片）
  static Future<String?> analyzeImage({
    required String imagePath,
    required String analysisPrompt,
    Function(String)? onProgressUpdate,
  }) async {
    try {
      debugPrint('🔍 GeminiService: 开始图片分析');

      final result = await processImages(
        imagePaths: [imagePath],
        prompt: analysisPrompt,
        onProgressUpdate: onProgressUpdate,
      );

      // 这里可以返回分析文本而不是图片路径
      // 根据实际需求调整返回值类型
      return result;
    } catch (e) {
      debugPrint('❌ GeminiService: 分析失败: $e');
      return null;
    }
  }

  /// 构建图片增强专用的提示词
  static String buildImageEnhancePrompt(String userPrompt) {
    return '''
作为AI图片分析专家，请分析这张图片并提供增强建议：

用户要求：$userPrompt

请提供详细的分析和建议，包括：
1. 图片当前质量评估
2. 可改进的方面
3. 具体的增强建议
4. 预期的改进效果

请用中文回答，内容要专业且易懂。
''';
  }
}
