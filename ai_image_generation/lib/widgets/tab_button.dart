import 'package:flutter/material.dart';

class TabButton extends StatelessWidget {
  final String text;
  final bool isSelected;
  final VoidCallback? onTap;

  const TabButton({
    super.key,
    required this.text,
    required this.isSelected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: isSelected 
            ? null 
            : Border.all(color: Colors.white24, width: 1),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white,
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

class TabGroup extends StatelessWidget {
  final List<String> tabs;
  final int selectedIndex;
  final Function(int)? onTabChanged;

  const TabGroup({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ...List.generate(tabs.length, (index) {
          return Padding(
            padding: EdgeInsets.only(right: index < tabs.length - 1 ? 10 : 0),
            child: TabButton(
              text: tabs[index],
              isSelected: selectedIndex == index,
              onTap: () => onTabChanged?.call(index),
            ),
          );
        }),
        const Spacer(),
        _buildGridViewButton(),
      ],
    );
  }

  Widget _buildGridViewButton() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF2F2F2F),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(
        Icons.grid_view,
        color: Colors.white,
        size: 20,
      ),
    );
  }
}
