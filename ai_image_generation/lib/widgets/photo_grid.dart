import 'package:flutter/material.dart';

class PhotoGrid extends StatelessWidget {
  final List<String> imageUrls;
  final int crossAxisCount;
  final double spacing;
  final bool showQRCode;
  final Function(int)? onItemTap;

  const PhotoGrid({
    super.key,
    required this.imageUrls,
    this.crossAxisCount = 2,
    this.spacing = 12.0,
    this.showQRCode = false,
    this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: spacing,
          mainAxisSpacing: spacing,
          childAspectRatio: 1.0, // 正方形比例
        ),
        itemCount: imageUrls.isEmpty ? 6 : imageUrls.length, // 如果没有数据显示6个占位符
        itemBuilder: (context, index) {
          return _buildGridItem(context, index);
        },
      ),
    );
  }

  Widget _buildGridItem(BuildContext context, int index) {
    return GestureDetector(
      onTap: () => onItemTap?.call(index),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF2F2F2F),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          children: [
            // 主要内容区域
            _buildItemContent(index),
            
            // 特殊内容覆盖层 (如二维码)
            if (showQRCode && index == 0) _buildQRCodeOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildItemContent(int index) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF404040),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(
        Icons.photo,
        color: Colors.white54,
        size: 30,
      ),
    );
  }

  Widget _buildQRCodeOverlay() {
    return Center(
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(
          Icons.qr_code,
          color: Colors.black,
        ),
      ),
    );
  }
}
