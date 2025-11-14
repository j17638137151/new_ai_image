import 'package:flutter/material.dart';
import 'dart:io';

class PhotoHorizontalGrid extends StatelessWidget {
  final List<String?> imageUrls; // 支持null值作为占位符
  final double itemWidth;
  final double itemHeight;
  final double spacing;
  final bool showQRCode;
  final Function(int)? onItemTap;

  const PhotoHorizontalGrid({
    super.key,
    required this.imageUrls,
    this.itemWidth = 120,
    this.itemHeight = 120,
    this.spacing = 12.0,
    this.showQRCode = false,
    this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    // 确保至少显示20个项目，这样始终有两行
    final int totalItems = imageUrls.length < 20 ? 20 : imageUrls.length;

    // 每行固定显示一半，确保两行都有内容
    final int itemsPerRow = totalItems ~/ 2; // 整数除法
    final int remainingItems = totalItems - itemsPerRow;

    final List<int> firstRowItems = List.generate(
      itemsPerRow,
      (index) => index,
    );
    final List<int> secondRowItems = List.generate(
      remainingItems,
      (index) => index + itemsPerRow,
    );

    return SizedBox(
      height: (itemHeight * 2) + spacing, // 两行的高度 + 中间间距
      child: Column(
        children: [
          // 第一行
          _buildHorizontalRow(firstRowItems, 0),

          SizedBox(height: spacing),

          // 第二行
          _buildHorizontalRow(secondRowItems, itemsPerRow),
        ],
      ),
    );
  }

  Widget _buildHorizontalRow(List<int> rowItems, int startIndex) {
    return Expanded(
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(left: 20),
        itemCount: rowItems.length,
        itemBuilder: (context, index) {
          final actualIndex = startIndex + index;
          return _buildPhotoItem(context, actualIndex);
        },
      ),
    );
  }

  Widget _buildPhotoItem(BuildContext context, int index) {
    return GestureDetector(
      onTap: () => onItemTap?.call(index),
      child: Container(
        width: itemWidth,
        height: itemHeight,
        margin: EdgeInsets.only(right: spacing),
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
    // 如果有图片URL且不为null，显示图片；否则显示占位符
    if (imageUrls.isNotEmpty && index < imageUrls.length) {
      final imageUrl = imageUrls[index];

      // 如果URL为null，显示占位符
      if (imageUrl == null) {
        return _buildPlaceholder();
      }

      // 判断是否为本地文件
      final isLocalFile =
          imageUrl.startsWith('/') || imageUrl.startsWith('file://');

      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: isLocalFile
            ? Image.file(
                File(imageUrl),
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                errorBuilder: (context, error, stackTrace) {
                  return _buildPlaceholder();
                },
              )
            : Image.network(
                imageUrl,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return _buildPlaceholder();
                },
                errorBuilder: (context, error, stackTrace) {
                  return _buildPlaceholder();
                },
              ),
      );
    }

    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF404040),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(Icons.photo, color: Colors.white54, size: 30),
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
        child: const Icon(Icons.qr_code, color: Colors.black, size: 30),
      ),
    );
  }
}
