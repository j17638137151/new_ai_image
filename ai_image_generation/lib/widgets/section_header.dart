import 'package:flutter/material.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final String emoji;
  final bool showSeeAll;
  final VoidCallback? onSeeAllPressed;

  const SectionHeader({
    super.key,
    required this.title,
    required this.emoji,
    this.showSeeAll = true,
    this.onSeeAllPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildTitleSection(context),
          if (showSeeAll) _buildSeeAllButton(),
        ],
      ),
    );
  }

  Widget _buildTitleSection(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontSize: 20,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          emoji,
          style: const TextStyle(fontSize: 20),
        ),
      ],
    );
  }

  Widget _buildSeeAllButton() {
    return GestureDetector(
      onTap: onSeeAllPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF2F2F2F),
          borderRadius: BorderRadius.circular(15),
        ),
        child: const Text(
          'See All',
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
