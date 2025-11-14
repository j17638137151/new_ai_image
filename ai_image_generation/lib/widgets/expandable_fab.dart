import 'package:flutter/material.dart';

class ExpandableFab extends StatefulWidget {
  final Function(String)? onActionTapped;

  const ExpandableFab({
    super.key,
    this.onActionTapped,
  });

  @override
  State<ExpandableFab> createState() => _ExpandableFabState();
}

class _ExpandableFabState extends State<ExpandableFab>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _backgroundController;
  late Animation<double> _expandAnimation;
  late Animation<double> _backgroundAnimation;
  bool _isExpanded = false;

  // 按钮配置
  final List<ActionButtonConfig> _actions = [
    ActionButtonConfig(
      icon: Icons.auto_fix_high,
      label: '增强',
      action: 'enhance',
      color: const Color(0xFF2F2F2F),
    ),
    ActionButtonConfig(
      icon: Icons.camera_alt_outlined,
      label: 'AI照片',
      action: 'ai_photo',
      color: const Color(0xFF2F2F2F),
    ),
    ActionButtonConfig(
      icon: Icons.tune,
      label: 'AI滤镜',
      action: 'ai_filter',
      color: const Color(0xFF2F2F2F),
    ),
    ActionButtonConfig(
      icon: Icons.edit_outlined,
      label: '文本编辑',
      action: 'text_edit',
      isHighlighted: true,
    ),
  ];

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _backgroundController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );

    _backgroundAnimation = Tween<double>(
      begin: 0.0,
      end: 0.5,
    ).animate(CurvedAnimation(
      parent: _backgroundController,
      curve: Curves.easeOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    _backgroundController.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isExpanded = !_isExpanded;
    });

    if (_isExpanded) {
      _backgroundController.forward();
      _controller.forward();
    } else {
      _controller.reverse();
      _backgroundController.reverse();
    }
  }

  void _onActionTapped(String action) {
    widget.onActionTapped?.call(action);
    _toggle(); // 点击按钮后自动收起
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 背景遮罩
        AnimatedBuilder(
          animation: _backgroundAnimation,
          builder: (context, child) {
            return _backgroundAnimation.value > 0
                ? GestureDetector(
                    onTap: _toggle, // 点击背景收起
                    child: Container(
                      width: double.infinity,
                      height: double.infinity,
                      color: Colors.black.withValues(
                        alpha: _backgroundAnimation.value,
                      ),
                    ),
                  )
                : const SizedBox.shrink();
          },
        ),

        // 扇形展开的按钮
        ...List.generate(_actions.length, (index) {
          return _buildExpandableButton(index);
        }),

        // 主FAB按钮
        Positioned(
          bottom: 30,
          right: 20,
          child: _buildMainFab(),
        ),
      ],
    );
  }

  Widget _buildMainFab() {
    return AnimatedBuilder(
      animation: _expandAnimation,
      builder: (context, child) {
        return GestureDetector(
          onTap: _toggle,
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFFFF6B35), // 橙色
                  Color(0xFFFF4757), // 红色
                  Color(0xFFE91E63), // 粉红色
                  Color(0xFF9C27B0), // 紫色
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF4757).withValues(alpha: 0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: AnimatedRotation(
              turns: _isExpanded ? 0.125 : 0, // 45度旋转
              duration: const Duration(milliseconds: 300),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  _isExpanded ? Icons.close : Icons.auto_awesome,
                  key: ValueKey(_isExpanded),
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildExpandableButton(int index) {
    return AnimatedBuilder(
      animation: _expandAnimation,
      builder: (context, child) {
        final action = _actions[index];

        // 简单的垂直展开 - 往上展开
        final double spacing = 70; // 按钮间距
        final double offsetY = (index + 1) * spacing * _expandAnimation.value;
        
        // 获取屏幕尺寸进行边界检查
        final screenHeight = MediaQuery.of(context).size.height;
        
        // 计算最终位置 - 从右下角往上展开
        double finalBottom = 30 + offsetY;
        
        // 边界检查 - 确保不会超出屏幕顶部
        final maxBottom = screenHeight - 120; // 避免与顶部导航栏重叠
        finalBottom = finalBottom.clamp(30.0, maxBottom);

        return Positioned(
          bottom: finalBottom,
          right: 20, // 保持与主FAB同一垂直线
          child: Transform.scale(
            scale: _expandAnimation.value.clamp(0.0, 1.0),
            child: Opacity(
              opacity: _expandAnimation.value.clamp(0.0, 1.0),
              child: _buildActionButton(action, index),
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionButton(ActionButtonConfig action, int index) {
    return GestureDetector(
      onTap: () => _onActionTapped(action.action),
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          gradient: action.isHighlighted
              ? const LinearGradient(
                  colors: [
                    Color(0xFFFF6B35),
                    Color(0xFFFF4757),
                    Color(0xFFE91E63),
                    Color(0xFF9C27B0),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: action.isHighlighted ? null : action.color,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: (action.isHighlighted 
                  ? const Color(0xFFFF4757) 
                  : Colors.black).withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              action.icon,
              color: Colors.white,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class ActionButtonConfig {
  final IconData icon;
  final String label;
  final String action;
  final Color color;
  final bool isHighlighted;

  const ActionButtonConfig({
    required this.icon,
    required this.label,
    required this.action,
    this.color = const Color(0xFF2F2F2F),
    this.isHighlighted = false,
  });
}
