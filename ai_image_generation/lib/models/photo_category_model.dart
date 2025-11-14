import 'package:flutter/material.dart';

class PhotoCategory {
  final String id;
  final String title;
  final String icon;
  final int photoCount;
  final IconData trendIcon;
  final List<String> photos;
  final String subtitle;

  PhotoCategory({
    required this.id,
    required this.title,
    required this.icon,
    required this.photoCount,
    required this.trendIcon,
    required this.photos,
    this.subtitle = '',
  });
}

// 预设照片数据
class PhotoPreset {
  final String id;
  final String imageUrl;
  final String title;
  final String description;

  PhotoPreset({
    required this.id,
    required this.imageUrl,
    required this.title,
    required this.description,
  });
}
