enum MessageType {
  text,
  voice,
  imageResult,
}

enum MessageSender {
  user,
  ai,
}

class ChatMessage {
  final String id;
  final MessageType type;
  final MessageSender sender;
  final String content;
  final DateTime timestamp;
  final String? voiceDuration; // 语音消息时长，如 "00:03"
  final String? originalImagePath; // AI结果消息的原图路径
  final String? processedImagePath; // AI结果消息的处理后图片路径
  final bool isProcessing; // AI是否正在处理中

  ChatMessage({
    required this.id,
    required this.type,
    required this.sender,
    required this.content,
    required this.timestamp,
    this.voiceDuration,
    this.originalImagePath,
    this.processedImagePath,
    this.isProcessing = false,
  });

  // 创建文字消息
  factory ChatMessage.text({
    required String content,
    required MessageSender sender,
  }) {
    return ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: MessageType.text,
      sender: sender,
      content: content,
      timestamp: DateTime.now(),
    );
  }

  // 创建语音消息
  factory ChatMessage.voice({
    required String content,
    required String duration,
    required MessageSender sender,
  }) {
    return ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: MessageType.voice,
      sender: sender,
      content: content,
      timestamp: DateTime.now(),
      voiceDuration: duration,
    );
  }

  // 创建AI图片结果消息
  factory ChatMessage.imageResult({
    required String originalImagePath,
    required String processedImagePath,
    bool isProcessing = false,
  }) {
    return ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: MessageType.imageResult,
      sender: MessageSender.ai,
      content: '',
      timestamp: DateTime.now(),
      originalImagePath: originalImagePath,
      processedImagePath: processedImagePath,
      isProcessing: isProcessing,
    );
  }

  // 复制并更新处理状态
  ChatMessage copyWith({
    bool? isProcessing,
    String? processedImagePath,
  }) {
    return ChatMessage(
      id: id,
      type: type,
      sender: sender,
      content: content,
      timestamp: timestamp,
      voiceDuration: voiceDuration,
      originalImagePath: originalImagePath,
      processedImagePath: processedImagePath ?? this.processedImagePath,
      isProcessing: isProcessing ?? this.isProcessing,
    );
  }
}
