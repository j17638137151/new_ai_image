import 'package:flutter/material.dart';
import '../models/subscription_plan.dart';
import '../widgets/plan_card.dart';
import '../widgets/free_trial_card.dart';
import '../widgets/price_selector.dart';
import '../widgets/periodicity_dialog.dart';

class ProPage extends StatefulWidget {
  const ProPage({super.key});

  @override
  State<ProPage> createState() => _ProPageState();
}

class _ProPageState extends State<ProPage> {
  late PageController _pageController;
  late List<SubscriptionPlan> _plans;
  int _currentPlanIndex = 0;
  PricingPeriod _selectedPeriod = PricingPeriod.weekly;
  double _selectedFreeTrialPrice = 0.00;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _plans = SubscriptionPlan.getPlans();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  SubscriptionPlan get currentPlan => _plans[_currentPlanIndex];
  PlanPricing get currentPricing => currentPlan.pricing[_selectedPeriod]!;

  void _onPlanChanged(int index) {
    setState(() {
      _currentPlanIndex = index;
      // 重置选择的免费试用价格为第一个选项
      _selectedFreeTrialPrice = currentPricing.freeTrialPrices?.first ?? 0.00;
    });
  }

  void _onPeriodChanged(PricingPeriod period) {
    setState(() {
      _selectedPeriod = period;
      // 重置选择的免费试用价格
      _selectedFreeTrialPrice = currentPlan.pricing[period]!.freeTrialPrices?.first ?? 0.00;
    });
  }

  void _showPeriodSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => PeriodicityDialog(
        currentPlan: currentPlan,
        selectedPeriod: _selectedPeriod,
        onPeriodSelected: (period) {
          _onPeriodChanged(period);
          Navigator.pop(context);
        },
      ),
    );
  }

  void _onFreeTrialPriceChanged(double price) {
    setState(() {
      _selectedFreeTrialPrice = price;
    });
  }

  void _onTryForFree() {
    // TODO: 处理免费试用逻辑
    debugPrint('开始免费试用: ${currentPlan.title}, 周期: ${_selectedPeriod.name}, 价格: $_selectedFreeTrialPrice');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5), // 浅灰色背景
      body: SafeArea(
        child: Column(
          children: [
            // 顶部导航栏
            _buildTopNavigationBar(),

            // 主要内容区域
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 20),

                    // 套餐卡片轮播
                    _buildPlanCarousel(),

                    const SizedBox(height: 30),

                    // 免费试用促销卡片
                    FreeTrialCard(),

                    const SizedBox(height: 20),

                    // 价格选择器
                    if (currentPricing.freeTrialPrices != null)
                      PriceSelector(
                        prices: currentPricing.freeTrialPrices!,
                        selectedPrice: _selectedFreeTrialPrice,
                        onPriceChanged: _onFreeTrialPriceChanged,
                      ),

                    const SizedBox(height: 20),

                    // 试用按钮
                    _buildTryForFreeButton(),

                    const SizedBox(height: 12),

                    // 续费说明
                    _buildRenewalText(),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopNavigationBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: Row(
        children: [
          // 左侧关闭按钮
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.close,
                color: Colors.black54,
                size: 20,
              ),
            ),
          ),

          // 中间标题
          const Expanded(
            child: Text(
              'Restore Purchases',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.black87,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          // 右侧空白区域（保持布局平衡）
          const SizedBox(width: 32),
        ],
      ),
    );
  }

  Widget _buildPlanCarousel() {
    return SizedBox(
      height: 180,
      child: PageView.builder(
        controller: _pageController,
        onPageChanged: _onPlanChanged,
        itemCount: _plans.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: PlanCard(
              plan: _plans[index],
              selectedPeriod: _selectedPeriod,
              isSelected: index == _currentPlanIndex,
              onPeriodTap: _showPeriodSelector,
            ),
          );
        },
      ),
    );
  }

  Widget _buildTryForFreeButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: _onTryForFree,
        child: Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(28),
          ),
          child: const Center(
            child: Text(
              'Try For Free',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRenewalText() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Text(
        currentPricing.renewalText,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.black54,
          fontSize: 13,
          height: 1.4,
        ),
      ),
    );
  }
}
