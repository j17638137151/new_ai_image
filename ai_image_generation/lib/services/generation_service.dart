import 'package:flutter/foundation.dart';
import 'dart:async';
import 'ai_model_service.dart';
import 'generation_history_api_service.dart';
import '../models/photobooth_model.dart';

enum GenerationStatus {
  idle, // 空闲状态
  generating, // 生成中
  completed, // 已完成
}

class GenerationTask {
  final String id;
  final String type; // 'photobooth', 'enhance', 等
  final DateTime startTime;
  final String title;
  final String description;
  final List<String> inputImages;
  final String? effectId; // 具体效果ID，如 'side_hug', 'classic_hug'

  GenerationTask({
    required this.id,
    required this.type,
    required this.startTime,
    required this.title,
    required this.description,
    required this.inputImages,
    this.effectId, // 可选的效果ID
  });
}

class GenerationService extends ChangeNotifier {
  static final GenerationService _instance = GenerationService._internal();
  factory GenerationService() => _instance;
  GenerationService._internal();

  GenerationStatus _status = GenerationStatus.idle;
  GenerationTask? _currentTask;
  List<String> _generatedResults = [];
  Timer? _autoHideTimer; // 自动隐藏定时器
  String? _aiGeneratedImagePath; // AI生成的图片路径

  GenerationStatus get status => _status;
  GenerationTask? get currentTask => _currentTask;
  List<String> get generatedResults => _generatedResults;

  // 检查是否有正在进行的任务
  bool get hasActiveTask => _status != GenerationStatus.idle;

  // 检查是否有已完成的任务
  bool get hasCompletedTask => _status == GenerationStatus.completed;

  // 开始生成任务
  void startGeneration({
    required String type,
    required String title,
    required String description,
    required List<String> inputImages,
    String? effectId, // 可选的效果ID
  }) {
    if (_status == GenerationStatus.generating) {
      debugPrint('已有生成任务进行中，无法开始新任务');
      return;
    }

    _currentTask = GenerationTask(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: type,
      startTime: DateTime.now(),
      title: title,
      description: description,
      inputImages: inputImages,
      effectId: effectId, // 传递效果ID
    );

    _status = GenerationStatus.generating;
    _generatedResults.clear();

    debugPrint('开始生成任务: ${_currentTask!.type}');
    notifyListeners();

    // 模拟生成过程 (实际项目中这里会调用AI生成API)
    _simulateGeneration();
  }

