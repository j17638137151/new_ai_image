/// 写真主题数据模型
class PhotoshootTheme {
  final String id;
  final String title;
  final String emoji;
  final String description;
  final String subtitle;
  final List<String> previewImages;
  final String aiPrompt;
  final int photoCount;

  const PhotoshootTheme({
    required this.id,
    required this.title,
    required this.emoji,
    required this.description,
    required this.subtitle,
    required this.previewImages,
    required this.aiPrompt,
    required this.photoCount,
  });
}
