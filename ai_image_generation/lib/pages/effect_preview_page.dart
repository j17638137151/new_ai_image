import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:ui';
import 'upgrade_page.dart';
import '../services/enhance_service.dart';
import '../services/prompt_service.dart';

class EffectPreviewPage extends StatefulWidget {
  final String imagePath;
  final String effectType; // 效果类型：background_blur, colors等

  const EffectPreviewPage({
    super.key,
    required this.imagePath,
    required this.effectType,
  });

  @override
  State<EffectPreviewPage> createState() => _EffectPreviewPageState();
}

class _EffectPreviewPageState extends State<EffectPreviewPage> {
  int _selectedLevel = 0; // 当前选择的效果级别 (0-7)
  bool _isPremiumUser = false; // 会员状态（未来可通过UserService设置）
  bool _isProcessing = false; // 是否正在AI处理
  String? _processedImagePath; // AI处理后的图片路径

  // 获取效果名称映射
  String get _effectName {
    switch (widget.effectType) {
      case 'background_blur':
        return 'Background Blur';
      case 'colors':
        return 'Colors';
      case 'background_enhancer':
        return 'Background Enhancer';
      case 'face_retouch':
        return 'Face Retouch';
      case 'face_enhancer':
        return 'Face Enhancer';
      default:
        return 'Effect';
    }
  }

  // 获取效果级别名称 (8个级别)
  List<String> get _levelNames {
    return ['Off', 'Low', 'Medium', 'High', 'Extreme', 'Pro', 'Master', 'Ultimate'];
  }

