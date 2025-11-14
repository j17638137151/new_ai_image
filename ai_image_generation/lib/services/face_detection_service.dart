import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_ml_kit/google_ml_kit.dart';

class FaceDetectionService {
  late final FaceDetector _faceDetector;

  FaceDetectionService() {
    _faceDetector = GoogleMlKit.vision.faceDetector(
      FaceDetectorOptions(
        enableClassification: false, // 关闭分类以提高性能
        enableLandmarks: false,      // 关闭特征点以提高性能  
        enableContours: false,       // 关闭轮廓以提高性能
        enableTracking: false,       // 关闭跟踪以提高性能
        minFaceSize: 0.1,           // 降低最小人脸尺寸要求
        performanceMode: FaceDetectorMode.fast, // 使用快速模式
      ),
    );
  }

  /// 检测图片中的人脸数量
  /// 返回检测到的人脸数量
  Future<int> detectFaces(File imageFile) async {
    try {
      debugPrint('开始检测图片: ${imageFile.path}');
      final inputImage = InputImage.fromFile(imageFile);
      final List<Face> faces = await _faceDetector.processImage(inputImage);

      debugPrint('检测到人脸数量: ${faces.length}');
      
      // 打印更详细的人脸信息
      for (int i = 0; i < faces.length; i++) {
        final face = faces[i];
        debugPrint('人脸 $i: 置信度=${face.headEulerAngleY}, 边界=${face.boundingBox}');
      }

      return faces.length;
    } catch (e) {
      debugPrint('人脸检测失败: $e');
      // 如果检测失败，返回1表示假设有一张人脸（避免阻塞用户流程）
      return 1;
    }
  }

  /// 释放资源
  void dispose() {
    _faceDetector.close();
  }
}
