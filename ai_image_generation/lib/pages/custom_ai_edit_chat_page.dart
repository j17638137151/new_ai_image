import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import '../services/ai_model_service.dart';

// 消息类型枚举
enum MessageType { text, voice, imageResult }

// 消息发送者枚举
enum MessageSender { user, ai }

// 聊天消息模型
class ChatMessage {
  final String content;
  final MessageType type;
  final MessageSender sender;
  final DateTime timestamp;
  final bool isProcessing;
  final String? audioPath; // 音频文件路径
  final String? originalImagePath; // 原始图片路径
  final String? processedImagePath; // 处理后图片路径

  ChatMessage({
    required this.content,
    required this.type,
    required this.sender,
    DateTime? timestamp,
    this.isProcessing = false,
    this.audioPath,
    this.originalImagePath,
    this.processedImagePath,
  }) : timestamp = timestamp ?? DateTime.now();

  // 工厂方法：创建文字消息
  factory ChatMessage.text({
    required String content,
    required MessageSender sender,
    DateTime? timestamp,
  }) {
    return ChatMessage(
      content: content,
      type: MessageType.text,
      sender: sender,
      timestamp: timestamp,
    );
  }

  // 工厂方法：创建语音消息
  factory ChatMessage.voice({
    required String content,
    required String audioPath,
    required MessageSender sender,
    DateTime? timestamp,
  }) {
    return ChatMessage(
      content: content,
      type: MessageType.voice,
      sender: sender,
      timestamp: timestamp,
      audioPath: audioPath,
    );
  }

  // 工厂方法：创建图片结果消息
  factory ChatMessage.imageResult({
    required String content,
    required MessageSender sender,
    required String originalImagePath,
    required String processedImagePath,
    bool isProcessing = false,
    DateTime? timestamp,
  }) {
    return ChatMessage(
      content: content,
      type: MessageType.imageResult,
      sender: sender,
      timestamp: timestamp,
      isProcessing: isProcessing,
      originalImagePath: originalImagePath,
      processedImagePath: processedImagePath,
    );
  }

  // copyWith方法
  ChatMessage copyWith({
    String? content,
    MessageType? type,
    MessageSender? sender,
    DateTime? timestamp,
    bool? isProcessing,
    String? audioPath,
    String? originalImagePath,
    String? processedImagePath,
  }) {
    return ChatMessage(
      content: content ?? this.content,
      type: type ?? this.type,
      sender: sender ?? this.sender,
      timestamp: timestamp ?? this.timestamp,
      isProcessing: isProcessing ?? this.isProcessing,
      audioPath: audioPath ?? this.audioPath,
      originalImagePath: originalImagePath ?? this.originalImagePath,
      processedImagePath: processedImagePath ?? this.processedImagePath,
    );
  }
}

class CustomAiEditChatPage extends StatefulWidget {
  final String userImagePath;

  const CustomAiEditChatPage({super.key, required this.userImagePath});

  @override
  State<CustomAiEditChatPage> createState() => _CustomAiEditChatPageState();
}