  // 检查是否为付费级别
  bool _isProLevel(int level) {
    return level >= 2 && !_isPremiumUser; // 2-7级别需要会员（除非已是会员）
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 全屏背景图片（应用效果）
          _buildBackgroundImage(),

          // 处理中遮罩
          if (_isProcessing) _buildProcessingOverlay(),

          // 底部效果选择器
          _buildEffectSelector(),

          // 底部控制栏
          _buildBottomControls(),
        ],
      ),
    );
  }

  // 背景图片（根据选择的级别显示不同效果）
  Widget _buildBackgroundImage() {
    return Positioned(
      top: 60, // 给顶部留出状态栏空间
      left: 20,
      right: 20,
      bottom: 290, // 给底部控制区域留出更多空间
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.file(
          File(_processedImagePath ?? widget.imagePath), // 显示处理后的图片
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        ),
      ),
    );
  }

  // 处理中遮罩
  Widget _buildProcessingOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.7),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
              SizedBox(height: 16),
              Text(
                '🤖 AI正在处理中...',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  // 底部效果选择器 (8个级别) - 舒适滚动版本
  Widget _buildEffectSelector() {
    return Positioned(
      bottom: 120,
      left: 0,
      right: 0,
      child: Container(
        height: 130, // 🔥 再增加高度，更舒适
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16), // 🔥 更大的左右边距
          child: Row(
            children: List.generate(8, (index) {
              final isSelected = index == _selectedLevel;
              final isProLevel = _isProLevel(index);

              return GestureDetector(
                onTap: () => _onLevelTap(index),
                child: Container(
                  width: 85, // 🔥 固定宽度，更舒适
                  margin: EdgeInsets.only(
                    right: index < 7 ? 12 : 0, // 🔥 右间距12px，最后一个不加
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 缩略图 - 固定大小，更大气
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 70, // 🔥 固定70px，大气
                            height: 70,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12), // 🔥 更大的圆角
                              border: isSelected
                                  ? Border.all(color: Colors.white, width: 3) // 🔥 更粗的选中边框
                                  : Border.all(color: Colors.white24, width: 1.5),
                              boxShadow: isSelected ? [
                                BoxShadow(
                                  color: Colors.white.withOpacity(0.4), // 🔥 更强的光晕
                                  blurRadius: 12,
                                  spreadRadius: 2,
                                ),
                              ] : [
                                BoxShadow( // 🔥 给所有按钮加淡淡阴影
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 4,
                                  spreadRadius: 0,
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(9),
                              child: Stack(
                                children: [
                                  Image.file(
                                    File(widget.imagePath),
                                    fit: BoxFit.cover,
                                    width: 70,
                                    height: 70,
                                  ),
                                  // PRO级别添加模糊遮罩和锁定图标
                                  if (isProLevel)
                                    Positioned.fill(
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(9),
                                        child: BackdropFilter(
                                          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                                          child: Container(
                                            color: Colors.black.withOpacity(0.6),
                                            child: const Center(
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    Icons.lock,
                                                    color: Colors.white,
                                                    size: 20, // 🔥 更大的锁定图标
                                                  ),
                                                  SizedBox(height: 4),
                                                  Text(
                                                    'PRO',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 10, // 🔥 更大的PRO文字
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12), // 🔥 更大的垂直间距

                      // 级别名称 - 更清晰
                      Text(
                        _levelNames[index],
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.white70,
                          fontSize: 14, // 🔥 更大的字体
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500, // 🔥 更强的对比
                          letterSpacing: 0.5, // 🔥 增加字符间距
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  // 底部控制栏
  Widget _buildBottomControls() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Container(
          height: 80,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(color: Colors.black.withOpacity(0.8)),
          child: Row(
            children: [
              // 关闭按钮
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 24),
                ),
              ),

              // 中间效果名称
              Expanded(
                child: Center(
                  child: Text(
                    _effectName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              // 确认按钮
              GestureDetector(
                onTap: _applyEffect,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 24),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 点击效果级别
  void _onLevelTap(int level) async {
    debugPrint('🎯 点击级别: $level, 是否PRO: ${_isProLevel(level)}');
    
    if (_isProLevel(level)) {
      // PRO功能，跳转到升级页面
      debugPrint('🔒 跳转到升级页面');
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const UpgradePage()),
      );
    } else {
      // 免费功能或会员功能
      if (level == 0) {
        // Level 0 (Off) - 直接切换到原图
        debugPrint('📱 Level 0: 显示原图');
        setState(() {
          _selectedLevel = level;
          _processedImagePath = null; // 重置为原图
        });
      } else {
        // Level 1+ - 需要AI处理
        debugPrint('🤖 Level $level: 开始AI处理');
        await _processWithAI(level);
      }
    }
  }

  // 使用AI处理图片
  Future<void> _processWithAI(int level) async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      debugPrint('🎯 开始AI处理: ${widget.effectType} Level $level');
      
      // 获取精准的提示词
      final prompt = PromptService.getToolLevelPrompt(widget.effectType, level);
      debugPrint('📝 获取到提示词: ${prompt.length > 100 ? prompt.substring(0, 100) + '...' : prompt}');
      
      final currentImagePath = _processedImagePath ?? widget.imagePath;
      debugPrint('🖼️ 处理图片路径: $currentImagePath');
      
      // 调用AI处理（使用自定义提示词方法）
      final result = await EnhanceService.processWithCustomPrompt(
        imagePath: currentImagePath,
        prompt: prompt,
        onProgressUpdate: (progress) {
          debugPrint('⏳ 处理进度: $progress');
        },
      );

      if (mounted) {
        if (result != null) {
          debugPrint('✅ AI处理成功: $result');
          setState(() {
            _selectedLevel = level;
            _processedImagePath = result; // 保存处理结果
            _isProcessing = false;
          });
        } else {
          debugPrint('❌ AI处理失败');
          setState(() {
            _isProcessing = false;
          });
          
          // 显示错误提示
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('AI处理失败，请重试'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('❌ AI处理异常: $e');
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('网络错误，请检查网络连接'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // 应用效果并返回结果
  void _applyEffect() {
    final resultPath = _processedImagePath ?? widget.imagePath;
    debugPrint('✅ 应用 ${_effectName} 效果，级别: ${_levelNames[_selectedLevel]}');
    debugPrint('📸 返回图片路径: $resultPath');
    
    // 返回处理后的图片路径给上一页
    Navigator.pop(context, resultPath);
  }
}
