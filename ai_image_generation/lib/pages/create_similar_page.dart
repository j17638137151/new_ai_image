import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../models/explore_item_model.dart';
import '../services/ai_model_service.dart';
import 'create_similar_result_page.dart';

class CreateSimilarPage extends StatefulWidget {
  final ExploreItemModel originalItem;

  const CreateSimilarPage({
    super.key,
    required this.originalItem,
  });

  @override
  State<CreateSimilarPage> createState() => _CreateSimilarPageState();
}

class _CreateSimilarPageState extends State<CreateSimilarPage> {
  late TextEditingController _promptController;
  List<File> _uploadedImages = [];
  final ImagePicker _picker = ImagePicker();
  bool _isGenerating = false; // 跟踪生成状态，避免重复操作
  
  // 获取允许上传的最大图片数量
  int get _maxImageCount => widget.originalItem.uploadImageCount;

  @override
  void initState() {
    super.initState();
    _promptController = TextEditingController(text: widget.originalItem.prompt);
  }

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: GestureDetector(
        onTap: () {
          // 点击空白区域收起键盘
          FocusScope.of(context).unfocus();
        },
        child: SafeArea(
          child: Column(
            children: [
              // 顶部导航栏
              _buildTopNavBar(),
              
              // 主要内容区域
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 图片上传区域
                      _buildImageUploadSection(),
                      
                      const SizedBox(height: 24),
                      
                      // 提示词编辑区域
                      _buildPromptSection(),
                      
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
              
              // 底部生成按钮
              _buildBottomGenerateButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopNavBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(
              Icons.arrow_back,
              color: Colors.white,
              size: 24,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () {
              // TODO: 更多选项
            },
            child: const Icon(
              Icons.more_horiz,
              color: Colors.white,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageUploadSection() {
    return Container(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '上传图片 (最多${_maxImageCount}张)',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          
          // 图片网格
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              // 已上传的图片
              ..._uploadedImages.map((image) => _buildImageItem(image)),
              
              // 上传按钮（如果未达到上限）
              if (_uploadedImages.length < _maxImageCount) _buildUploadButton(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImageItem(File image) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: const Color(0xFF2F2F2F),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        children: [
          // 图片内容
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(
              image,
              width: 80,
              height: 80,
              fit: BoxFit.cover,
            ),
          ),
          
          // 删除按钮
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () => _removeImage(image),
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadButton() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: const Color(0xFF2F2F2F),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.3),
            width: 1,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add,
              color: Colors.white.withValues(alpha: 0.6),
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              '上传',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPromptSection() {
    return Container(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 提示词输入框
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
            child: TextField(
              controller: _promptController,
              maxLines: 4,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                height: 1.5,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: '输入你的创作提示词...',
                hintStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 14,
                ),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildBottomGenerateButton() {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        border: Border(
          top: BorderSide(
            color: Colors.white.withValues(alpha: 0.15),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          // 参数信息
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.image_outlined,
                    color: Colors.white.withValues(alpha: 0.6),
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${_uploadedImages.length}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          const SizedBox(width: 20),
          // 生成按钮
          Expanded(
            child: GestureDetector(
              onTap: _isGenerating ? null : _onGenerate,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: _isGenerating ? const Color(0xFF666666) : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: _isGenerating
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            '生成中...',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      )
                    : const Text(
                        '生成',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 图片上传相关方法
  Future<void> _pickImage() async {
    if (_uploadedImages.length >= _maxImageCount) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('最多只能上传${_maxImageCount}张图片'),
          backgroundColor: const Color(0xFF2F2F2F),
        ),
      );
      return;
    }
    
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );
      
      if (image != null) {
        setState(() {
          _uploadedImages.add(File(image.path));
        });
      }
    } catch (e) {
      debugPrint('上传图片失败: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('上传图片失败'),
          backgroundColor: Color(0xFF2F2F2F),
        ),
      );
    }
  }
  
  void _removeImage(File image) {
    setState(() {
      _uploadedImages.remove(image);
    });
  }

  Future<void> _onGenerate() async {
    if (_isGenerating) return; // 防止重复点击
    
    if (_uploadedImages.length != _maxImageCount) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('请上传${_maxImageCount}张图片才能生成'),
          backgroundColor: const Color(0xFF2F2F2F),
        ),
      );
      return;
    }
    
    if (_promptController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('请输入描述文字'),
          backgroundColor: Color(0xFF2F2F2F),
        ),
      );
      return;
    }
    
    setState(() {
      _isGenerating = true;
    });
    
    // 显示生成进度
    _showGeneratingDialog();
    
    try {
      debugPrint('🚀 开始AI生成: ${_promptController.text}');
      debugPrint('📸 上传图片数量: ${_uploadedImages.length}');
      
      // 验证图片路径
      final imagePaths = _uploadedImages.map((file) => file.path).toList();
      for (final path in imagePaths) {
        if (path.isEmpty || !File(path).existsSync()) {
          throw Exception('图片文件不存在或路径无效');
        }
      }
      
      // 调用统一的AI生图服务
      final result = await AIModelService.processImages(
        imagePaths: imagePaths,
        prompt: _promptController.text.trim(),
      );
      
      if (mounted) {
        // 关闭进度弹窗
        Navigator.pop(context);
        
        if (result != null && result.isNotEmpty) {
          debugPrint('✅ AI生成成功: $result');
          
          // 跳转到结果页面
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => CreateSimilarResultPage(
                generatedImagePath: result,
                originalTitle: widget.originalItem.name,
              ),
            ),
          );
        } else {
          debugPrint('❌ AI生成失败: 结果为空');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('生成失败，请重试'),
              backgroundColor: Color(0xFFFF4757),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('❌ AI生成异常: $e');
      if (mounted) {
        // 安全关闭进度弹窗
        try {
          Navigator.pop(context);
        } catch (popError) {
          debugPrint('关闭弹窗失败: $popError');
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('生成失败: $e'),
            backgroundColor: const Color(0xFFFF4757),
          ),
        );
      }
    } finally {
      // 重置生成状态
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }
    }
  }
  
  // 显示生成进度弹窗
  void _showGeneratingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2F2F2F),
        content: Row(
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF4757)),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Text(
                '正在处理中，请稍候...',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
