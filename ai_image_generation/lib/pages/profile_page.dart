import 'package:flutter/material.dart';

import '../services/auth_state.dart';
import '../services/generation_history_api_service.dart';
import '../services/user_stats_service.dart';
import '../widgets/image_detail_dialog.dart';
import 'generation_history_page.dart';
import 'edit_profile_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  void initState() {
    super.initState();
    // 自动刷新用户资料
    _refreshProfile();
  }

  Future<void> _refreshProfile() async {
    if (AuthState.instance.isLoggedIn) {
      await AuthState.instance.refreshProfile();
      if (mounted) {
        setState(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = AuthState.instance.currentUser;
    final isLoggedIn = user != null;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(title: const Text('个人中心'), centerTitle: true),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildUserHeaderCard(theme, isLoggedIn, user),
              const SizedBox(height: 20),
              _buildHistorySection(context, theme, isLoggedIn),
              const SizedBox(height: 24),
              _buildSettingsSection(theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyHistoryPlaceholder() {
    return Center(
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(top: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF151515),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFF222222),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.history, color: Colors.white70, size: 18),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '暂无生成记录',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '去首页尝试生成你的第一张照片吧～',
                    style: TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getDisplayName(dynamic user) {
    if (user.phone != null && user.phone.isNotEmpty) {
      // 隐藏手机号中间4位
      final phone = user.phone as String;
      if (phone.length >= 11) {
        return '${phone.substring(0, 3)}****${phone.substring(7)}';
      }
      return phone;
    }
    if (user.email != null && user.email.isNotEmpty) {
      return user.email;
    }
    return '用户 ${user.userId.substring(0, 8)}';
  }

  Widget _buildUserHeaderCard(ThemeData theme, bool isLoggedIn, dynamic user) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF151515),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 头像
              CircleAvatar(
                radius: 26,
                backgroundColor: Colors.orange,
                backgroundImage: (isLoggedIn && user.avatarUrl != null)
                    ? NetworkImage(user.avatarUrl!)
                    : null,
                child: (isLoggedIn && user.avatarUrl != null)
                    ? null
                    : const Icon(Icons.person, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isLoggedIn
                          ? (user.nickname ?? _getDisplayName(user))
                          : '未登录用户',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isLoggedIn ? (user.bio ?? '暂无个人简介') : '登录后可同步生成记录和个人数据',
                      style: theme.textTheme.bodyMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 真实统计数据
          FutureBuilder<UserStats>(
            future: isLoggedIn ? UserStatsService.getStats() : null,
            builder: (context, snapshot) {
              if (!isLoggedIn) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    _UserStatItem(label: '今日生成', value: '-'),
                    _UserStatItem(label: '本周生成', value: '-'),
                    _UserStatItem(label: '总生成', value: '-'),
                  ],
                );
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    _UserStatItem(label: '今日生成', value: '...'),
                    _UserStatItem(label: '本周生成', value: '...'),
                    _UserStatItem(label: '总生成', value: '...'),
                  ],
                );
              }

              final stats =
                  snapshot.data ??
                  const UserStats(todayCount: 0, weekCount: 0, totalCount: 0);
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _UserStatItem(label: '今日生成', value: '${stats.todayCount}'),
                  _UserStatItem(label: '本周生成', value: '${stats.weekCount}'),
                  _UserStatItem(label: '总生成', value: '${stats.totalCount}'),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHistorySection(
    BuildContext context,
    ThemeData theme,
    bool isLoggedIn,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('最近生成', style: theme.textTheme.headlineSmall),
            TextButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const GenerationHistoryPage(),
                  ),
                );
              },
              child: const Text(
                '查看全部',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (!isLoggedIn)
          const Text(
            '登录后可以在这里查看你的生成历史记录',
            style: TextStyle(color: Colors.white60, fontSize: 13),
          )
        else
          SizedBox(
            height: 210,
            child: FutureBuilder<GenerationHistoryPageResult>(
              future: GenerationHistoryApiService.listHistory(
                page: 1,
                pageSize: 10,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  // 简单的 skeleton 占位
                  return ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: 3,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      return Container(
                        width: 140,
                        decoration: BoxDecoration(
                          color: const Color(0xFF151515),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  color: Colors.grey[800],
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              height: 10,
                              margin: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey[800],
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                        ),
                      );
                    },
                  );
                }

                if (snapshot.hasError) {
                  // 后台记录错误，但对用户展示为空状态占位，避免打扰体验
                  debugPrint('加载生成历史失败: ${snapshot.error}');
                  return _buildEmptyHistoryPlaceholder();
                }

                final result = snapshot.data;
                final items = result?.items ?? [];

                if (items.isEmpty) {
                  return _buildEmptyHistoryPlaceholder();
                }

                return ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return GestureDetector(
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
                        width: 132,
                        decoration: BoxDecoration(
                          color: const Color(0xFF151515),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x66000000),
                              blurRadius: 10,
                              offset: Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AspectRatio(
                              aspectRatio: 3 / 4,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(20),
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
                            const SizedBox(height: 6),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              child: Text(
                                _getHistoryTitle(item.type),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
      ],
    );
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

  Widget _buildSettingsSection(ThemeData theme) {
    final user = AuthState.instance.currentUser;
    final isLoggedIn = user != null;

    final items = [
      // 编辑资料放在第一个
      if (isLoggedIn)
        _SettingItemData(
          icon: Icons.edit_outlined,
          label: '编辑资料',
          onTap: () async {
            final result = await Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const EditProfilePage()));

            // 如果修改了资料，刷新页面
            if (result == true && mounted) {
              setState(() {});
            }
          },
        ),
      _SettingItemData(icon: Icons.person_outline, label: '账号与安全'),
      _SettingItemData(icon: Icons.lock_outline, label: '隐私设置'),
      _SettingItemData(icon: Icons.language, label: '语言与地区'),
      _SettingItemData(icon: Icons.info_outline, label: '关于应用'),
    ];

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF151515),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            ListTile(
              leading: Icon(items[i].icon, color: Colors.white70, size: 22),
              title: Text(items[i].label, style: theme.textTheme.bodyLarge),
              trailing: const Icon(Icons.chevron_right, color: Colors.white38),
              onTap: items[i].onTap ?? () {},
            ),
            if (i != items.length - 1)
              const Divider(height: 1, color: Color(0xFF222222)),
          ],
        ],
      ),
    );
  }
}

class _UserStatItem extends StatelessWidget {
  final String label;
  final String value;

  const _UserStatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }
}

class _SettingItemData {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _SettingItemData({required this.icon, required this.label, this.onTap});
}
