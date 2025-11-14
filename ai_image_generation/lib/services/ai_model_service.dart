import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

/// 万能AI大模型调用服务
/// 支持多图片输入，返回AI处理后的图片
class AIModelService {
  static const String _baseUrl =
      'https://api.xianfeiglobal.com'; // TODO: 填写您的baseUrl
  // 'https://api.llmone.net';
  static const String _apiKey =
      // 'sk-HkXDf42oyNw7Vg1RONR2PIKGHsE6ovyiTlDIKuUpw5uMSuVI'; // TODO: 填写您的apiKey
      'sk-qaCC5kdfVU3PJOHoArPU8U5Zh88U3g6inDAq04D7j8nGElId';
  // 'sk-eb7665c25ae84440abffaebbee0f4dc0';
  static const String _modelName =
      'gemini-2.5-flash-image-preview'; // TODO: 填写模型名称，如 gpt-4-vision-preview

  /// 处理图片的通用方法
  ///
  /// [imagePaths] 输入图片路径列表（支持多张图片）
  /// [prompt] 提示词
  /// [customBaseUrl] 自定义baseUrl（可选，覆盖默认配置）
  /// [customApiKey] 自定义apiKey（可选，覆盖默认配置）
  /// [customModel] 自定义模型名称（可选，覆盖默认配置）
  ///
  /// 返回处理后的图片文件路径，失败返回null
  static Future<String?> processImages({
    required List<String> imagePaths,
    required String prompt,
    String? customBaseUrl,
    String? customApiKey,
    String? customModel,
  }) async {
    try {
      // 验证输入参数
      if (imagePaths.isEmpty || prompt.trim().isEmpty) {
        debugPrint('❌ AIModelService: 输入参数无效');
        return null;
      }

      final baseUrl = customBaseUrl ?? _baseUrl;
      final apiKey = customApiKey ?? _apiKey;
      final model = customModel ?? _modelName;

      if (baseUrl.isEmpty || apiKey.isEmpty || model.isEmpty) {
        debugPrint('❌ AIModelService: API配置未完成，请检查baseUrl、apiKey和模型名称');
        return null;
      }

      debugPrint('🚀 AIModelService: 开始处理 ${imagePaths.length} 张图片');

      // 1. 验证图片文件
      final List<String> validImagePaths = [];
      for (String imagePath in imagePaths) {
        final file = File(imagePath);
        if (await file.exists()) {
          validImagePaths.add(imagePath);
        } else {
          debugPrint('⚠️ AIModelService: 图片文件不存在: $imagePath');
        }
      }

      if (validImagePaths.isEmpty) {
        debugPrint('❌ AIModelService: 没有有效的图片文件');
        return null;
      }

      // 2. 构造multipart/form-data请求
      final endpoint = '$baseUrl/v1/images/edits';
      debugPrint('🔍 AIModelService: 使用端点: $endpoint');

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/v1/images/edits'),
      );

      // 设置请求头
      request.headers['Authorization'] = 'Bearer $apiKey';

      // 添加基本参数
      final finalPrompt = _buildSystemPrompt(prompt);
      debugPrint('🔍 AIModelService: 最终提示词长度: ${finalPrompt.length}');
      debugPrint(
        '🔍 AIModelService: 最终提示词前100字符: ${finalPrompt.substring(0, finalPrompt.length > 100 ? 100 : finalPrompt.length)}',
      );

      // 使用带系统要求的完整提示词
      request.fields['prompt'] = finalPrompt; // 使用包含系统要求的提示词
      request.fields['model'] = model;
      request.fields['response_format'] = 'b64_json'; // 返回base64格式
      request.fields['size'] = '1024x1824'; // 9:16比例 (1024 * 1.78 ≈ 1824)
      request.fields['n'] = '1'; // 生成1张图片

      debugPrint('🔍 AIModelService: 请求参数: ${request.fields}');

      // 3. 添加多张图片文件
      for (int i = 0; i < validImagePaths.length; i++) {
        final imagePath = validImagePaths[i];
        final fileName = path.basename(imagePath);

        debugPrint('🔍 AIModelService: 添加第${i + 1}张图片: $fileName');

        // 根据文档，多图片应该使用 image[] 数组格式
        const fieldName = 'image[]'; // 所有图片都使用相同的字段名

        debugPrint('🔍 AIModelService: 使用字段名: $fieldName');

        request.files.add(
          await http.MultipartFile.fromPath(
            fieldName,
            imagePath,
            filename: fileName,
          ),
        );
      }

      debugPrint('📤 AIModelService: 发送API请求到 $baseUrl/v1/images/edits');

      // 4. 发送请求（添加300秒超时，适合复杂AI图片处理）
      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 300),
        onTimeout: () {
          debugPrint('❌ AIModelService: 请求超时（300秒）');
          throw Exception('AI图片处理超时，请检查网络连接后重试');
        },
      );
      final response = await http.Response.fromStream(streamedResponse);

      debugPrint('📥 AIModelService: 收到响应 ${response.statusCode}');

      if (response.statusCode == 200) {
        // 4. 解析响应并保存图片
        return await _handleResponse(response.body);
      } else {
        debugPrint(
          '❌ AIModelService: API请求失败 ${response.statusCode}: ${response.body}',
        );
        return null;
      }
    } catch (e) {
      debugPrint('❌ AIModelService: 处理异常: $e');
      return null;
    }
  }

  // 构建包含系统要求的完整提示词
  static String _buildSystemPrompt(String userPrompt) {
    const String systemRequirements = '''
【系统要求】
- 输出图片比例必须为9:16竖屏格式，适合手机屏幕展示
- 图片质量要求高清，细节丰富
- 保持人物面部特征清晰自然
- 色彩和谐，光线自然

【用户需求】
''';

    return systemRequirements + userPrompt;
  }

  // 处理API响应
  static Future<String?> _handleResponse(String responseBody) async {
    try {
      debugPrint('🔍 AIModelService: 原始响应内容: $responseBody');
      final responseJson = jsonDecode(responseBody);
      debugPrint('🔍 AIModelService: 解析后的JSON: $responseJson');

      // 解析OpenAI images API响应格式
      final data = responseJson['data'] as List?;
      if (data == null || data.isEmpty) {
        debugPrint('❌ AIModelService: 响应中没有data数组');
        debugPrint('🔍 AIModelService: 完整响应结构: ${responseJson.keys}');
        return null;
      }

      final firstImage = data[0] as Map<String, dynamic>;
      debugPrint('🔍 AIModelService: 第一个图片对象的键: ${firstImage.keys}');
      String? imageBase64;

      // 根据response_format获取图片数据
      if (firstImage.containsKey('b64_json')) {
        // base64格式
        imageBase64 = firstImage['b64_json'];
        debugPrint('✅ AIModelService: 找到b64_json格式数据');
      } else if (firstImage.containsKey('url')) {
        // URL格式 - 需要下载图片
        final imageUrl = firstImage['url'] as String;
        debugPrint('📥 AIModelService: 下载图片 $imageUrl');
        return await _downloadImageFromUrl(imageUrl);
      } else if (firstImage.containsKey('revised_prompt')) {
        // 从revised_prompt中提取图片URL
        final revisedPrompt = firstImage['revised_prompt'] as String;
        debugPrint('🔍 AIModelService: 在revised_prompt中查找图片URL');

        // 使用正则表达式提取URL
        final urlPattern = RegExp(
          r'https://[^\s\)]+\.(jpg|jpeg|png|gif|webp)',
          caseSensitive: false,
        );
        final match = urlPattern.firstMatch(revisedPrompt);

        if (match != null) {
          final imageUrl = match.group(0)!;
          debugPrint('✅ AIModelService: 找到图片URL: $imageUrl');
          return await _downloadImageFromUrl(imageUrl);
        } else {
          debugPrint('❌ AIModelService: 在revised_prompt中未找到图片URL');
          debugPrint(
            '🔍 AIModelService: revised_prompt内容: ${revisedPrompt.substring(0, 200)}...',
          );
          return null;
        }
      } else {
        debugPrint('❌ AIModelService: 响应格式不支持');
        debugPrint('🔍 AIModelService: 可用字段: ${firstImage.keys}');
        return null;
      }

      if (imageBase64 == null || imageBase64.isEmpty) {
        debugPrint('❌ AIModelService: 响应中没有找到图片数据');
        return null;
      }

      // 保存base64图片到本地文件
      return await _saveBase64Image(imageBase64);
    } catch (e) {
      debugPrint('❌ AIModelService: 响应解析失败: $e');
      return null;
    }
  }

  /// 从URL下载图片并保存到本地
  static Future<String?> _downloadImageFromUrl(String imageUrl) async {
    try {
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode == 200) {
        // 获取应用文档目录
        final directory = await getApplicationDocumentsDirectory();
        final fileName =
            'ai_processed_${DateTime.now().millisecondsSinceEpoch}.png';
        final filePath = '${directory.path}/$fileName';

        // 写入文件
        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);

        debugPrint('✅ AIModelService: 图片已保存到 $filePath');
        return filePath;
      } else {
        debugPrint('❌ AIModelService: 图片下载失败 ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ AIModelService: 图片下载异常: $e');
      return null;
    }
  }

  /// 保存base64图片到本地文件
  static Future<String?> _saveBase64Image(String base64String) async {
    try {
      // 清理base64字符串（移除可能的前缀）
      final cleanBase64 = base64String.replaceAll(
        RegExp(r'^data:image/[^;]+;base64,'),
        '',
      );

      final bytes = base64Decode(cleanBase64);

      // 获取应用文档目录
      final directory = await getApplicationDocumentsDirectory();
      final fileName =
          'ai_processed_${DateTime.now().millisecondsSinceEpoch}.png';
      final filePath = '${directory.path}/$fileName';

      // 写入文件
      final file = File(filePath);
      await file.writeAsBytes(bytes);

      debugPrint('✅ AIModelService: 图片已保存到 $filePath');
      return filePath;
    } catch (e) {
      debugPrint('❌ AIModelService: 保存图片失败: $e');
      return null;
    }
  }

  /// 便捷方法：处理单张图片
  static Future<String?> processSingleImage({
    required String imagePath,
    required String prompt,
    String? customBaseUrl,
    String? customApiKey,
    String? customModel,
  }) async {
    return processImages(
      imagePaths: [imagePath],
      prompt: prompt,
      customBaseUrl: customBaseUrl,
      customApiKey: customApiKey,
      customModel: customModel,
    );
  }

  /// 检查服务配置是否完整
  static bool isConfigured({
    String? customBaseUrl,
    String? customApiKey,
    String? customModel,
  }) {
    final baseUrl = customBaseUrl ?? _baseUrl;
    final apiKey = customApiKey ?? _apiKey;
    final model = customModel ?? _modelName;

    return baseUrl.isNotEmpty && apiKey.isNotEmpty && model.isNotEmpty;
  }

  /// 测试API连接
  static Future<bool> testConnection() async {
    try {
      debugPrint('🧪 测试API连接...');
      debugPrint('🔗 BaseURL: $_baseUrl');
      debugPrint('🔑 API Key: ${_apiKey.substring(0, 10)}...');
      debugPrint('🤖 Model: $_modelName');

      final response = await http
          .get(
            Uri.parse('$_baseUrl/v1/models'),
            headers: {'Authorization': 'Bearer $_apiKey'},
          )
          .timeout(const Duration(seconds: 10));

      debugPrint('📡 API响应状态: ${response.statusCode}');
      debugPrint(
        '📡 API响应内容: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}',
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('❌ API连接测试失败: $e');
      return false;
    }
  }
}
