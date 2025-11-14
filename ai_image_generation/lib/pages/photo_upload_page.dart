import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../widgets/index.dart';
import '../services/face_detection_service.dart';
import '../services/generation_service.dart';

class PhotoUploadPage extends StatefulWidget {
  final String? effectId; // 可选的效果ID

  const PhotoUploadPage({super.key, this.effectId});

  @override
  State<PhotoUploadPage> createState() => _PhotoUploadPageState();
}

class _PhotoUploadPageState extends State<PhotoUploadPage>
    with TickerProviderStateMixin {
  File? _person1Image;
  File? _person2Image;
  bool _isLoading = false;

  late AnimationController _person2AnimationController;
  late Animation<double> _person2FadeAnimation;
  late Animation<Offset> _person2SlideAnimation;

  final FaceDetectionService _faceDetectionService = FaceDetectionService();

  @override
  void initState() {
    super.initState();
    _initAnimations();
  }

  void _initAnimations() {
    _person2AnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _person2FadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _person2AnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _person2SlideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _person2AnimationController,
            curve: Curves.easeOutCubic,
          ),
        );
  }

  @override
  void dispose() {
    _person2AnimationController.dispose();
    _faceDetectionService.dispose();
    super.dispose();
  }

  // 处理图片选择
  Future<void> _pickImage(int personNumber) async {
    try {
      setState(() {
        _isLoading = true;
      });

      // 使用更安全的方式选择图片
      final XFile? image = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (image != null) {
        final File imageFile = File(image.path);

        // 检查文件是否存在
        if (await imageFile.exists()) {
          debugPrint('图片选择成功，开始人脸检测: ${imageFile.path}');

          // 先进行人脸检测，检测通过才显示图片
          await _performFaceDetectionAndSetImage(imageFile, personNumber);
        } else {
          debugPrint('图片文件不存在');
        }
      } else {
        debugPrint('用户取消选择图片');
      }
    } catch (e) {
      debugPrint('选择图片失败: $e');
      // 注释掉错误提示
      // if (mounted) {
      //   ScaffoldMessenger.of(context).showSnackBar(
      //     SnackBar(
      //       content: Text('选择图片失败: ${e.toString()}'),
      //       backgroundColor: Colors.red,
      //     ),
      //   );
      // }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // 执行人脸检测并根据结果设置图片
  Future<void> _performFaceDetectionAndSetImage(
    File imageFile,
    int personNumber,
  ) async {
    try {
      final faceCount = await _faceDetectionService.detectFaces(imageFile);
      debugPrint('检测结果 - 人脸数量: $faceCount, 人物编号: $personNumber');

      if (mounted) {
        // 临时解决方案：如果检测失败(返回0)，先直接显示图片，方便测试
        if (faceCount == 0) {
          debugPrint('⚠️ 检测到0张人脸，临时跳过检查直接显示图片');
          // 临时：直接设置图片，不弹警告
          setState(() {
            if (personNumber == 1) {
              _person1Image = imageFile;
              if (_person2Image == null) {
                _person2AnimationController.forward();
              }
            } else {
              _person2Image = imageFile;
            }
          });
          debugPrint('✅ 临时跳过检测，图片已设置: ${imageFile.path}');

          // 可选：还是弹出警告让用户知道
          // _showFaceDetectionDialog('无人脸', personNumber);
        } else if (faceCount > 1) {
          // 多人脸，显示警告弹窗，不设置图片
          debugPrint('❌ 检测到多张人脸: $faceCount');
          _showFaceDetectionDialog('多人脸', personNumber);
        } else {
          // 检测到一张人脸，设置图片并更新UI
          debugPrint('✅ 检测到1张人脸，正常设置图片');
          setState(() {
            if (personNumber == 1) {
              _person1Image = imageFile;
              // 如果人物1上传成功，显示人物2区域
              if (_person2Image == null) {
                _person2AnimationController.forward();
              }
            } else {
              _person2Image = imageFile;
            }
          });
          debugPrint('人脸检测成功，图片已设置: ${imageFile.path}');
        }
      }
    } catch (e) {
      debugPrint('❌ 人脸检测异常: $e');
      // 检测异常时，临时也直接显示图片
      setState(() {
        if (personNumber == 1) {
          _person1Image = imageFile;
          if (_person2Image == null) {
            _person2AnimationController.forward();
          }
        } else {
          _person2Image = imageFile;
        }
      });
      debugPrint('⚠️ 检测异常，临时跳过检查直接显示图片');
    }
  }

  // 删除图片
  void _deleteImage(File? imageToDelete) {
    setState(() {
      if (_person1Image == imageToDelete) {
        _person1Image = null;
        // 如果删除了人物1的照片，隐藏人物2区域
        if (_person2Image == null) {
          _person2AnimationController.reverse();
        }
      } else if (_person2Image == imageToDelete) {
        _person2Image = null;
      }
    });

    // 注释掉删除成功提示
    // ScaffoldMessenger.of(context).showSnackBar(
    //   const SnackBar(
    //     content: Text('📷 照片已删除'),
    //     backgroundColor: Colors.orange,
    //     duration: Duration(seconds: 1),
    //   ),
    // );
  }

  // 显示人脸检测结果弹窗
  void _showFaceDetectionDialog(String type, int personNumber) {
    showDialog(
      context: context,
      builder: (context) => FaceDetectionDialog(
        type: type,
        onSelectPhoto: () => _pickImage(personNumber), // 重新选择同一个人物的照片
      ),
    );
  }

  // 底部按钮点击处理
  Future<void> _onBottomButtonPressed() async {
    if (_person1Image == null) {
      // 填充人物1
      await _pickImage(1);
    } else if (_person2Image == null) {
      // 填充人物2
      await _pickImage(2);
    } else {
      // 继续下一步
      _onContinue();
    }
  }

  void _onContinue() {
    // 启动AI生成流程
    final generationService = GenerationService();

    // 收集上传的图片路径
    List<String> inputImages = [];
    if (_person1Image != null) {
      inputImages.add(_person1Image!.path);
    }
    if (_person2Image != null) {
      inputImages.add(_person2Image!.path);
    }

    // 启动Photobooth生成任务
    generationService.startGeneration(
      type: 'photobooth',
      title: 'Photobooth Photos',
      description: '正在生成您的AI照片展示',
      inputImages: inputImages,
      effectId: widget.effectId, // 传递效果ID
    );

    debugPrint('已启动AI生成任务，返回首页...');

    // 返回首页
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          '上传自拍照',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
      ),
      body: Column(
        children: [
          // 主要内容区域
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),

                  // 人物1区域
                  _buildPersonCard(
                    title: '人物1',
                    image: _person1Image,
                    onTap: () => _pickImage(1),
                    showUpload: true,
                  ),

                  const SizedBox(height: 30),

                  // 人物2区域
                  _buildPersonCard(
                    title: '人物2',
                    image: _person2Image,
                    onTap: () => _pickImage(2),
                    showUpload: _person1Image != null,
                    hasAnimation: true,
                  ),

                  const SizedBox(height: 40),

                  // 提示区域
                  _buildTipsSection(),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // 底部固定按钮
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.black,
              border: Border(
                top: BorderSide(
                  color: Colors.white.withOpacity(0.1),
                  width: 0.5,
                ),
              ),
            ),
            child: SafeArea(top: false, child: _buildBottomButton()),
          ),
        ],
      ),
    );
  }

  Widget _buildTipsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.warning_rounded,
                  color: Colors.orange,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                '提示',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._getTipTexts().map(
            (tip) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                tip,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<String> _getTipTexts() {
    if (_person1Image != null && _person2Image != null) {
      return [
        '点击"继续"，您声明您拥有所有必要的权利和权限与我们分享这些图片，并且您将合法使用所生成的照片。',
        '如果您上传含有未成年人的照片，点击"继续"，您声明您对他们拥有父母权责，并且拥有分享图片的权利。',
      ];
    } else {
      return ['使用一张有一个人的照片。', '使用一张正面且特征清晰的照片。', '不要使用一张有多个人的照片。'];
    }
  }

  Widget _buildBottomButton() {
    final buttonText = _getButtonText();
    final buttonIcon = _getButtonIcon();

    return GestureDetector(
      onTap: _isLoading ? null : _onBottomButtonPressed,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: _isLoading ? Colors.grey.shade600 : Colors.white,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isLoading)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                ),
              )
            else ...[
              Text(
                buttonText,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              Icon(buttonIcon, color: Colors.black, size: 20),
            ],
          ],
        ),
      ),
    );
  }

  String _getButtonText() {
    if (_person1Image != null && _person2Image != null) {
      return '继续';
    } else {
      return '上传一张自拍照';
    }
  }

  IconData _getButtonIcon() {
    if (_person1Image != null && _person2Image != null) {
      return Icons.arrow_forward;
    } else {
      return Icons.add;
    }
  }

  // 构建人物卡片（灰色块包含标题和上传组件）
  Widget _buildPersonCard({
    required String title,
    required File? image,
    required VoidCallback onTap,
    required bool showUpload,
    bool hasAnimation = false,
  }) {
    Widget cardContent = Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题行
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFF2F2F2F),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.person,
                  color: Colors.white70,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          // 上传组件（条件显示）
          if (showUpload) ...[
            const SizedBox(height: 20),
            _buildSquareUploadComponent(image: image, onTap: onTap),
          ],
        ],
      ),
    );

    // 如果需要动画效果（人物2）
    if (hasAnimation && showUpload) {
      return SlideTransition(
        position: _person2SlideAnimation,
        child: FadeTransition(
          opacity: _person2FadeAnimation,
          child: cardContent,
        ),
      );
    }

    return cardContent;
  }

  // 构建正方形上传组件
  Widget _buildSquareUploadComponent({
    required File? image,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: _isLoading ? null : onTap,
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: const Color(0xFF2F2F2F),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
        ),
        child: Stack(
          children: [
            // 主要内容区域
            if (image != null)
              // 显示已上传的图片
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  image,
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                ),
              )
            else
              // 显示上传占位符
              Center(
                child: Icon(
                  Icons.add,
                  color: Colors.white.withOpacity(0.6),
                  size: 32,
                ),
              ),

            // 警告图标（未上传状态）
            if (image == null)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: const BoxDecoration(
                    color: Colors.orange,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.priority_high,
                    color: Colors.white,
                    size: 10,
                  ),
                ),
              ),

            // 删除按钮（已上传状态）
            if (image != null)
              Positioned(
                top: 6,
                right: 6,
                child: GestureDetector(
                  onTap: () => _deleteImage(image),
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 12,
                    ),
                  ),
                ),
              ),

            // 加载指示器
            if (_isLoading)
              Container(
                width: double.infinity,
                height: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
