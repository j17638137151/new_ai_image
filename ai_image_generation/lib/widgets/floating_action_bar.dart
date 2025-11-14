import 'package:flutter/material.dart';

class FloatingActionBar extends StatelessWidget {
  final bool isVisible;
  final Function(String)? onActionTapped;

  const FloatingActionBar({
    super.key, 
    required this.isVisible,
    this.onActionTapped,
  });

  @override
  Widget build(BuildContext context) {
    debugPrint('FloatingActionBar isVisible: $isVisible');
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        transform: Matrix4.translationValues(
          0,
          isVisible ? 0 : 100, // 向下平移隐藏
          0,
        ),
        height: 100, // 增加高度以适应安全区域
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A), // 使用更亮的背景色以便可见
          border: Border(
            top: BorderSide(
              color: Colors.white.withValues(alpha: 0.1),
              width: 0.5,
            ),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionButton(
                  icon: Icons.auto_fix_high,
                  label: '增强',
                  onTap: () => _onButtonTapped('enhance'),
                ),
                _buildActionButton(
                  icon: Icons.camera_alt_outlined,
                  label: 'AI照片',
                  onTap: () => _onButtonTapped('ai_photo'),
                ),
                _buildActionButton(
                  icon: Icons.tune,
                  label: 'AI滤镜',
                  onTap: () => _onButtonTapped('ai_filter'),
                ),
                _buildActionButton(
                  icon: Icons.edit_outlined,
                  label: '文本编辑',
                  isHighlighted: true,
                  onTap: () => _onButtonTapped('text_edit'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isHighlighted = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: isHighlighted
              ? const Color(0xFFFF4757)
              : const Color(0xFF2F2F2F),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 26),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onButtonTapped(String action) {
    debugPrint('点击了: $action');
    onActionTapped?.call(action);
  }
}