class _CustomAiEditChatPageState extends State<CustomAiEditChatPage>
    with TickerProviderStateMixin {
  // 聊天消息列表
  List<ChatMessage> _messages = [];

  // 输入控制器
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // 输入模式：true为文字，false为语音
  bool _isTextMode = true;

  // 语音相关状态
  bool _isRecording = false;
  int _recordingDuration = 0;
  Timer? _recordingTimer;
  double _currentVolumeScale = 1.0; // 当前音量对应的缩放值
  double _baselineVolume = double.infinity; // 背景噪音基线，使用最小值
  bool _hasBaseline = false; // 是否已建立基线
  List<double> _volumeSamples = []; // 音量样本缓存
  List<double> _recentScales = []; // 最近的缩放值，用于更平滑的过渡
  double _lastTargetScale = 1.0; // 上一次的目标缩放值
  double _velocityScale = 0.0; // 缩放变化速度
  int _lastUpdateTime = 0; // 上次更新时间
  List<double> _volumeHistory = []; // 音量历史记录
  double _volumeTrend = 0.0; // 音量变化趋势
  double _adaptiveSensitivity = 1.0; // 自适应灵敏度
  double _emotionalState = 0.0; // 情绪状态（基于音量模式）

  // 语音播放状态
  String? _playingMessageId;
  Timer? _playingTimer;

  // 录音实例
  FlutterSoundRecorder? _audioRecorder;
  FlutterSoundPlayer? _audioPlayer;
  String? _currentRecordingPath;
  StreamSubscription<RecordingDisposition>? _recorderSubscription;

  // 继续编辑状态管理
  String _baseImagePath = ''; // 当前编辑的基础图片路径
  bool _isEditingProcessedImage = false; // 是否正在编辑处理后的图片

  // 动画控制器（用于语音球体动画）
  late AnimationController _voiceAnimationController;
  late Animation<double> _voiceAnimation;

  @override
  void initState() {
    super.initState();
    _baseImagePath = widget.userImagePath; // 初始化为用户上传的原图
    _initializeAnimations();
    _initializeAudio();
  }

  // 计算音量方差（用于情绪状态分析）
  double _calculateVariance(List<double> values) {
    if (values.isEmpty) return 0.0;
    final mean = values.reduce((a, b) => a + b) / values.length;
    final variance =
        values.map((x) => math.pow(x - mean, 2)).reduce((a, b) => a + b) /
        values.length;
    return variance.toDouble();
  }

  // 使用系统音量播放 - 简单有效的方法
  Future<void> _setSpeakerphone() async {
    try {
      // 先停止任何正在播放的音频
      await _audioPlayer!.stopPlayer();
    } catch (e) {
      // 音频准备失败，静默处理
    }
  }

  // 初始化音频
  void _initializeAudio() async {
    try {
      _audioRecorder = FlutterSoundRecorder();
      _audioPlayer = FlutterSoundPlayer();

      // 初始化录音器和播放器
      await _audioRecorder!.openRecorder();
      await _audioPlayer!.openPlayer();
    } catch (e) {
      // 音频初始化失败，静默处理
    }
  }

  void _initializeAnimations() {
    // 语音球体动画控制器
    _voiceAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _voiceAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(
        parent: _voiceAnimationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _voiceAnimationController.dispose();
    _textController.dispose();
    _scrollController.dispose();
    _recordingTimer?.cancel();
    _playingTimer?.cancel();
    _audioRecorder?.closeRecorder();
    _audioPlayer?.closePlayer();
    super.dispose();
  }

  // 发送文字消息
  void _sendTextMessage() {
    if (_textController.text.trim().isEmpty) return;

    final message = ChatMessage.text(
      content: _textController.text.trim(),
      sender: MessageSender.user,
    );

    setState(() {
      _messages.add(message);
    });

    _textController.clear();
    _scrollToBottom();

    // 模拟AI处理
    _simulateAiProcessing(message.content);
  }

  // 切换输入模式
  void _toggleInputMode() {
    setState(() {
      _isTextMode = !_isTextMode;
    });
  }

  // 开始录制语音
  void _startRecording() async {
    // 先检查当前权限状态
    var currentStatus = await Permission.microphone.status;

    // 如果权限未授予，请求权限
    if (currentStatus != PermissionStatus.granted) {
      var requestStatus = await Permission.microphone.request();

      if (requestStatus != PermissionStatus.granted) {
        _showPermissionDialog(requestStatus);
        return;
      }
    }

    try {
      // 生成录音文件路径
      final directory = await getTemporaryDirectory();
      final fileName = 'recording_${DateTime.now().millisecondsSinceEpoch}.aac';
      _currentRecordingPath = '${directory.path}/$fileName';

      // 开始录音
      await _audioRecorder!.startRecorder(
        toFile: _currentRecordingPath!,
        codec: Codec.aacADTS,
      );

      setState(() {
        _isRecording = true;
        _recordingDuration = 0;
        _currentVolumeScale = 1.0; // 确保开始时球体正常大小
        _hasBaseline = false; // 重置基线检测
        _baselineVolume = double.infinity; // 重置为最大值，寻找最小值
        _volumeSamples.clear(); // 清空样本缓存
        _recentScales.clear(); // 清空平滑缓存
        _lastTargetScale = 1.0; // 重置目标缩放
        _velocityScale = 0.0; // 重置速度
        _lastUpdateTime = DateTime.now().millisecondsSinceEpoch;
        _volumeHistory.clear(); // 清空历史记录
        _volumeTrend = 0.0; // 重置趋势
        _adaptiveSensitivity = 1.0; // 重置灵敏度
        _emotionalState = 0.0; // 重置情绪状态
      });

      // 设置录音订阅频率，获取更频繁的音量数据
      await _audioRecorder!.setSubscriptionDuration(
        const Duration(milliseconds: 50),
      );

      // 监听录音进度和真实音量
      _recorderSubscription = _audioRecorder!.onProgress!.listen((e) {
        setState(() {
          _recordingDuration = e.duration.inSeconds;

          // 智能最小值基线检测算法
          final dbLevel = (e.decibels ?? 0.0).abs(); // 取绝对值确保为正数

          // 收集音量样本，持续更新最小值基线
          _volumeSamples.add(dbLevel);
          if (_volumeSamples.length > 100) {
            _volumeSamples.removeAt(0); // 保持最近100个样本
          }

          // 动态更新基线为最小值 + 小缓冲
          final currentMin = _volumeSamples.reduce((a, b) => a < b ? a : b);
          _baselineVolume = currentMin + 0.1; // 最小值 + 0.1 缓冲

          // 前1秒为基线稳定期 - 缩短等待时间
          if (!_hasBaseline && _recordingDuration < 1) {
            _currentVolumeScale = 1.0; // 稳定期保持正常大小
            return;
          } else if (!_hasBaseline) {
            _hasBaseline = true;
          }

          // 计算相对于智能基线的音量增益
          final volumeGain = (dbLevel - _baselineVolume).clamp(
            0.0,
            double.infinity,
          );

          // 🚀 超级精进算法 - AI级智能生物仿真 🚀
          final now = DateTime.now().millisecondsSinceEpoch;
          final deltaTime = (now - _lastUpdateTime).clamp(1, 200);
          _lastUpdateTime = now;

          // 📊 1. 智能音量分析与趋势预测
          _volumeHistory.add(volumeGain);
          if (_volumeHistory.length > 20) _volumeHistory.removeAt(0);

          // 计算音量变化趋势（斜率）
          if (_volumeHistory.length >= 3) {
            final recent = _volumeHistory.sublist(_volumeHistory.length - 3);
            _volumeTrend = (recent.last - recent.first) / recent.length;
          }

          // 🧠 2. 自适应灵敏度调整
          final avgVolume = _volumeHistory.isNotEmpty
              ? _volumeHistory.reduce((a, b) => a + b) / _volumeHistory.length
              : 0.0;
          _adaptiveSensitivity = (avgVolume < 10.0)
              ? 1.5
              : // 安静环境更敏感
                (avgVolume > 80.0)
              ? 0.7
              : 1.0; // 嘈杂环境减敏感

          // 💭 3. 情绪状态分析（基于音量模式）
          final volumeVariance = _volumeHistory.isNotEmpty
              ? _calculateVariance(_volumeHistory)
              : 0.0;
          _emotionalState = (volumeVariance > 50.0)
              ? 0.8
              : // 激动
                (volumeVariance > 20.0)
              ? 0.4
              : 0.1; // 平静

          // 🎯 4. 高级感知缩放
          final normalizedGain = (volumeGain / 120.0).clamp(0.0, 1.0);
          final perceptualBase = math.pow(normalizedGain, 0.6);
          final adaptiveScale = perceptualBase * _adaptiveSensitivity;
          var targetScale = 1.0 + (adaptiveScale * 0.4);

          // 🔮 5. 预测性平滑（根据趋势预判）
          final trendPrediction = _volumeTrend * 0.3; // 预测下一帧
          targetScale += trendPrediction * 0.05;

          // 🎭 6. 情绪驱动的复合波形
          final emotionalIntensity = _emotionalState;
          final nervousShake =
              math.sin(now / 150.0) * 0.004 * emotionalIntensity; // 紧张颤抖
          final calmBreath =
              math.sin(now / 1800.0) * 0.012 * (1 - emotionalIntensity); // 平静呼吸
          final heartPulse =
              math.sin(now / 900.0) *
              (0.010 + emotionalIntensity * 0.008); // 心跳

          targetScale += nervousShake + calmBreath + heartPulse;

          // 🔬 7. 高级物理仿真（变刚度弹簧）
          final adaptiveSpring = 0.06 + (_emotionalState * 0.04); // 情绪影响弹性
          final adaptiveDamping = 0.90 + (_emotionalState * 0.05); // 情绪影响阻尼

          // 多层次震荡系统
          final displacement = targetScale - _currentVolumeScale;
          final springForce = displacement * adaptiveSpring;

          // 添加二阶振荡（更复杂的物理特性）
          final secondOrderForce = -_velocityScale * 0.02; // 速度阻抗

          // 更新物理状态
          _velocityScale +=
              (springForce + secondOrderForce) * (deltaTime / 50.0);
          _velocityScale *= adaptiveDamping;
          _currentVolumeScale += _velocityScale * (deltaTime / 50.0);

          // 🛡️ 8. 智能边界管理
          final softLimit = 0.05 * math.sin(now / 2000.0); // 动态边界
          _currentVolumeScale = _currentVolumeScale.clamp(
            0.88 + softLimit,
            1.52 - softLimit,
          );

          _lastTargetScale = targetScale;
        });
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('录音启动失败: $e')));
    }
  }

  // 显示权限对话框
  void _showPermissionDialog(PermissionStatus status) {
    String message;
    String buttonText;
    VoidCallback? onPressed;

    switch (status) {
      case PermissionStatus.denied:
        message = '需要麦克风权限才能录制语音消息。请点击"设置"开启权限。';
        buttonText = '设置';
        onPressed = () {
          openAppSettings();
          Navigator.of(context).pop();
        };
        break;
      case PermissionStatus.permanentlyDenied:
        message = '麦克风权限已被永久拒绝。请到设置中手动开启权限。';
        buttonText = '去设置';
        onPressed = () {
          openAppSettings();
          Navigator.of(context).pop();
        };
        break;
      default:
        message = '无法获取麦克风权限，请重试。';
        buttonText = '重试';
        onPressed = () {
          Navigator.of(context).pop();
          _startRecording();
        };
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('需要麦克风权限'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          if (onPressed != null)
            TextButton(onPressed: onPressed, child: Text(buttonText)),
        ],
      ),
    );
  }

  // 播放语音消息
  void _playVoiceMessage(ChatMessage message) async {
    if (message.audioPath == null) return;

    final messageId = '${message.hashCode}';

    // 如果点击的是正在播放的消息，则暂停
    if (_playingMessageId == messageId) {
      await _audioPlayer?.stopPlayer();
      setState(() {
        _playingMessageId = null;
      });
      return;
    }

    // 如果正在播放其他语音，先停止
    if (_playingMessageId != null) {
      await _audioPlayer?.stopPlayer();
      setState(() {
        _playingMessageId = null;
      });
    }

    // 开始播放当前语音
    setState(() {
      _playingMessageId = messageId;
    });

    try {
      // 🔊 强制设置扬声器播放，提高音量
      await _setSpeakerphone();

      // 播放音频文件
      await _audioPlayer!.startPlayer(
        fromURI: message.audioPath!,
        whenFinished: () {
          setState(() {
            _playingMessageId = null;
          });
        },
      );
    } catch (e) {
      setState(() {
        _playingMessageId = null;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('播放语音失败')));
    }
  }

  // 停止录制语音
  void _stopRecording() async {
    _recorderSubscription?.cancel();
    _recorderSubscription = null;
    _voiceAnimationController.stop();
    _voiceAnimationController.reset();

    setState(() {
      _isRecording = false;
      _currentVolumeScale = 1.0; // 重置音量缩放
    });

    try {
      // 停止录音
      final path = await _audioRecorder?.stopRecorder();

      if (path != null && _currentRecordingPath != null) {
        // 创建语音消息
        final voiceMessage = ChatMessage.voice(
          content: '语音消息 ${_recordingDuration}s',
          audioPath: _currentRecordingPath!,
          sender: MessageSender.user,
        );

        setState(() {
          _messages.add(voiceMessage);
        });

        // 自动滚动到底部
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom();
        });

        // 模拟AI回复
        _simulateAiProcessing('语音消息');
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('录音保存失败')));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('录音失败，请重试')));
    }

    // 清空当前录音路径
    _currentRecordingPath = null;
  }

  // 真实AI处理
  Future<void> _simulateAiProcessing(String userInput) async {
    // 添加处理中的AI回复
    final processingMessage = ChatMessage.imageResult(
      content: '正在处理您的图片...',
      sender: MessageSender.ai,
      originalImagePath: widget.userImagePath,
      processedImagePath: widget.userImagePath, // 临时使用原图
      isProcessing: true,
    );

    setState(() {
      _messages.add(processingMessage);
    });

    _scrollToBottom();

    try {
      debugPrint('🚀 开始AI处理用户请求: $userInput');
      debugPrint('📸 原图路径: ${widget.userImagePath}');

      // 调用真实的AI服务，使用当前选择的基础图片
      final result = await AIModelService.processSingleImage(
        imagePath: _baseImagePath, // 使用当前选择的基础图片
        prompt: userInput,
      );

      // 更新消息状态
      final index = _messages.indexOf(processingMessage);
      if (index != -1 && mounted) {
        setState(() {
          if (result != null) {
            // AI处理成功
            debugPrint('✅ AI处理成功: $result');
            _messages[index] = processingMessage.copyWith(
              content: '已为您完成图片编辑',
              isProcessing: false,
              processedImagePath: result,
            );
          } else {
            // AI处理失败
            debugPrint('❌ AI处理失败');
            _messages[index] = processingMessage.copyWith(
              content: 'AI处理失败，可能是网络问题或服务暂时不可用。请检查网络连接后重试。',
              isProcessing: false,
              processedImagePath: widget.userImagePath, // 显示原图
            );
          }
        });
        _scrollToBottom();
      }
    } catch (e) {
      // 处理异常
      debugPrint('❌ AI处理异常: $e');
      final index = _messages.indexOf(processingMessage);
      if (index != -1 && mounted) {
        setState(() {
          _messages[index] = processingMessage.copyWith(
            content: 'AI处理异常: ${e.toString()}',
            isProcessing: false,
            processedImagePath: widget.userImagePath, // 显示原图
          );
        });
        _scrollToBottom();
      }
    }
  }

  // 重试最后一个请求
  void _retryLastRequest() {
    // 查找最后一个用户文字消息
    ChatMessage? lastUserTextMessage;
    for (int i = _messages.length - 1; i >= 0; i--) {
      if (_messages[i].sender == MessageSender.user &&
          _messages[i].type == MessageType.text) {
        lastUserTextMessage = _messages[i];
        break;
      }
    }

    if (lastUserTextMessage != null) {
      debugPrint('🔄 重试用户请求: ${lastUserTextMessage.content}');
      _simulateAiProcessing(lastUserTextMessage.content);
    }
  }

  // 选择图片进行继续编辑
  void _selectImageForEditing(String imagePath) {
    setState(() {
      _baseImagePath = imagePath;
      _isEditingProcessedImage = true;
    });

    debugPrint('📝 选择图片继续编辑: $imagePath');

    // 滚动到输入框
    _scrollToBottom();
  }

  // 重置到原图编辑模式
  void _resetToOriginalImage() {
    setState(() {
      _baseImagePath = widget.userImagePath;
      _isEditingProcessedImage = false;
    });
    debugPrint('🔄 重置到原图编辑模式');
  }

  // 下载图片功能
  Future<void> _downloadImage(String imagePath) async {
    try {
      debugPrint('📥 开始下载图片: $imagePath');

      final result = await ImageGallerySaver.saveFile(
        imagePath,
        name: 'ai_edit_${DateTime.now().millisecondsSinceEpoch}',
      );

      if (mounted) {
        if (result['isSuccess'] == true) {
          _showSuccessDialog();
        } else {
          _showErrorDialog('保存失败，请检查存储权限');
        }
      }
    } catch (e) {
      debugPrint('❌ 下载图片失败: $e');
      if (mounted) {
        _showErrorDialog('下载失败：${e.toString()}');
      }
    }
  }

  // 显示成功弹窗（参考AI滤镜结果页面）
  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 成功图标
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 36,
                ),
              ),
              const SizedBox(height: 16),

              // 成功文字
              const Text(
                '保存成功！',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),

              const Text(
                '图片已保存到相册',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 20),

              // 确定按钮
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    '确定',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    // 2秒后自动关闭弹窗
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        // 检查是否还有dialog可以关闭
        try {
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          }
        } catch (e) {
          // 如果弹窗已经被手动关闭，忽略错误
          debugPrint('自动关闭弹窗失败，可能已被手动关闭: $e');
        }
      }
    });
  }

  // 显示错误弹窗（参考AI滤镜结果页面）
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 错误图标
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 30,
                ),
              ),

              const SizedBox(height: 16),

              const Text(
                '下载失败',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    '确定',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 滚动到底部
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients && mounted) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: true, // 启用软键盘适配
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '自定义 AI 编辑',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: GestureDetector(
        onTap: () {
          // 点击空白区域收起键盘
          FocusScope.of(context).unfocus();
        },
        child: Column(
          children: [
            // 聊天消息区域 - 使用Expanded，内部用SingleChildScrollView处理滚动
            Expanded(
              child: Stack(
                children: [
                  // 聊天内容 - 使用SingleChildScrollView让内容可以被键盘推出屏幕
                  SingleChildScrollView(
                    controller: _scrollController,
                    child: Column(
                      children: [
                        // 顶部用户图片展示区域（只在没有消息时显示）
                        if (_messages.isEmpty) _buildUserImageHeader(),

                        // 描述区域（只在没有消息时显示）
                        if (_messages.isEmpty) _buildDescriptionArea(),

                        // 推荐提示词区域（只在没有消息时显示）
                        if (_messages.isEmpty) _buildSuggestionChips(),

                        // 消息列表区域
                        if (_messages.isNotEmpty)
                          ...List.generate(_messages.length, (index) {
                            return _buildMessageItem(_messages[index]);
                          }),

                        // 底部留白，确保最后一条消息不被输入框遮挡
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),

                  // 录制时的大球体覆盖层
                  if (_isRecording) _buildRecordingOverlay(),
                ],
              ),
            ),

            // 输入区域 - 固定在底部
            _buildInputArea(),
          ],
        ),
      ),
    );
  }

  // 顶部用户图片展示区域
  Widget _buildUserImageHeader() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      height: 250, // 增加图片高度
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.file(
          File(widget.userImagePath),
          fit: BoxFit.contain, // 改为完整显示图片
          width: double.infinity,
        ),
      ),
    );
  }

  // 描述区域
  Widget _buildDescriptionArea() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
      child: Column(
        children: [
          const SizedBox(height: 4), // 距离默认图增加2px
          const Text(
            '告诉我您想要改变的内容',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 15,
              height: 1.2,
            ), // 字体减小1px
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
        ],
      ),
    );
  }

  // 推荐提示词区域
  Widget _buildSuggestionChips() {
    final suggestions = ['换成海滩背景', '变成动漫风格', '添加夕阳效果', '去除背景'];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min, // 防止占用过多空间
        children: [
          const SizedBox(height: 8),
          Wrap(
            spacing: 8, // 水平间距
            runSpacing: 8, // 垂直间距
            alignment: WrapAlignment.center,
            children: suggestions.map((suggestion) {
              return _buildSuggestionChip(suggestion);
            }).toList(),
          ),
          const SizedBox(height: 12), // 与输入框的间距
        ],
      ),
    );
  }

  // 构建单个推荐提示词芯片
  Widget _buildSuggestionChip(String text) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _onSuggestionTap(text),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.grey[800],
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey[600]!, width: 1),
          ),
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  // 处理推荐提示词点击
  void _onSuggestionTap(String suggestion) {
    _textController.text = suggestion;
    _sendTextMessage();
  }

  // 构建消息项
  Widget _buildMessageItem(ChatMessage message) {
    final isUser = message.sender == MessageSender.user;

    return Container(
      margin: EdgeInsets.only(
        top: 8,
        bottom: 8,
        // 统一的左右边距，确保与AI图片对齐
        left: message.type == MessageType.imageResult
            ? MediaQuery.of(context).padding.left +
                  4 // AI图片消息：与安全区域对齐
            : isUser
            ? 60
            : 16, // 文字消息：用户消息左侧留更多空间，AI消息左侧适中
        right: MediaQuery.of(context).padding.right + 4, // 所有消息右侧都与AI图片对齐
      ),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            child: message.type == MessageType.imageResult
                ? _buildMessageContent(message) // AI图片消息不需要容器
                : Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isUser ? Colors.blue[600] : Colors.grey[800],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: _buildMessageContent(message),
                  ),
          ),
        ],
      ),
    );
  }

  // 构建消息内容
  Widget _buildMessageContent(ChatMessage message) {
    switch (message.type) {
      case MessageType.text:
        return Text(
          message.content,
          style: const TextStyle(color: Colors.white, fontSize: 16),
        );
      case MessageType.voice:
        bool isPlaying = _playingMessageId == '${message.hashCode}';
        return GestureDetector(
          onTap: () {
            // 播放语音消息
            _playVoiceMessage(message);
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isPlaying ? Icons.pause : Icons.play_arrow,
                color: isPlaying ? Colors.red : Colors.blue,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                isPlaying ? '正在播放...' : message.content,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
        );
      case MessageType.imageResult:
        return _buildImageResult(message);
    }
  }

  // 构建图片结果
  Widget _buildImageResult(ChatMessage message) {
    if (message.isProcessing) {
      return Container(
        height: 250,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey[700],
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.blue),
              SizedBox(height: 12),
              Text('正在处理中...', style: TextStyle(color: Colors.white70)),
            ],
          ),
        ),
      );
    }

    // 检查是否处理失败（处理后图片路径与原图相同表示失败）
    final isProcessingFailed =
        message.processedImagePath == message.originalImagePath &&
        message.content.contains('失败');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ComparisonImageWidget(
          originalImagePath: message.originalImagePath!,
          processedImagePath: message.processedImagePath!,
          onDownload: () {
            _downloadImage(message.processedImagePath!);
          },
          onEdit: () {
            _selectImageForEditing(message.processedImagePath!);
          },
        ),
        if (isProcessingFailed) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    message.content,
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _retryLastRequest(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[600],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                  ),
                  child: const Text('重试', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // 输入区域
  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        border: Border(top: BorderSide(color: Colors.grey[800]!)),
      ),
      child: SafeArea(
        child: IntrinsicHeight(
          // 重要：让Row根据内容高度自适应
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end, // 按钮对齐到底部
            children: [
              // 左侧：模式切换按钮
              IconButton(
                onPressed: _toggleInputMode,
                icon: Icon(
                  _isTextMode ? Icons.keyboard_voice : Icons.keyboard,
                  color: Colors.white,
                ),
              ),

              const SizedBox(width: 8),

              // 中间：输入区域 - 使用Flexible而不是Expanded
              Flexible(
                child: _isTextMode ? _buildTextInput() : _buildVoiceArea(),
              ),

              // 右侧：发送按钮（仅文字模式显示）
              if (_isTextMode) ...[
                const SizedBox(width: 12),
                IconButton(
                  onPressed: _sendTextMessage,
                  icon: Icon(Icons.send, color: Colors.blue[600]),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // 文字输入框
  Widget _buildTextInput() {
    return Column(
      mainAxisSize: MainAxisSize.min, // 重要：让Column只占用需要的空间
      children: [
        // 显示编辑状态指示器
        if (_isEditingProcessedImage) _buildEditingIndicator(),

        // 使用Flexible包装TextField以防止溢出
        Flexible(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxHeight: 120, // 限制输入框最大高度，约4-5行
            ),
            child: TextField(
              controller: _textController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: _isEditingProcessedImage
                    ? '基于处理后图片继续编辑...'
                    : '描述您想要的编辑效果...',
                hintStyle: const TextStyle(color: Colors.white54),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[800],
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              maxLines: null,
              minLines: 1,
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendTextMessage(),
            ),
          ),
        ),
      ],
    );
  }

  // 编辑状态指示器
  Widget _buildEditingIndicator() {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.edit, color: Colors.blue, size: 16),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              '正在基于处理后图片编辑',
              style: TextStyle(color: Colors.blue, fontSize: 12),
            ),
          ),
          GestureDetector(
            onTap: _resetToOriginalImage,
            child: Container(
              padding: const EdgeInsets.all(2),
              child: Icon(Icons.close, color: Colors.grey[400], size: 16),
            ),
          ),
        ],
      ),
    );
  }

  // 语音区域（替换输入框）
  Widget _buildVoiceArea() {
    if (_isRecording) {
      return _buildRecordingIndicator();
    }

    return GestureDetector(
      onTap: _startRecording,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: Colors.blue[600],
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Center(
          child: Text(
            '点击说话',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  // 录制指示器
  Widget _buildRecordingIndicator() {
    return GestureDetector(
      onTap: _stopRecording,
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red[600]!, width: 2),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 实时音量驱动的3D球体
            Transform.scale(
              scale: _currentVolumeScale, // 实时跟随音量变化
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.red[300]!,
                      Colors.red[600]!,
                      Colors.red[900]!,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withOpacity(0.6),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                    BoxShadow(
                      color: Colors.red[300]!.withOpacity(0.8),
                      blurRadius: 40,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.red[200]!.withOpacity(0.8),
                        Colors.red[800]!,
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '正在录制...',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${_recordingDuration}s',
                  style: TextStyle(
                    color: Colors.red[300],
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            const Text(
              '点击停止',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

// 前后对比图片组件
class _ComparisonImageWidget extends StatefulWidget {
  final String originalImagePath;
  final String processedImagePath;
  final VoidCallback onDownload;
  final VoidCallback onEdit; // 新增编辑回调

  const _ComparisonImageWidget({
    required this.originalImagePath,
    required this.processedImagePath,
    required this.onDownload,
    required this.onEdit, // 新增编辑回调
  });

  @override
  State<_ComparisonImageWidget> createState() => _ComparisonImageWidgetState();
}

class _ComparisonImageWidgetState extends State<_ComparisonImageWidget> {
  double _sliderPosition = 0.5; // 分割线位置 (0.0 - 1.0)

  @override
  Widget build(BuildContext context) {
    // 使用固定的图片高度，让SingleChildScrollView处理滚动
    const imageHeight = 300.0; // 固定高度，简单可靠

    return Container(
      width: double.infinity,
      height: imageHeight, // 固定高度，通过滚动适配键盘
      margin: const EdgeInsets.only(top: 8, bottom: 8), // 简化边距，由父容器统一管理左右边距
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            // 背景图片（处理后的效果 - 添加蓝色滤镜效果）
            Positioned.fill(
              child: Image.file(
                File(widget.processedImagePath),
                fit: BoxFit.cover,
                color: Colors.blue.withOpacity(0.3), // 蓝色滤镜效果，模拟AI处理
                colorBlendMode: BlendMode.overlay,
              ),
            ),

            // 前景图片（原图），使用ClipPath裁剪
            Positioned.fill(
              child: ClipPath(
                clipper: _SliderClipper(_sliderPosition),
                child: Image.file(
                  File(widget.originalImagePath),
                  fit: BoxFit.cover,
                  // 原图保持原样，无滤镜
                ),
              ),
            ),

            // 分割线和控制器
            Positioned.fill(
              child: GestureDetector(
                onPanUpdate: (details) {
                  setState(() {
                    final RenderBox box =
                        context.findRenderObject() as RenderBox;
                    final localPosition = details.localPosition;
                    _sliderPosition = (localPosition.dx / box.size.width).clamp(
                      0.0,
                      1.0,
                    );
                  });
                },
                child: CustomPaint(painter: _SliderPainter(_sliderPosition)),
              ),
            ),

            // 左侧标签
            Positioned(
              left: 16,
              top: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text(
                  '处理前',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),

            // 右侧标签
            Positioned(
              right: 16,
              top: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text(
                  '处理后',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),

            // 右下角按钮组
            Positioned(
              right: 16,
              bottom: 16,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 编辑按钮
                  GestureDetector(
                    onTap: widget.onEdit,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.edit,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),

                  const SizedBox(width: 8), // 按钮间距
                  // 下载按钮
                  GestureDetector(
                    onTap: widget.onDownload,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.download,
                        color: Colors.black,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 分割线裁剪器
class _SliderClipper extends CustomClipper<Path> {
  final double sliderPosition;

  _SliderClipper(this.sliderPosition);

  @override
  Path getClip(Size size) {
    final path = Path();
    final splitX = size.width * sliderPosition;

    path.addRect(Rect.fromLTWH(0, 0, splitX, size.height));
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) {
    return true;
  }
}

// 分割线绘制器
class _SliderPainter extends CustomPainter {
  final double sliderPosition;

  _SliderPainter(this.sliderPosition);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2;

    final splitX = size.width * sliderPosition;

    // 绘制垂直分割线
    canvas.drawLine(Offset(splitX, 0), Offset(splitX, size.height), paint);

    // 绘制中心拖动按钮
    final buttonPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final buttonCenter = Offset(splitX, size.height / 2);
    canvas.drawCircle(buttonCenter, 16, buttonPaint);

    // 绘制拖动图标
    final iconPaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    // 左箭头
    canvas.drawLine(
      Offset(splitX - 6, size.height / 2 - 3),
      Offset(splitX - 3, size.height / 2),
      iconPaint,
    );
    canvas.drawLine(
      Offset(splitX - 6, size.height / 2 + 3),
      Offset(splitX - 3, size.height / 2),
      iconPaint,
    );

    // 右箭头
    canvas.drawLine(
      Offset(splitX + 3, size.height / 2),
      Offset(splitX + 6, size.height / 2 - 3),
      iconPaint,
    );
    canvas.drawLine(
      Offset(splitX + 3, size.height / 2),
      Offset(splitX + 6, size.height / 2 + 3),
      iconPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

// 为CustomAiEditChatPageState添加录制覆盖层方法
extension on _CustomAiEditChatPageState {
  // 录制时的大球体覆盖层
  Widget _buildRecordingOverlay() {
    return Positioned.fill(
      child: GestureDetector(
        onTap: _stopRecording, // 点击任意位置停止录制
        child: Container(
          color: Colors.black.withOpacity(0.7), // 半透明背景
          child: Center(
            child: Column(
              children: [
                // 上方空间（70%）
                Expanded(flex: 70, child: Container()),

                // 球体区域（在底部30%的位置）
                Expanded(
                  flex: 30,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // 实时音量驱动的超大3D球体
                        Transform.scale(
                          scale: _currentVolumeScale, // 实时跟随音量变化
                          child: Container(
                            width: 120, // 大球体
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  Colors.red[200]!,
                                  Colors.red[400]!,
                                  Colors.red[700]!,
                                  Colors.red[900]!,
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.red.withOpacity(0.8),
                                  blurRadius: 40,
                                  spreadRadius: 10,
                                ),
                                BoxShadow(
                                  color: Colors.red[300]!.withOpacity(0.6),
                                  blurRadius: 60,
                                  spreadRadius: 20,
                                ),
                              ],
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Colors.red[100]!.withOpacity(0.8),
                                    Colors.red[600]!,
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),

                        // 移除所有文字显示，只保留球体动画
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