  // 真实AI生成过程
  void _simulateGeneration() async {
    if (_currentTask == null || _currentTask!.inputImages.isEmpty) {
      debugPrint('❌ GenerationService: 生成任务或输入图片为空');
      _status = GenerationStatus.idle;
      notifyListeners();
      return;
    }

    try {
      debugPrint('🚀 GenerationService: 开始调用AI服务...');
      debugPrint('📸 输入图片: ${_currentTask!.inputImages}');

      // 构造针对任务类型的提示词
      String prompt = _getPromptForTaskType(_currentTask!.type);
      debugPrint('💬 提示词: $prompt');

      // 调用AI服务处理图片
      final result = await AIModelService.processImages(
        imagePaths: _currentTask!.inputImages,
        prompt: prompt,
      );

      // 检查生成状态是否仍然有效
      if (_status == GenerationStatus.generating) {
        if (result != null) {
          debugPrint('✅ GenerationService: AI生成成功 - $result');
          _aiGeneratedImagePath = result;
          _completeGeneration();
        } else {
          debugPrint('❌ GenerationService: AI生成失败');
          _status = GenerationStatus.idle;
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('❌ GenerationService: AI生成异常 - $e');
      if (_status == GenerationStatus.generating) {
        _status = GenerationStatus.idle;
        notifyListeners();
      }
    }
  }

  // 根据任务类型获取提示词
  String _getPromptForTaskType(String taskType) {
    switch (taskType) {
      case 'photobooth':
        // 使用PhotoboothModel的具体效果
        final effects = PhotoboothModel.getAllEffects();
        if (effects.isNotEmpty) {
          // 如果有指定effectId，查找对应的效果
          if (_currentTask?.effectId != null) {
            final selectedEffect = effects.firstWhere(
              (effect) => effect.id == _currentTask!.effectId,
              orElse: () => effects.first, // 找不到就用第一个
            );
            debugPrint(
              '📝 GenerationService: 使用PhotoboothModel - ${selectedEffect.title} (ID: ${selectedEffect.id})',
            );
            return selectedEffect.aiPrompt;
          } else {
            // 没有指定effectId，使用第一个
            debugPrint(
              '📝 GenerationService: 使用PhotoboothModel - ${effects.first.title} (默认)',
            );
            return effects.first.aiPrompt;
          }
        } else {
          debugPrint('⚠️ GenerationService: PhotoboothModel为空，使用默认提示词');
          return '请将这两张照片中的人物合成一个拥抱的合照效果';
        }

      case 'art_toy':
        return '将这些照片转换为艺术玩具风格，保持人物特征但添加玩具化的视觉效果';

      case 'muscle_filter':
        return '增强照片中人物的肌肉线条和体型，创造健身达人的效果';

      case 'enhance':
        return '增强照片质量，提升清晰度、色彩和细节表现';

      default:
        return '请处理这些照片，创造出精美的效果';
    }
  }

  // 完成生成
  void _completeGeneration() {
    // 使用AI生成的真实结果
    if (_aiGeneratedImagePath != null) {
      _generatedResults = [_aiGeneratedImagePath!];

      // 异步同步到对象存储和生成历史
      final path = _aiGeneratedImagePath!;
      final task = _currentTask;
      if (task != null) {
        unawaited(
          GenerationHistoryApiService.syncGenerationResult(
            localFilePath: path,
            type: task.type,
            effectId: task.effectId,
          ).catchError((e, stack) {
            debugPrint('同步生成历史失败: $e');
          }),
        );
      }
    } else {
      // 兜底：如果AI生成失败，使用默认图片
      _generatedResults = [
        'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400&h=400&fit=crop&crop=face',
      ];
    }

    _status = GenerationStatus.completed;
    debugPrint('生成完成: ${_generatedResults.length}张图片');
    debugPrint('AI生成结果: $_aiGeneratedImagePath');
    notifyListeners();

    // 启动1分钟后自动隐藏定时器
    _startAutoHideTimer();
  }

  // 启动自动隐藏定时器
  void _startAutoHideTimer() {
    _autoHideTimer?.cancel(); // 取消之前的定时器
    _autoHideTimer = Timer(const Duration(minutes: 1), () {
      if (_status == GenerationStatus.completed) {
        clearCompletedTask();
      }
    });
  }

  // 清除已完成的任务
  void clearCompletedTask() {
    if (_status == GenerationStatus.completed) {
      _autoHideTimer?.cancel(); // 取消自动隐藏定时器
      _status = GenerationStatus.idle;
      _currentTask = null;
      _generatedResults.clear();
      debugPrint('已清除完成的任务');
      notifyListeners();
    }
  }

  // 重置服务状态
  void reset() {
    _autoHideTimer?.cancel(); // 取消自动隐藏定时器
    _status = GenerationStatus.idle;
    _currentTask = null;
    _generatedResults.clear();
    debugPrint('重置生成服务状态');
    notifyListeners();
  }

  // 清理服务资源（用于应用关闭时调用）
  @override
  void dispose() {
    _autoHideTimer?.cancel();
    _status = GenerationStatus.idle;
    _currentTask = null;
    _generatedResults.clear();
    debugPrint('GenerationService已清理资源');
    super.dispose();
  }

  // 获取生成进度文案
  String getProgressText() {
    switch (_status) {
      case GenerationStatus.idle:
        return '';
      case GenerationStatus.generating:
        return '我们正在生成您的照片...';
      case GenerationStatus.completed:
        return '您的照片已经准备好了！🎉';
    }
  }

  // 获取生成子标题文案
  String getSubtitleText() {
    switch (_status) {
      case GenerationStatus.idle:
        return '';
      case GenerationStatus.generating:
        return '快准备好了...';
      case GenerationStatus.completed:
        return '现在就去看看。';
    }
  }

  // 获取任务类型显示文本
  String getTaskTypeDisplay() {
    if (_currentTask == null) return '';

    switch (_currentTask!.type) {
      case 'photobooth':
        return 'PHOTOBOOTH 📷';
      case 'enhance':
        return 'ENHANCE ✨';
      case 'art_toy':
        return 'ART TOY 🎨';
      default:
        return 'AI GENERATION 🤖';
    }
  }
}
