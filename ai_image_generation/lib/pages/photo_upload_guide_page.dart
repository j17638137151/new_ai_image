import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../widgets/index.dart';
import 'ai_generation_page.dart';

class PhotoUploadGuidePage extends StatefulWidget {
  final String? selectedThemeId; // 选中的写真主题ID

  const PhotoUploadGuidePage({super.key, this.selectedThemeId});

  @override
  State<PhotoUploadGuidePage> createState() => _PhotoUploadGuidePageState();
}

class _PhotoUploadGuidePageState extends State<PhotoUploadGuidePage> {
  List<File> _selectedPhotos = []; // 存储选择的照片（最多8张）
  bool _isLoading = false;
  late ScrollController _scrollController; // 滚动控制器

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // 自动滚动到底部显示上传的照片
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      // 使用延迟确保UI更新完成后再滚动
      Future.delayed(const Duration(milliseconds: 300), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOutCubic,
          );
        }
      });
    }
  }

  // 显示照片来源选择弹窗
  Future<void> _showPhotoSourceDialog() async {
    await showDialog(
      context: context,
      builder: (context) => PhotoSourceDialog(
        onSourceSelected: (ImageSource source) {
          _pickImageFromSource(source);
        },
      ),
    );
  }

  // 从指定来源选择图片
  Future<void> _pickImageFromSource(ImageSource source) async {
    try {
      setState(() {
        _isLoading = true;
      });

      if (source == ImageSource.camera) {
        // 相机只能拍摄单张
        final XFile? image = await ImagePicker().pickImage(
          source: source,
          imageQuality: 85,
          maxWidth: 1024,
          maxHeight: 1024,
        );

        if (image != null) {
          final File imageFile = File(image.path);
          if (await imageFile.exists()) {
            debugPrint('拍摄照片成功: ${imageFile.path}');

            setState(() {
              if (_selectedPhotos.length < 8) {
                _selectedPhotos.add(imageFile);
              }
            });

            // 自动滚动到底部显示新上传的照片
            _scrollToBottom();
          }
        } else {
          debugPrint('用户取消拍摄');
        }
      } else {
        // 照片库支持多选
        final List<XFile> images = await ImagePicker().pickMultiImage(
          imageQuality: 85,
          maxWidth: 1024,
          maxHeight: 1024,
        );

        if (images.isNotEmpty) {
          List<File> newPhotos = [];

          for (XFile image in images) {
            final File imageFile = File(image.path);
            if (await imageFile.exists()) {
              newPhotos.add(imageFile);
            }
          }

          debugPrint('选择了 ${newPhotos.length} 张照片');

          // 计算当前可以添加的照片数量
          int currentCount = _selectedPhotos.length;
          int maxCanAdd = 8 - currentCount;
          int actualAdded = 0;

          setState(() {
            // 添加新照片，但不超过8张总数
            for (File photo in newPhotos) {
              if (_selectedPhotos.length < 8) {
                _selectedPhotos.add(photo);
                actualAdded++;
              } else {
                break;
              }
            }
          });

          // 自动滚动到底部显示新上传的照片
          _scrollToBottom();

          // 如果选择的照片超过可添加数量，给用户提示
          if (newPhotos.length > maxCanAdd && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '最多只能选择8张照片，已添加 $actualAdded 张，剩余 ${newPhotos.length - actualAdded} 张未添加',
                ),
                backgroundColor: Colors.orange,
              ),
            );
          }
        } else {
          debugPrint('用户取消选择图片');
        }
      }
    } catch (e) {
      debugPrint('选择图片失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('选择图片失败: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // 删除照片
  void _removePhoto(int index) {
    setState(() {
      _selectedPhotos.removeAt(index);
    });
  }

  // 继续按钮处理
  void _onContinue() {
    if (_selectedPhotos.length >= 1) {
      // 显示上传进度弹窗
      showDialog(
        context: context,
        barrierDismissible: false, // 不能点击外部关闭
        builder: (context) => UploadProgressDialog(
          totalPhotos: _selectedPhotos.length, // 传入实际照片数量
          onComplete: () {
            // 进度完成后关闭弹窗并跳转到AI生成页面
            Navigator.pop(context); // 关闭进度弹窗
            _navigateToAIGenerationPage();
          },
        ),
      );
    }
  }

  // 跳转到AI生成页面
  void _navigateToAIGenerationPage() {
    debugPrint('跳转到AI生成页面，照片数量: ${_selectedPhotos.length}');
    debugPrint('🎯 PhotoUploadGuidePage: 当前主题ID: ${widget.selectedThemeId}');

    // 将File转换为路径字符串
    List<String> photoPaths = _selectedPhotos.map((file) => file.path).toList();
    debugPrint('📸 PhotoUploadGuidePage: 照片路径列表: $photoPaths');

    // 跳转到AI生成页面，传递主题ID和照片路径
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AIGenerationPage(
          photoPaths: photoPaths,
          themeId: widget.selectedThemeId, // 传递主题ID
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          // 状态栏占位
          Container(
            height: MediaQuery.of(context).padding.top,
            color: Colors.black,
          ),

          // 顶部导航栏
          _buildTopNavigation(),

          // 主要内容
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 40),

                  // 主标题
                  _buildMainTitle(),

                  const SizedBox(height: 16),

                  // 副标题
                  _buildSubTitle(),

                  const SizedBox(height: 60),

                  // AI流程图示
                  _buildAIFlowDiagram(),

                  const SizedBox(height: 80),

                  // 照片网格（当有照片时显示）
                  if (_selectedPhotos.isNotEmpty) ...[
                    _buildPhotosSection(),
                    const SizedBox(height: 30),
                    _buildLegalText(),
                    const SizedBox(height: 30),
                  ],
                ],
              ),
            ),
          ),

          // 底部上传按钮
          _buildUploadButton(),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // 顶部导航栏
  Widget _buildTopNavigation() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // 左侧返回按钮
          GestureDetector(
            onTap: () {
              Navigator.pop(context);
            },
            child: Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(shape: BoxShape.circle),
              child: const Icon(
                Icons.arrow_back_ios,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),

          // 中央标题
          const Expanded(
            child: Center(
              child: Text(
                '上传自拍照',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          // 右侧关闭按钮（回到首页）
          GestureDetector(
            onTap: () {
              // 回到首页 - 清除所有页面栈
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            child: Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(shape: BoxShape.circle),
              child: const Icon(
                Icons.keyboard_arrow_down,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 主标题
  Widget _buildMainTitle() {
    return const Text(
      '让我们看看你的样子',
      style: TextStyle(
        color: Colors.white,
        fontSize: 28,
        fontWeight: FontWeight.bold,
        height: 1.2,
      ),
    );
  }

  // 副标题
  Widget _buildSubTitle() {
    return const Text(
      '上传您的自拍照，帮助人工智能为您生成令人惊叹的照片！✨',
      style: TextStyle(color: Colors.grey, fontSize: 16, height: 1.4),
    );
  }

  // AI流程图示
  Widget _buildAIFlowDiagram() {
    return Column(
      children: [
        // 上半部分：你的自拍照 + AI魔法
        Row(
          children: [
            // 左侧：你的自拍照
            Expanded(
              child: Column(
                children: [
                  // 4张照片：上下两排，左右重叠
                  Container(
                    width: 90, // 50 + 50 - 10 (重叠)
                    height: 90, // 50 + 50 - 10 (重叠)
                    child: Stack(
                      children: [
                        // 上排左侧
                        Positioned(
                          top: 0,
                          left: 0,
                          child: _buildCirclePhoto(
                            'https://p.potaufeu.asahi.com/27df-p/picture/26127222/86950447374cf274e97cb8778e70d4ca.jpg',
                          ),
                        ),
                        // 上排右侧 (左右重叠10px)
                        Positioned(
                          top: 0,
                          left: 40, // 50 - 10
                          child: _buildCirclePhoto(
                            'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=100&h=100&fit=crop&crop=face',
                          ),
                        ),
                        // 下排左侧 (上下重叠10px)
                        Positioned(
                          top: 40, // 50 - 10
                          left: 0,
                          child: _buildCirclePhoto(
                            'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=100&h=100&fit=crop&crop=face',
                          ),
                        ),
                        // 下排右侧 (左右重叠10px，上下重叠10px)
                        Positioned(
                          top: 40, // 50 - 10
                          left: 40, // 50 - 10
                          child: _buildCirclePhoto(
                            'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=100&h=100&fit=crop&crop=face',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '你的自拍照📷',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            // 中间：粉色水平箭头
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 30,
                  height: 2,
                  decoration: BoxDecoration(
                    color: Colors.pink[400],
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_right,
                  color: Colors.pink[400],
                  size: 28,
                ),
              ],
            ),

            // 右侧：AI魔法
            Expanded(
              child: Column(
                children: [
                  // AI魔法云朵图标
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(40),
                    ),
                    child: const Center(
                      child: Text('🧠', style: TextStyle(fontSize: 40)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'AI魔法✨',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 40),

        // 流程箭头（倾斜）
        Transform.rotate(
          angle: 0.3, // 向右倾斜约17度
          child: Column(
            children: [
              Container(
                width: 2,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.pink[400],
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
              Icon(
                Icons.keyboard_arrow_down,
                color: Colors.pink[400],
                size: 32,
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // 下半部分：生成结果
        Column(
          children: [
            // 生成的照片（缩小尺寸）
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.orange[400]!, width: 3),
              ),
              child: ClipOval(
                child: Image.network(
                  'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200&h=200&fit=crop&crop=face',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '由AI生成✨',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // 圆形照片组件
  Widget _buildCirclePhoto(String imageUrl) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: ClipOval(
        child: Image.network(
          imageUrl,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              color: Colors.grey[800],
              child: const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.grey[800],
              child: const Icon(Icons.person, color: Colors.white, size: 25),
            );
          },
        ),
      ),
    );
  }

  // 底部上传按钮
  Widget _buildUploadButton() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 24),
      child: ElevatedButton(
        onPressed: () {
          if (_selectedPhotos.isNotEmpty) {
            // 如果有照片，继续到下一步
            _onContinue();
          } else {
            // 如果没有照片，显示选择弹窗
            _showPhotoSourceDialog();
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _selectedPhotos.isNotEmpty
                  ? '继续 (${_selectedPhotos.length}/8)'
                  : '上传8张自拍照',
              style: const TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 12),
            Icon(
              _selectedPhotos.isNotEmpty ? Icons.arrow_forward : Icons.add,
              color: Colors.black,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  // 照片展示区域
  Widget _buildPhotosSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '你的自拍照',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 20),
        _buildPhotoGrid(),
      ],
    );
  }

  // 照片网格
  Widget _buildPhotoGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.0,
      ),
      itemCount: 9, // 8张照片 + 1个添加按钮
      itemBuilder: (context, index) {
        if (index < _selectedPhotos.length) {
          // 显示已选择的照片
          return _buildPhotoItem(_selectedPhotos[index], index);
        } else if (index == _selectedPhotos.length &&
            _selectedPhotos.length < 8) {
          // 显示添加按钮
          return _buildAddButton();
        } else {
          // 显示空占位符
          return Container(
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(12),
            ),
          );
        }
      },
    );
  }

  // 单个照片项目
  Widget _buildPhotoItem(File photo, int index) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red, width: 2),
      ),
      child: Stack(
        children: [
          // 照片
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.file(
              photo,
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
            ),
          ),

          // 删除按钮
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () => _removePhoto(index),
              child: Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.black, size: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 添加按钮
  Widget _buildAddButton() {
    return GestureDetector(
      onTap: _isLoading ? null : _showPhotoSourceDialog,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF2F2F2F),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Icon(Icons.add, color: Colors.white, size: 32),
        ),
      ),
    );
  }

  // 法律声明文字
  Widget _buildLegalText() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '通过点击"继续"，您声明您拥有与我们分享这些图像的所有必要权利和许可，并且您将合法使用所生成的照片。',
          style: TextStyle(color: Colors.grey[400], fontSize: 12, height: 1.4),
        ),
        const SizedBox(height: 12),
        Text(
          '如果您上传包含未成年人的图片，请点击"继续"，即表示您对他们拥有父母权责，并且拥有分享图片的必要权限。',
          style: TextStyle(color: Colors.grey[400], fontSize: 12, height: 1.4),
        ),
      ],
    );
  }
}
