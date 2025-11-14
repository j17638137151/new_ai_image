import 'package:flutter/material.dart';

class FaceDetectionDialog extends StatelessWidget {
  final String type; // '多人脸' 或 '无人脸'
  final VoidCallback? onSelectPhoto; // 选择照片回调

  const FaceDetectionDialog({
    super.key,
    required this.type,
    this.onSelectPhoto,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 插图区域
            Container(
              width: 120,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // 背景装饰
                  Positioned(
                    top: 10,
                    left: 20,
                    child: Container(
                      width: 30,
                      height: 25,
                      decoration: BoxDecoration(
                        color: Colors.orange.shade200,
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 15,
                    right: 15,
                    child: Container(
                      width: 25,
                      height: 20,
                      decoration: BoxDecoration(
                        color: Colors.orange.shade300,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  
                  // 主要图标内容
                  if (type == '多人脸') ...[
                    // 多人脸：两张照片重叠
                    Positioned(
                      left: 25,
                      child: Container(
                        width: 35,
                        height: 25,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: Icon(
                          Icons.person,
                          size: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                    Positioned(
                      right: 25,
                      child: Container(
                        width: 35,
                        height: 25,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: Icon(
                          Icons.person,
                          size: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ] else ...[
                    // 无人脸：放大镜和问号
                    Container(
                      width: 35,
                      height: 25,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Icon(
                        Icons.help_outline,
                        size: 16,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Positioned(
                      bottom: 5,
                      right: 20,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade600,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.search,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // 标题
            Text(
              _getTitle(),
              style: const TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 8),
            
            // 副标题
            Text(
              _getSubtitle(),
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 24),
            
            // 按钮
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(); // 先关闭弹窗
                  onSelectPhoto?.call(); // 然后调用回调函数重新选择照片
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  '选择照片',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getTitle() {
    switch (type) {
      case '多人脸':
        return '糟糕！人脸太多了。';
      case '无人脸':
        return '呜呼！我们需要面孔。';
      default:
        return '检测结果';
    }
  }

  String _getSubtitle() {
    switch (type) {
      case '多人脸':
        return '准确挑选面孔，每张照片一张。';
      case '无人脸':
        return '准确挑选面孔，每张照片一张。';
      default:
        return '请重新选择照片';
    }
  }
}
