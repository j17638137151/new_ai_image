import 'package:flutter/material.dart';
import 'home_page.dart';
import 'explore_page.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0; // 默认选中探索页面

  final List<Widget> _pages = [
    const ExplorePage(), // 探索页面
    const HomePage(),    // AI美化页面（原首页）
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          border: Border(
            top: BorderSide(
              color: Colors.white.withValues(alpha: 0.15),
              width: 0.5,
            ),
          ),
        ),
        child: SafeArea(
          child: Container(
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                _buildTabItem(
                  icon: Icons.explore_outlined,
                  activeIcon: Icons.explore,
                  label: '探索',
                  index: 0,
                ),
                _buildTabItem(
                  icon: Icons.auto_fix_high_outlined,
                  activeIcon: Icons.auto_fix_high,
                  label: 'AI美化',
                  index: 1,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
  }) {
    final isActive = _currentIndex == index;
    
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _currentIndex = index;
          });
        },
        behavior: HitTestBehavior.opaque,
        child: Container(
          height: 60,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  isActive ? activeIcon : icon,
                  color: isActive 
                      ? const Color(0xFFFF4757) 
                      : Colors.white.withValues(alpha: 0.6),
                  size: 24,
                ),
              ),
              const SizedBox(height: 4),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  color: isActive 
                      ? const Color(0xFFFF4757) 
                      : Colors.white.withValues(alpha: 0.6),
                  fontSize: 12,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                ),
                child: Text(label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
