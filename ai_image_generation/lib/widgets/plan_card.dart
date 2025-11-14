import 'package:flutter/material.dart';
import '../models/subscription_plan.dart';

class PlanCard extends StatelessWidget {
  final SubscriptionPlan plan;
  final PricingPeriod selectedPeriod;
  final bool isSelected;
  final VoidCallback? onPeriodTap;

  const PlanCard({
    super.key,
    required this.plan,
    required this.selectedPeriod,
    this.isSelected = false,
    this.onPeriodTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: plan.gradientColors,
        ),
        boxShadow: [
          BoxShadow(
            color: plan.gradientColors.first.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // 主要内容
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // 左侧文本内容
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 标题
                      Text(
                        plan.title,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 8),

                      // 描述
                      Text(
                        plan.description,
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 14,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),

                // 右侧头像区域
                Expanded(
                  flex: 1,
                  child: Column(
                    children: [
                      // 头像
                      Container(
                        width: 80,
                        height: 100,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            plan.heroImageUrl,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                color: Colors.black.withValues(alpha: 0.1),
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.black54),
                                  ),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.black.withValues(alpha: 0.1),
                                child: const Icon(
                                  Icons.person,
                                  color: Colors.black54,
                                  size: 32,
                                ),
                              );
                            },
                          ),
                        ),
                      ),

                      const Spacer(),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 右下角周期选择器
          Positioned(
            bottom: 16,
            right: 16,
            child: GestureDetector(
              onTap: onPeriodTap,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _getPeriodDisplayText(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.keyboard_arrow_down,
                      color: Colors.white,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getPeriodDisplayText() {
    switch (selectedPeriod) {
      case PricingPeriod.weekly:
        return 'Weekly';
      case PricingPeriod.yearly:
        return 'Yearly';
    }
  }
}
