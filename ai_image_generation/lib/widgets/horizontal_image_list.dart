import 'package:flutter/material.dart';

class HorizontalImageList extends StatelessWidget {
  final List<String> imageUrls;
  final bool showAvatars;
  final String placeholderIcon;
  final Function(int)? onItemTap;

  const HorizontalImageList({
    super.key,
    required this.imageUrls,
    this.showAvatars = false,
    this.placeholderIcon = 'image',
    this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 160,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(left: 20),
        itemCount: imageUrls.isEmpty ? 5 : imageUrls.length, // 如果没有数据显示5个占位符
        itemBuilder: (context, index) {
          return _buildImageItem(context, index);
        },
      ),
    );
  }

  Widget _buildImageItem(BuildContext context, int index) {
    return GestureDetector(
      onTap: () => onItemTap?.call(index),
      child: Container(
        width: 120,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF2F2F2F),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          children: [
            // 主图片区域
            _buildMainImageArea(index),
            
            // 底部小头像 (如果需要显示)
            if (showAvatars) _buildBottomAvatars(),
          ],
        ),
      ),
    );
  }

  Widget _buildMainImageArea(int index) {
    // 如果有真实图片URL，显示图片；否则显示占位符图标
    if (imageUrls.isNotEmpty && index < imageUrls.length) {
      final imageUrl = imageUrls[index];
      
      return Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: _buildImageWidget(imageUrl),
        ),
      );
    } else {
      // 显示占位符图标
      return Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFF404040),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          _getIconData(),
          color: Colors.white54,
          size: 40,
        ),
      );
    }
  }

  // 智能判断图片类型并使用对应的Image组件
  Widget _buildImageWidget(String imageUrl) {
    // 如果是assets路径，使用Image.asset
    if (imageUrl.startsWith('assets/')) {
      return Image.asset(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          debugPrint('加载assets图片失败: $imageUrl, 错误: $error');
          return Container(
            color: const Color(0xFF404040),
            child: Icon(
              _getIconData(),
              color: Colors.white54,
              size: 48,
            ),
          );
        },
      );
    }
    // 如果是网络URL，使用Image.network
    else if (imageUrl.startsWith('http')) {
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            color: const Color(0xFF404040),
            child: Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
                strokeWidth: 2,
                color: Colors.white54,
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: const Color(0xFF404040),
            child: Icon(
              _getIconData(),
              color: Colors.white54,
              size: 48,
            ),
          );
        },
      );
    }
    // 其他情况显示占位符
    else {
      return Container(
        color: const Color(0xFF404040),
        child: Icon(
          _getIconData(),
          color: Colors.white54,
          size: 48,
        ),
      );
    }
  }

  Widget _buildBottomAvatars() {
    return Positioned(
      bottom: 12,
      right: 8, // 确保整个Stack都在边界内
      child: SizedBox(
        width: 45, // 两个头像重叠后的总宽度：24 + 24 - 3 = 45px
        height: 24, // 头像高度
        child: Stack(
          children: [
            // 第一个头像（底层，左侧）
            Positioned(
              left: 0,
              child: CircleAvatar(
                radius: 12,
                backgroundColor: Colors.blue.withAlpha(230),
                child: const Icon(Icons.person, size: 12, color: Colors.white),
              ),
            ),
            // 第二个头像（重叠在上层，右侧，重叠3px）
            Positioned(
              left: 21, // 24 - 3 = 21px，实现3px重叠
              child: CircleAvatar(
                radius: 12,
                backgroundColor: Colors.pink.withAlpha(230),
                child: const Icon(Icons.person, size: 12, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconData() {
    switch (placeholderIcon) {
      case 'image':
        return Icons.image;
      case 'palette':
        return Icons.palette;
      case 'photo':
        return Icons.photo;
      case 'fitness':
        return Icons.fitness_center;
      case 'person':
        return Icons.person_outline;
      case 'landscape':
        return Icons.landscape;
      default:
        return Icons.image;
    }
  }
}
