import 'package:flutter/material.dart';

class PriceSelector extends StatelessWidget {
  final List<double> prices;
  final double selectedPrice;
  final Function(double) onPriceChanged;

  const PriceSelector({
    super.key,
    required this.prices,
    required this.selectedPrice,
    required this.onPriceChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          for (int i = 0; i < prices.length; i++) ...[
            Expanded(
              child: _buildPriceOption(prices[i], i == 0),
            ),
            if (i < prices.length - 1) const SizedBox(width: 12),
          ],
        ],
      ),
    );
  }

  Widget _buildPriceOption(double price, bool isMostPopular) {
    final isSelected = price == selectedPrice;
    
    return GestureDetector(
      onTap: () => onPriceChanged(price),
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.black : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Stack(
          children: [
            // 主要内容
            Center(
              child: Text(
                '¥${price.toStringAsFixed(2)}',
                style: TextStyle(
                  color: isSelected ? Colors.black : Colors.black54,
                  fontSize: 18,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                ),
              ),
            ),

            // "MOST POPULAR" 标签
            if (isMostPopular)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFF4757), // 红色
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(15),
                      topRight: Radius.circular(15),
                    ),
                  ),
                  child: const Text(
                    'MOST POPULAR',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
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
