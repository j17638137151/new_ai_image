import 'package:flutter/material.dart';
import '../models/explore_item_model.dart';
import '../models/comment_model.dart';
import 'create_similar_page.dart';

class ExploreDetailPage extends StatefulWidget {
  final ExploreItemModel item;

  const ExploreDetailPage({
    super.key,
    required this.item,
  });

  @override
  State<ExploreDetailPage> createState() => _ExploreDetailPageState();
}

class _ExploreDetailPageState extends State<ExploreDetailPage> {
  late List<CommentModel> _comments;
  late bool _isLiked;
  late bool _isFollowed;
  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _comments = CommentModel.getMockComments();
    _isLiked = false;
    _isFollowed = widget.item.isFollowed;
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: GestureDetector(
        onTap: () {
          // 点击空白区域收起键盘
          FocusScope.of(context).unfocus();
        },
        child: Stack(
          children: [
            // 主要内容
            CustomScrollView(
            slivers: [
              // 大图展示
              SliverAppBar(
                expandedHeight: MediaQuery.of(context).size.height * 0.6,
                pinned: true,
                backgroundColor: Colors.transparent,
                leading: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
                actions: [
                  IconButton(
                    onPressed: _onShare,
                    icon: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.share,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: _buildMainImage(),
                ),
              ),

              // 内容区域
              SliverToBoxAdapter(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFF0A0A0A),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 作者信息栏
                      _buildAuthorSection(),
                      
                      // 创作信息
                      _buildCreationInfo(),
                      
                      // 使用统计
                      _buildUsageStats(),
                      
                      // 评论区域
                      _buildCommentsSection(),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // 底部操作栏
          _buildBottomActionBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildMainImage() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.black26,
          ],
        ),
      ),
      child: widget.item.imageUrl.startsWith('assets/')
          ? Image.asset(
              widget.item.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return _buildImagePlaceholder();
              },
            )
          : Image.network(
              widget.item.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return _buildImagePlaceholder();
              },
            ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: const Color(0xFF2F2F2F),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_outlined,
            size: 80,
            color: Colors.white.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            widget.item.name,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 18,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAuthorSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          // 作者头像
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF404040),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.person,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          
          // 作者信息
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.item.authorName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '（手机摄影）',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          
          // 关注按钮
          GestureDetector(
            onTap: _toggleFollow,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _isFollowed ? const Color(0xFF404040) : const Color(0xFFFF4757),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                _isFollowed ? '已关注' : '关注',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreationInfo() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 创作信息标签
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF2F2F2F),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.auto_awesome,
                      color: Colors.amber,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      '创作信息',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // 描述文本
          Text(
            widget.item.description,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsageStats() {
    return Container(
      margin: const EdgeInsets.all(20),
      child: Text(
        '${_formatDate(widget.item.createdAt)} ${widget.item.useCount}次使用',
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.6),
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _buildCommentsSection() {
    return Container(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 评论标题
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              '评论 ${widget.item.commentCount}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // 评论输入框
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF2F2F2F),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFF404040),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.person,
                    color: Colors.white.withValues(alpha: 0.6),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: '说点什么...',
                      hintStyle: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 14,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // 评论列表
          ..._comments.map((comment) => _buildCommentItem(comment)),
          
          const SizedBox(height: 100), // 底部间距，避免被操作栏遮挡
        ],
      ),
    );
  }

  Widget _buildCommentItem(CommentModel comment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 用户头像
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF404040),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(
              Icons.person,
              color: Colors.white.withValues(alpha: 0.6),
              size: 20,
            ),
          ),
          
          const SizedBox(width: 12),
          
          // 评论内容
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 用户名和时间
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        comment.userName,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Text(
                      _formatDate(comment.createdAt),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 4),
                
                // 评论文本
                if (comment.content.isNotEmpty)
                  Text(
                    comment.content,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                
                // 评论图片
                if (comment.imageUrl != null) ...[
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 120,
                      height: 120,
                      color: const Color(0xFF2F2F2F),
                      child: comment.imageUrl!.startsWith('assets/')
                          ? Image.asset(
                              comment.imageUrl!,
                              fit: BoxFit.cover,
                            )
                          : Image.network(
                              comment.imageUrl!,
                              fit: BoxFit.cover,
                            ),
                    ),
                  ),
                ],
                
                const SizedBox(height: 8),
                
                // 查看作品详情按钮
                if (comment.imageUrl != null)
                  GestureDetector(
                    onTap: () {
                      // TODO: 查看作品详情
                    },
                    child: Text(
                      '查看作品详情 >',
                      style: TextStyle(
                        color: Colors.blue.withValues(alpha: 0.8),
                        fontSize: 13,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          // 点赞按钮
          GestureDetector(
            onTap: () {
              // TODO: 点赞评论
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    comment.isLiked ? Icons.favorite : Icons.favorite_border,
                    color: comment.isLiked 
                        ? const Color(0xFFFF4757) 
                        : Colors.white.withValues(alpha: 0.6),
                    size: 18,
                  ),
                  if (comment.likeCount > 0) ...[
                    const SizedBox(width: 4),
                    Text(
                      comment.likeCount.toString(),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActionBar() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 16,
          bottom: MediaQuery.of(context).padding.bottom + 16,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          border: Border(
            top: BorderSide(
              color: Colors.white.withValues(alpha: 0.15),
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          children: [
            // 点赞按钮
            GestureDetector(
              onTap: _toggleLike,
              child: Container(
                padding: const EdgeInsets.all(12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _isLiked ? Icons.favorite : Icons.favorite_border,
                      color: _isLiked ? const Color(0xFFFF4757) : Colors.white,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.item.likeCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(width: 20),
            
            // 做同款按钮
            Expanded(
              child: GestureDetector(
                onTap: _createSimilar,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Text(
                    '做同款',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleLike() {
    setState(() {
      _isLiked = !_isLiked;
    });
  }

  void _toggleFollow() {
    setState(() {
      _isFollowed = !_isFollowed;
    });
  }

  void _onShare() {
    // TODO: 分享功能
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('分享功能开发中...'),
        backgroundColor: Color(0xFF2F2F2F),
      ),
    );
  }

  void _createSimilar() {
    // 跳转到做同款页面
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateSimilarPage(originalItem: widget.item),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}天前';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}小时前';
    } else {
      return '刚刚';
    }
  }
}
