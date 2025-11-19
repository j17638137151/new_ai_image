import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

import 'auth_api_service.dart';
import 'auth_state.dart';

class UploadUrlResult {
  final String uploadUrl;
  final String fileUrl;
  final String objectKey;
  final String? contentType;

  const UploadUrlResult({
    required this.uploadUrl,
    required this.fileUrl,
    required this.objectKey,
    this.contentType,
  });
}

class GenerationHistoryItem {
  final String id;
  final String userId;
  final String type;
  final String imageUrl;
  final String? prompt;
  final String? effectId;
  final DateTime createdAt;

  const GenerationHistoryItem({
    required this.id,
    required this.userId,
    required this.type,
    required this.imageUrl,
    required this.createdAt,
    this.prompt,
    this.effectId,
  });

  factory GenerationHistoryItem.fromJson(Map<String, dynamic> json) {
    return GenerationHistoryItem(
      id: json['id'] as String,
      userId: json['userId'] as String,
      type: json['type'] as String,
      imageUrl: json['imageUrl'] as String,
      prompt: json['prompt'] as String?,
      effectId: json['effectId'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

class GenerationHistoryPageResult {
  final List<GenerationHistoryItem> items;
  final int page;
  final int pageSize;
  final bool hasMore;

  const GenerationHistoryPageResult({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.hasMore,
  });
}

class GenerationHistoryApiService {
  GenerationHistoryApiService._();

  static String get _baseUrl => AuthApiService.baseUrl;

  static String? _getToken() {
    return AuthState.instance.currentUser?.token;
  }

  /// 请求后端生成预签名上传URL
  static Future<UploadUrlResult> getUploadUrl(String filePath) async {
    final token = _getToken();
    if (token == null) {
      throw StateError('用户未登录，无法请求上传URL');
    }

    final fileName = p.basename(filePath);
    final contentType = _guessContentType(fileName);

    final uri = Uri.parse('$_baseUrl/storage/upload-url');

    debugPrint(
      '[History] 请求上传URL: filePath=$filePath, fileName=$fileName, contentType=$contentType',
    );
    debugPrint('[History] 当前用于请求上传URL的 token=$token');

    try {
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'fileName': fileName, 'contentType': contentType}),
      );

      debugPrint(
        '[History] 上传URL响应: status=${response.statusCode}, body=${response.body}',
      );

      if (response.statusCode != 200) {
        throw Exception('获取上传URL失败: ${response.statusCode} ${response.body}');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final result = UploadUrlResult(
        uploadUrl: data['uploadUrl'] as String,
        fileUrl: data['fileUrl'] as String,
        objectKey: data['objectKey'] as String,
        contentType: (data['contentType'] as String?),
      );

      debugPrint('[History] 获取上传URL成功: objectKey=${result.objectKey}');
      return result;
    } catch (e, stack) {
      debugPrint('[History] getUploadUrl 异常: $e');
      debugPrint(stack.toString());
      rethrow;
    }
  }

  /// 将本地文件上传到 MinIO（通过预签名URL）
  static Future<void> uploadFile(
    String uploadUrl,
    String filePath, {
    String? contentType,
  }) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('本地文件不存在: $filePath');
    }

    final bytes = await file.readAsBytes();

    debugPrint('[History] 开始上传到 MinIO: url=$uploadUrl, filePath=$filePath');

    final response = await http.put(
      Uri.parse(uploadUrl),
      headers: {if (contentType != null) 'Content-Type': contentType},
      body: bytes,
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        '上传文件到 MinIO 失败: ${response.statusCode} ${response.body}',
      );
    }

