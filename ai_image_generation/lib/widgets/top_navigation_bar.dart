import 'package:flutter/material.dart';
import '../pages/pro_page.dart';
import '../pages/settings_page.dart';

class TopNavigationBar extends StatelessWidget {
  const TopNavigationBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left side - App name
          Text('Remini', style: Theme.of(context).textTheme.headlineLarge),

          // Right side - Pro, Settings, Avatar
          Row(
            children: [
              // PRO button
              _buildProButton(context),

              const SizedBox(width: 15),

              // Settings icon
              _buildSettingsButton(context),

              const SizedBox(width: 15),

              // Avatar
              _buildAvatar(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const ProPage(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              // 底部滑入动画
              const begin = Offset(0.0, 1.0);
              const end = Offset.zero;
              const curve = Curves.easeInOutCubic;

              var tween = Tween(begin: begin, end: end).chain(
                CurveTween(curve: curve),
              );

              return SlideTransition(
                position: animation.drive(tween),
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 400),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          'PRO',
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const SettingsPage(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              // 底部滑入动画
              const begin = Offset(0.0, 1.0);
              const end = Offset.zero;
              const curve = Curves.easeInOutCubic;

              var tween = Tween(begin: begin, end: end).chain(
                CurveTween(curve: curve),
              );

              return SlideTransition(
                position: animation.drive(tween),
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 400),
          ),
        );
      },
      child: const Icon(Icons.settings_outlined, color: Colors.white, size: 24),
    );
  }

  Widget _buildAvatar() {
    return GestureDetector(
      onTap: () {
        // TODO: 导航到用户资料页面
      },
      child: const CircleAvatar(
        radius: 16,
        backgroundColor: Colors.orange,
        child: Icon(Icons.person, color: Colors.white, size: 18),
      ),
    );
  }
}
