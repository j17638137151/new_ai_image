class CommentModel {
  final String id;
  final String userId;
  final String userName;
  final String userAvatar;
  final String content;
  final DateTime createdAt;
  final int likeCount;
  final bool isLiked;
  final String? imageUrl; // 评论可能包含图片

  CommentModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userAvatar,
    required this.content,
    required this.createdAt,
    this.likeCount = 0,
    this.isLiked = false,
    this.imageUrl,
  });

  // 静态假数据
  static List<CommentModel> getMockComments() {
    return [
      CommentModel(
        id: '1',
        userId: '101',
        userName: '用户7015318543017',
        userAvatar: 'assets/images/demo/avatar_1.jpg',
        content: '回复',
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
        likeCount: 1,
        imageUrl: 'assets/images/demo/processed_demo.jpg',
      ),
      CommentModel(
        id: '2',
        userId: '102',
        userName: '用户7652680608505',
        userAvatar: 'assets/images/demo/avatar_2.jpg',
        content: '7红foot红色战甲金蝉金蟮山传红山\n成红色战甲山成红色战甲\n15911819492846346\nPUBUBDMofijgnhbfeOOo·心心\n(fhtvhcfih)',
        createdAt: DateTime.now().subtract(const Duration(days: 8)),
        likeCount: 0,
      ),
      CommentModel(
        id: '3',
        userId: '103',
        userName: 'AI创作爱好者',
        userAvatar: 'assets/images/demo/avatar_3.jpg',
        content: '这个机器人的细节做得太棒了！请问用了什么参数？',
        createdAt: DateTime.now().subtract(const Duration(hours: 5)),
        likeCount: 3,
      ),
    ];
  }
}