    debugPrint('[History] 上传到 MinIO 成功');
  }

  /// 写入一条生成历史
  static Future<void> createHistory({
    required String type,
    required String imageUrl,
    String? prompt,
    String? effectId,
  }) async {
    final token = _getToken();
    if (token == null) {
      throw StateError('用户未登录，无法写入生成历史');
    }

    final uri = Uri.parse('$_baseUrl/generation/history');

    debugPrint('[History] 准备写入生成历史: type=$type, imageUrl=$imageUrl');

    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'type': type,
        'imageUrl': imageUrl,
        if (prompt != null) 'prompt': prompt,
        if (effectId != null) 'effectId': effectId,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('写入生成历史失败: ${response.statusCode} ${response.body}');
    }

    debugPrint('[History] 写入生成历史成功');
  }

  /// 通过后端代上传的方式，将本地文件上传到 MinIO
  /// 后端接口：POST /storage/upload-direct (multipart/form-data)
  static Future<UploadUrlResult> uploadFileDirect(
    String filePath, {
    String? contentType,
  }) async {
    final token = _getToken();
    if (token == null) {
      throw StateError('用户未登录，无法上传文件');
    }

    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('本地文件不存在: $filePath');
    }

    final uri = Uri.parse('$_baseUrl/storage/upload-direct');
    final fileName = p.basename(filePath);
    final effectiveContentType = contentType ?? _guessContentType(fileName);

    debugPrint(
      '[History] 开始后端代上传: url=$uri, filePath=$filePath, fileName=$fileName, contentType=$effectiveContentType',
    );

    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $token'
      ..fields['contentType'] = effectiveContentType;

    request.files.add(
      await http.MultipartFile.fromPath('file', filePath, filename: fileName),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    debugPrint(
      '[History] 后端代上传响应: status=${response.statusCode}, body=${response.body}',
    );

    if (response.statusCode != 200) {
      throw Exception('后端代上传失败: ${response.statusCode} ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final fileUrl = data['fileUrl'] as String;
    final objectKey = data['objectKey'] as String;

    return UploadUrlResult(
      uploadUrl: '',
      fileUrl: fileUrl,
      objectKey: objectKey,
      contentType: effectiveContentType,
    );
  }

  /// 一步完成：本地文件 -> MinIO -> 写历史
  static Future<void> syncGenerationResult({
    required String localFilePath,
    required String type,
    String? prompt,
    String? effectId,
  }) async {
    debugPrint('[History] 开始同步生成结果: path=$localFilePath, type=$type');

    try {
      // 使用后端代上传，避免客户端直连 MinIO 的各种网络和签名问题
      final uploadInfo = await uploadFileDirect(
        localFilePath,
        contentType: _guessContentType(localFilePath),
      );

      await createHistory(
        type: type,
        imageUrl: uploadInfo.fileUrl,
        prompt: prompt,
        effectId: effectId,
      );

      debugPrint('[History] 同步生成结果完成');
    } catch (e, stack) {
      debugPrint('[History] syncGenerationResult 异常: $e');
      debugPrint(stack.toString());
      rethrow;
    }
  }

  /// 分页获取当前用户的生成历史
  static Future<GenerationHistoryPageResult> listHistory({
    int page = 1,
    int pageSize = 20,
  }) async {
    final token = _getToken();
    if (token == null) {
      throw StateError('用户未登录，无法获取生成历史');
    }

    final uri = Uri.parse('$_baseUrl/generation/history').replace(
      queryParameters: {
        'page': page.toString(),
        'pageSize': pageSize.toString(),
      },
    );

    final response = await http.get(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode != 200) {
      throw Exception('获取生成历史失败: ${response.statusCode} ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final items = (data['items'] as List<dynamic>)
        .map((e) => GenerationHistoryItem.fromJson(e))
        .toList();

    return GenerationHistoryPageResult(
      items: items,
      page: (data['page'] as num).toInt(),
      pageSize: (data['pageSize'] as num).toInt(),
      hasMore: data['hasMore'] as bool,
    );
  }

  static String _guessContentType(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) {
      return 'image/jpeg';
    }
    if (lower.endsWith('.png')) {
      return 'image/png';
    }
    if (lower.endsWith('.webp')) {
      return 'image/webp';
    }
    return 'application/octet-stream';
  }
}
