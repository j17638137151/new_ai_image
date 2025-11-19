import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/user_profile_service.dart';
import '../services/generation_history_api_service.dart';
import '../services/auth_state.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();

  String? _avatarUrl;
  File? _selectedImage;
  bool _isSaving = false;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentProfile();
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _loadCurrentProfile() {
    final user = AuthState.instance.currentUser;
    if (user != null) {
      _nicknameController.text = user.nickname ?? '';
      _bioController.text = user.bio ?? '';
      _avatarUrl = user.avatarUrl;
    }
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });

        // 立即上传头像
        await _uploadAvatar();
      }
    } catch (e) {
      debugPrint('选择图片失败: $e');
      _showSnackBar('选择图片失败', isError: true);
    }
  }

  Future<void> _uploadAvatar() async {
    if (_selectedImage == null) return;

    setState(() {
      _isUploading = true;
    });

    try {
      // 上传到MinIO
      final uploadInfo = await GenerationHistoryApiService.uploadFileDirect(
        _selectedImage!.path,
        contentType: 'image/jpeg',
      );

      setState(() {
        _avatarUrl = uploadInfo.fileUrl;
        _isUploading = false;
      });

      debugPrint('头像上传成功: $_avatarUrl');
    } catch (e) {
      setState(() {
        _isUploading = false;
      });
      debugPrint('头像上传失败: $e');
      _showSnackBar('头像上传失败', isError: true);
    }
  }

  Future<void> _saveProfile() async {
    if (_isSaving) return;

    final nickname = _nicknameController.text.trim();

    // 验证昵称
    if (nickname.isEmpty) {
      _showSnackBar('请输入昵称', isError: true);
      return;
    }

    if (nickname.length > 50) {
      _showSnackBar('昵称不能超过50个字符', isError: true);
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final success = await UserProfileService.updateProfile(
        nickname: nickname,
        avatarUrl: _avatarUrl,
        bio: _bioController.text.trim(),
      );

      if (mounted) {
        setState(() {
          _isSaving = false;
        });

        if (success) {
          // 刷新用户资料
          await AuthState.instance.refreshProfile();
          // 直接返回，不显示提示
          if (mounted) {
            Navigator.of(context).pop(true); // 返回true表示已更新
          }
        } else {
          _showSnackBar('保存失败，请重试', isError: true);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        _showSnackBar('保存失败：${e.toString()}', isError: true);
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? const Color(0xFFFF4757)
            : const Color(0xFF4CAF50),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        title: const Text('编辑资料'),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveProfile,
            child: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    '保存',
                    style: TextStyle(color: Color(0xFFFF4757), fontSize: 16),
                  ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),

            // 头像
            _buildAvatarSection(),

            const SizedBox(height: 40),

            // 昵称
            _buildTextField(
              controller: _nicknameController,
              label: '昵称',
              hint: '请输入昵称',
              maxLength: 50,
            ),

            const SizedBox(height: 24),

            // 个人简介
            _buildTextField(
              controller: _bioController,
              label: '个人简介',
              hint: '介绍一下自己吧...',
              maxLines: 4,
              maxLength: 200,
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarSection() {
    return Column(
      children: [
        GestureDetector(
          onTap: _isUploading ? null : _pickImage,
          child: Stack(
            children: [
              // 头像
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF151515),
                  border: Border.all(color: const Color(0xFFFF4757), width: 2),
                ),
                child: _isUploading
                    ? const Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xFFFF4757),
                          ),
                        ),
                      )
                    : _selectedImage != null
                    ? ClipOval(
                        child: Image.file(
                          _selectedImage!,
                          fit: BoxFit.cover,
                          width: 100,
                          height: 100,
                        ),
                      )
                    : _avatarUrl != null
                    ? ClipOval(
                        child: Image.network(
                          _avatarUrl!,
                          fit: BoxFit.cover,
                          width: 100,
                          height: 100,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.person,
                              color: Colors.white70,
                              size: 50,
                            );
                          },
                        ),
                      )
                    : const Icon(Icons.person, color: Colors.white70, size: 50),
              ),

              // 编辑图标
              if (!_isUploading)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFFF4757),
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          _isUploading ? '上传中...' : '点击更换头像',
          style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
    int? maxLength,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          maxLength: maxLength,
          style: const TextStyle(color: Colors.white, fontSize: 15),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: Colors.white.withOpacity(0.3),
              fontSize: 15,
            ),
            filled: true,
            fillColor: const Color(0xFF151515),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16,
              vertical: maxLines > 1 ? 16 : 14,
            ),
            counterStyle: TextStyle(
              color: Colors.white.withOpacity(0.4),
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}
