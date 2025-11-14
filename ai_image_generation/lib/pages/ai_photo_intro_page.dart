import 'package:flutter/material.dart';
import 'photo_gallery_page.dart';

class AiPhotoIntroPage extends StatefulWidget {
  const AiPhotoIntroPage({super.key});

  @override
  State<AiPhotoIntroPage> createState() => _AiPhotoIntroPageState();
}

class _AiPhotoIntroPageState extends State<AiPhotoIntroPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 主要内容
          Column(
            children: [
              // 主视觉图片区域
              Expanded(flex: 6, child: _buildMainImageArea()),

              // 底部信息区域
              Expanded(flex: 4, child: _buildBottomInfoArea()),
            ],
          ),

          // 顶部导航栏（叠加在图片上）
          _buildTopNavigation(),
        ],
      ),
    );
  }

  // 顶部导航栏
  Widget _buildTopNavigation() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 16,
          left: 24,
          right: 24,
          bottom: 16,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black.withOpacity(0.6), Colors.transparent],
          ),
        ),
        child: Row(
          children: [
            // 左侧关闭按钮
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 20),
              ),
            ),

            // 中央标题
            const Expanded(
              child: Center(
                child: Text(
                  'AI照片',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            // 右侧占位（保持对称）
            const SizedBox(width: 36),
          ],
        ),
      ),
    );
  }

  // 主视觉图片区域
  Widget _buildMainImageArea() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF2A2A2A), Colors.black],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        child: Image.asset(
          'assets/images/photoshoot/fitness_model/preview_1.jpg',
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            debugPrint('图片加载失败: $error');
            return Container(
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.person, color: Colors.white, size: 80),
                    SizedBox(height: 16),
                    Text(
                      'AI生成的照片效果展示',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // 底部信息区域
  Widget _buildBottomInfoArea() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),

          // 主标题
          RichText(
            text: const TextSpan(
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                height: 1.2,
              ),
              children: [
                TextSpan(
                  text: '用AI生成您的\n',
                  style: TextStyle(color: Colors.white),
                ),
                TextSpan(
                  text: '照片',
                  style: TextStyle(
                    color: Color(0xFFFF6B9D), // 粉红色
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 功能描述
          const Text(
            '训练AI，选择预设，然后\n一键生成照片。✨',
            style: TextStyle(color: Colors.grey, fontSize: 16, height: 1.4),
          ),

          const Spacer(),

          // 生成按钮
          Container(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                // 跳转到照片展示页面
                Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) =>
                        const PhotoGalleryPage(), // 使用默认的fitness_model主题
                    transitionsBuilder:
                        (context, animation, secondaryAnimation, child) {
                          const begin = Offset(0.0, 1.0); // 从下方开始
                          const end = Offset.zero; // 到达正常位置
                          const curve = Curves.easeInOut;

                          var tween = Tween(
                            begin: begin,
                            end: end,
                          ).chain(CurveTween(curve: curve));

                          return SlideTransition(
                            position: animation.drive(tween),
                            child: child,
                          );
                        },
                    transitionDuration: const Duration(milliseconds: 400),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text(
                '生成',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
