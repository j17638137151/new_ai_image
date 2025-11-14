import 'package:flutter/material.dart';

enum PlanType {
  pro,
  lite,
}

enum PricingPeriod {
  weekly,
  yearly,
}

class SubscriptionPlan {
  final PlanType type;
  final String title;
  final String description;
  final String heroImageUrl;
  final List<Color> gradientColors;
  final Map<PricingPeriod, PlanPricing> pricing;

  SubscriptionPlan({
    required this.type,
    required this.title,
    required this.description,
    required this.heroImageUrl,
    required this.gradientColors,
    required this.pricing,
  });

  static List<SubscriptionPlan> getPlans() {
    return [
      // Lite Plan (放在前面)
      SubscriptionPlan(
        type: PlanType.lite,
        title: 'Lite',
        description: 'Unlock only photo\nenhancement. No\nadditional tools, no video\nand no Desktop access.',
        heroImageUrl: 'https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?w=200&h=200&fit=crop&crop=face',
        gradientColors: [
          const Color(0xFF9C27B0), // 紫色
          const Color(0xFF7B1FA2), // 深紫色
          const Color(0xFF6A1B9A), // 更深紫色
        ],
        pricing: {
          PricingPeriod.weekly: PlanPricing(
            period: PricingPeriod.weekly,
            price: 38.00,
            renewalText: 'Renews at ¥38.00/week. Cancel anytime.',
            freeTrialPrices: [0.00, 38.00],
          ),
          PricingPeriod.yearly: PlanPricing(
            period: PricingPeriod.yearly,
            price: 228.00,
            weeklyEquivalent: 4.38,
            discountPercentage: 89,
            renewalText: 'Renews at ¥228.00/year. Cancel anytime.',
          ),
        },
      ),

      // Pro Plan (放在后面)
      SubscriptionPlan(
        type: PlanType.pro,
        title: 'Pro',
        description: 'Unlock all our features,\nboth on Mobile and on\nDesktop.',
        heroImageUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200&h=200&fit=crop&crop=face',
        gradientColors: [
          const Color(0xFFFF8A65), // 橙色
          const Color(0xFFFF7043), // 深橙色  
          const Color(0xFFEC407A), // 粉色
        ],
        pricing: {
          PricingPeriod.weekly: PlanPricing(
            period: PricingPeriod.weekly,
            price: 68.00,
            renewalText: 'Renews at ¥68.00/week. Cancel anytime.',
            freeTrialPrices: [0.00, 8.00, 68.00],
          ),
          PricingPeriod.yearly: PlanPricing(
            period: PricingPeriod.yearly,
            price: 598.00,
            weeklyEquivalent: 11.50,
            discountPercentage: 84,
            renewalText: 'Renews at ¥598.00/year. Cancel anytime.',
          ),
        },
      ),
    ];
  }
}

class PlanPricing {
  final PricingPeriod period;
  final double price;
  final double? weeklyEquivalent; // 年付时显示的周等价价格
  final int? discountPercentage; // 折扣百分比
  final String renewalText;
  final List<double>? freeTrialPrices; // 免费试用期的价格选项

  PlanPricing({
    required this.period,
    required this.price,
    this.weeklyEquivalent,
    this.discountPercentage,
    required this.renewalText,
    this.freeTrialPrices,
  });

  String get periodText {
    switch (period) {
      case PricingPeriod.weekly:
        return 'Weekly';
      case PricingPeriod.yearly:
        return 'Yearly';
    }
  }

  String get priceText {
    return '¥${price.toStringAsFixed(2)}';
  }

  String get weeklyEquivalentText {
    if (weeklyEquivalent != null) {
      return 'only ¥${weeklyEquivalent!.toStringAsFixed(2)}/week';
    }
    return '¥${price.toStringAsFixed(2)}/week';
  }
}
