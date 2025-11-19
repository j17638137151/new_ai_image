import 'package:flutter/material.dart';

import '../services/generation_history_api_service.dart';
import '../widgets/image_detail_dialog.dart';

class GenerationHistoryPage extends StatefulWidget {
  const GenerationHistoryPage({super.key});

  @override
  State<GenerationHistoryPage> createState() => _GenerationHistoryPageState();
}

class _GenerationHistoryPageState extends State<GenerationHistoryPage> {
  final List<GenerationHistoryItem> _items = [];
  final ScrollController _scrollController = ScrollController();

  int _currentPage = 1;
  final int _pageSize = 20;
  bool _isLoading = false;
  bool _hasMore = true;
  bool _initialLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadInitial();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadInitial() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final result = await GenerationHistoryApiService.listHistory(
        page: 1,
        pageSize: _pageSize,
      );
      setState(() {
        _items
          ..clear()
          ..addAll(result.items);
        _currentPage = 1;
        _hasMore = result.hasMore;
        _initialLoaded = true;
      });
    } catch (e) {
      debugPrint('加载历史失败: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadMore() async {
    if (_isLoading || !_hasMore) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final nextPage = _currentPage + 1;
      final result = await GenerationHistoryApiService.listHistory(
        page: nextPage,
        pageSize: _pageSize,
      );
      setState(() {
        _items.addAll(result.items);
        _currentPage = nextPage;
        _hasMore = result.hasMore;
      });
    } catch (e) {
      debugPrint('加载更多历史失败: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _onScroll() {
    if (!_hasMore || _isLoading) return;
    if (!_scrollController.hasClients) return;

    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  String _getHistoryTitle(String type) {
    switch (type) {
      case 'photobooth':
        return '写真生成';
      case 'enhance':
        return '高清修复';
      case 'filter':
        return '滤镜效果';
      case 'photoshoot':
        return '写真拍摄';
      case 'create_similar':
        return '做同款';
      default:
        return 'AI生成';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(title: const Text('全部生成历史'), centerTitle: true),
      body: RefreshIndicator(onRefresh: _loadInitial, child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (!_initialLoaded && _isLoading) {
      return ListView(
        children: const [
          SizedBox(height: 120),
          Center(child: CircularProgressIndicator()),
        ],
      );
    }

    if (_items.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 80),
          Center(
            child: Text(
              '暂无生成记录',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: _items.length + 1,
      itemBuilder: (context, index) {
        if (index == _items.length) {
          if (!_hasMore) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  '已经到底了',
                  style: TextStyle(color: Colors.white38, fontSize: 12),
                ),
              ),
            );
          }
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const SizedBox.shrink(),
            ),
          );
        }

        final item = _items[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: GestureDetector(
            onTap: () {
              showDialog(
                context: context,
                builder: (context) {
                  return ImageDetailDialog(
                    imageUrl: item.imageUrl,
                    title: _getHistoryTitle(item.type),
                    description: item.prompt,
                  );
                },
              );
            },
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF151515),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 100,
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: AspectRatio(
                          aspectRatio: 3 / 4,
                          child: Image.network(
                            item.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey[850],
                                child: const Center(
                                  child: Icon(
                                    Icons.broken_image,
                                    color: Colors.white54,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(
                        top: 12,
                        right: 12,
                        bottom: 12,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getHistoryTitle(item.type),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          if (item.prompt != null && item.prompt!.isNotEmpty)
                            Text(
                              item.prompt!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          const SizedBox(height: 8),
                          Text(
                            item.createdAt.toLocal().toString(),
                            style: const TextStyle(
                              color: Colors.white38,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
