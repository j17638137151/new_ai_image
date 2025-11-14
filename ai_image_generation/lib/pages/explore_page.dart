import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../models/explore_item_model.dart';
import '../widgets/explore_card.dart';
import 'explore_detail_page.dart';

class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key});

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  late List<ExploreItemModel> _items;
  int _selectedCategoryIndex = 0;

  final List<String> _categories = [
    '发现',
    '🔥热门',
    '人像写真', 
    '风景',
    '动漫',
    '艺术创作',
    '滤镜特效',
  ];

  @override
  void initState() {
    super.initState();
    _items = ExploreItemModel.getMockData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: Column(
          children: [
            // 顶部导航栏
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: const Row(
                children: [
                  Text(
                    '探索',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            
            // 分类标签栏
            Container(
              height: 50,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final isSelected = index == _selectedCategoryIndex;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedCategoryIndex = index;
                      });
                      _onCategoryChanged(index);
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected 
                            ? const Color(0xFFFF4757)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                        border: !isSelected ? Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                          width: 1,
                        ) : null,
                      ),
                      child: Text(
                        _categories[index],
                        style: TextStyle(
                          color: isSelected 
                              ? Colors.white 
                              : Colors.white.withValues(alpha: 0.7),
                          fontSize: 14,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            
            // 瀑布流内容区域
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: MasonryGridView.count(
                  crossAxisCount: 2, // 两列
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  itemCount: _items.length,
                  itemBuilder: (context, index) {
                    final item = _items[index];
                    return ExploreCard(
                      item: item,
                      onTap: () => _onCardTap(item),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onCategoryChanged(int categoryIndex) {
    // TODO: 根据分类筛选内容
    debugPrint('切换到分类: ${_categories[categoryIndex]}');
    
    // 这里可以根据分类来筛选_items
    // 暂时只是切换显示状态，不显示提示
  }

  void _onCardTap(ExploreItemModel item) {
    // 跳转到详情页面
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ExploreDetailPage(item: item),
      ),
    );
  }
}
