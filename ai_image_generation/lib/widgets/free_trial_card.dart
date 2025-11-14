import 'package:flutter/material.dart';

class FreeTrialCard extends StatelessWidget {
  const FreeTrialCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题和图标
          Row(
            children: [
              // 标题
              const Expanded(
                child: Text(
                  'We\'re offering a free\nweek of AI 👑',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                  ),
                ),
              ),

              // 右侧礼品盒图标
              _buildGiftIcon(),
            ],
          ),

          const SizedBox(height: 16),

          // 描述文本
          const Text(
            'We\'d love for everyone to experience the magic of Remini, no matter their budget. So for your first week of generating AI photos, you\'re free to pick the price.',
            style: TextStyle(
              color: Colors.black54,
              fontSize: 14,
              height: 1.5,
            ),
          ),

          const SizedBox(height: 20),

          // 价格选择标题
          const Text(
            'Which amount feels right for you? 🎁',
            style: TextStyle(
              color: Colors.black,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGiftIcon() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          // 主礼品盒
          Positioned(
            right: 8,
            bottom: 8,
            child: Container(
              width: 32,
              height: 24,
              decoration: BoxDecoration(
                color: const Color(0xFFFF7043), // 橙色
                borderRadius: BorderRadius.circular(4),
              ),
              child: Stack(
                children: [
                  // 礼品盒顶部装饰带
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 6,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD32F2F), // 红色装饰带
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(4),
                          topRight: Radius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  // 中间的垂直装饰带
                  Positioned(
                    top: 0,
                    bottom: 0,
                    left: 13,
                    child: Container(
                      width: 6,
                      color: const Color(0xFFD32F2F), // 红色装饰带
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 辅助装饰元素
          Positioned(
            left: 4,
            top: 4,
            child: Container(
              width: 16,
              height: 12,
              decoration: BoxDecoration(
                color: const Color(0xFFFFAB91).withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // 右上角小装饰
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              width: 12,
              height: 10,
              decoration: BoxDecoration(
                color: const Color(0xFFFFCC02).withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
