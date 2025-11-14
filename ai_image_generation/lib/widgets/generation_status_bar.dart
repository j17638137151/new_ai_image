import 'package:flutter/material.dart';
import '../services/generation_service.dart';

class GenerationStatusBar extends StatelessWidget {
  final VoidCallback? onTap;
  final GenerationService generationService;

  const GenerationStatusBar({
    super.key,
    this.onTap,
    required this.generationService,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: generationService,
      builder: (context, child) {
        // 如果没有活跃任务，不显示状态栏
        if (!generationService.hasActiveTask && !generationService.hasCompletedTask) {
          return const SizedBox.shrink();
        }

        return AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOutCubic,
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _getBackgroundColor(),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // 左侧图标和头像
                  _buildLeftSection(),
                  
                  const SizedBox(width: 12),
                  
                  // 中间文本内容
                  Expanded(
                    child: _buildTextContent(),
                  ),
                  
                  // 右侧箭头
                  if (generationService.hasCompletedTask)
                    const Icon(
                      Icons.chevron_right,
                      color: Colors.black54,
                      size: 20,
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Color _getBackgroundColor() {
    switch (generationService.status) {
      case GenerationStatus.generating:
        return Colors.grey.withValues(alpha: 0.8); // 灰色半透明
      case GenerationStatus.completed:
        return const Color(0xFFFFB6C1).withValues(alpha: 0.9); // 粉色
      default:
        return Colors.transparent;
    }
  }

  Widget _buildLeftSection() {
    return SizedBox(
      width: 60,
      height: 40,
      child: Stack(
        children: [
          // 主头像
          Positioned(
            left: 0,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.network(
                  'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=100&h=100&fit=crop&crop=face',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey.shade300,
                      child: const Icon(Icons.person, size: 16),
                    );
                  },
                ),
              ),
            ),
          ),
          
          // 副头像
          Positioned(
            left: 20,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.network(
                  'https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?w=100&h=100&fit=crop&crop=face',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey.shade300,
                      child: const Icon(Icons.person, size: 16),
                    );
                  },
                ),
              ),
            ),
          ),
          
          // 第三个小头像 (仅在生成中显示)
          if (generationService.status == GenerationStatus.generating)
            Positioned(
              left: 40,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4.5),
                  child: Image.network(
                    'https://images.unsplash.com/photo-1494790108755-2616c96afe86?w=100&h=100&fit=crop&crop=face',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey.shade300,
                        child: const Icon(Icons.person, size: 10),
                      );
                    },
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTextContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 任务类型标签
        Text(
          generationService.getTaskTypeDisplay(),
          style: const TextStyle(
            color: Colors.black45,
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        
        const SizedBox(height: 2),
        
        // 主要文案
        Text(
          generationService.getProgressText(),
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        
        // 副文案
        if (generationService.getSubtitleText().isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            generationService.getSubtitleText(),
            style: const TextStyle(
              color: Colors.black54,
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }
}
