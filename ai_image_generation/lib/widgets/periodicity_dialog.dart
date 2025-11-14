import 'package:flutter/material.dart';
import '../models/subscription_plan.dart';

class PeriodicityDialog extends StatelessWidget {
  final SubscriptionPlan currentPlan;
  final PricingPeriod selectedPeriod;
  final Function(PricingPeriod) onPeriodSelected;

  const PeriodicityDialog({
    super.key,
    required this.currentPlan,
    required this.selectedPeriod,
    required this.onPeriodSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 顶部指示器
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // 标题和关闭按钮
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Periodicity',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.black54,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 选项列表
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  // Weekly选项
                  _buildPeriodOption(
                    period: PricingPeriod.weekly,
                    pricing: currentPlan.pricing[PricingPeriod.weekly]!,
                  ),

                  const SizedBox(height: 12),

                  // Yearly选项
                  _buildPeriodOption(
                    period: PricingPeriod.yearly,
                    pricing: currentPlan.pricing[PricingPeriod.yearly]!,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodOption({
    required PricingPeriod period,
    required PlanPricing pricing,
  }) {
    final isSelected = period == selectedPeriod;
    final isYearly = period == PricingPeriod.yearly;

    return GestureDetector(
      onTap: () => onPeriodSelected(period),
      child: Container(
        // 为折扣标签预留空间
        margin: isYearly ? const EdgeInsets.only(top: 8, right: 8) : EdgeInsets.zero,
        child: Stack(
          clipBehavior: Clip.none, // 允许子组件超出边界显示
          children: [
            // 主容器
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isSelected ? Colors.black : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? Colors.black : Colors.grey.shade200,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  // 左侧内容
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 周期和价格
                        Row(
                          children: [
                            Text(
                              pricing.periodText,
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.black,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '| ${pricing.priceText}',
                              style: TextStyle(
                                color: isSelected ? Colors.white70 : Colors.black54,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),

                        // 年度选项的周等价价格
                        if (isYearly) ...[
                          const SizedBox(height: 4),
                          Text(
                            pricing.weeklyEquivalentText,
                            style: TextStyle(
                              color: isSelected ? Colors.white70 : Colors.black54,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // 右侧价格显示
                  Text(
                    pricing.weeklyEquivalentText,
                    style: TextStyle(
                      color: isSelected ? Colors.white70 : Colors.black54,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            // 折扣标签（仅年度选项）
            if (isYearly && pricing.discountPercentage != null)
              Positioned(
                top: -4,
                right: -4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50), // 绿色
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 3,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Text(
                    '${pricing.discountPercentage}% OFF',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
