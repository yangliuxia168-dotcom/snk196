import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/providers/contact_provider.dart';
import '../../../data/models/friend_model.dart';
import '../../../data/models/group_model.dart';
import '../../../ui/theme/app_theme.dart';
import '../../../ui/widgets/avatar_widget.dart';
import '../chat/chat_page.dart';

/// 联系人页面
class ContactPage extends StatefulWidget {
  const ContactPage({super.key});

  @override
  State<ContactPage> createState() => _ContactPageState();
}

class _ContactPageState extends State<ContactPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('联系人'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_outlined),
            onPressed: () => _showSearchDialog(context),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: AppTheme.textSecondary,
          indicatorColor: AppTheme.primaryColor,
          tabs: const [
            Tab(text: '好友'),
            Tab(text: '群组'),
            Tab(text: '请求'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _FriendListTab(),
          _GroupListTab(),
          _RequestListTab(),
        ],
      ),
    );
  }

  void _showSearchDialog(BuildContext context) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('搜索用户'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: '输入用户名或昵称',
            prefixIcon: Icon(Icons.search),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              final keyword = controller.text.trim();
              if (keyword.isEmpty) return;
              Navigator.pop(ctx);
              _showSearchResults(context, keyword);
            },
            child: const Text('搜索'),
          ),
        ],
      ),
    );
  }

  void _showSearchResults(BuildContext context, String keyword) async {
    final contactProvider = context.read<ContactProvider>();
    final results = await contactProvider.searchUsers(keyword);

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        expand: false,
        builder: (_, scrollController) {
          if (results.isEmpty) {
            return const Center(child: Text('未找到用户'));
          }
          return ListView.builder(
            controller: scrollController,
            itemCount: results.length,
            itemBuilder: (context, index) {
              final user = results[index];
              return ListTile(
                leading: AvatarWidget(
                  url: user['avatarUrl'] as String?,
                  name: (user['nickname'] as String?) ?? '',
                  size: 40,
                ),
                title: Text((user['nickname'] as String?) ?? ''),
                subtitle: Text('ID: ${(user['username'] as String?) ?? ''}'),
                trailing: ElevatedButton(
                  onPressed: () async {
                    await contactProvider.sendFriendRequest((user['userId'] as num).toInt(), null);
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('好友请求已发送')),
                      );
                    }
                  },
                  child: const Text('添加'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

/// 好友列表
class _FriendListTab extends StatelessWidget {
  const _FriendListTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<ContactProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && provider.friends.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.friends.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_outline, size: 64, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text('暂无好友', style: TextStyle(color: Colors.grey[400], fontSize: 16)),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => provider.loadFriends(),
          child: ListView.builder(
            itemCount: provider.friends.length,
            itemBuilder: (context, index) {
              final friend = provider.friends[index];
              return ListTile(
                leading: Stack(
                  children: [
                    AvatarWidget(url: friend.avatarUrl, name: friend.displayName, size: 44),
                    if (friend.isOnline)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: AppTheme.successColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                  ],
                ),
                title: Text(friend.displayName, style: const TextStyle(fontWeight: FontWeight.w500)),
                subtitle: friend.signature != null
                    ? Text(friend.signature!, maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary))
                    : null,
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => ChatPage(
                      targetId: friend.userId,
                      chatType: 1,
                      name: friend.displayName,
                      avatarUrl: friend.avatarUrl,
                    ),
                  ));
                },
              );
            },
          ),
        );
      },
    );
  }
}

/// 群组列表
class _GroupListTab extends StatelessWidget {
  const _GroupListTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<ContactProvider>(
      builder: (context, provider, _) {
        if (provider.groups.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.group_outlined, size: 64, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text('暂无群组', style: TextStyle(color: Colors.grey[400], fontSize: 16)),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => provider.loadGroups(),
          child: ListView.builder(
            itemCount: provider.groups.length,
            itemBuilder: (context, index) {
              final group = provider.groups[index];
              return ListTile(
                leading: AvatarWidget(url: group.avatarUrl, name: group.groupName, size: 44, isGroup: true),
                title: Row(
                  children: [
                    Flexible(
                      child: Text(group.groupName, style: const TextStyle(fontWeight: FontWeight.w500),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                    const SizedBox(width: 4),
                    Text('(${group.memberCount})', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                  ],
                ),
                subtitle: group.myRoleName.isNotEmpty
                    ? Text(group.myRoleName, style: const TextStyle(fontSize: 12, color: AppTheme.primaryColor))
                    : null,
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => ChatPage(
                      targetId: group.groupId,
                      chatType: 2,
                      name: group.groupName,
                      avatarUrl: group.avatarUrl,
                    ),
                  ));
                },
              );
            },
          ),
        );
      },
    );
  }
}

/// 好友请求列表
class _RequestListTab extends StatelessWidget {
  const _RequestListTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<ContactProvider>(
      builder: (context, provider, _) {
        if (provider.friendRequests.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.mark_email_read_outlined, size: 64, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text('暂无新请求', style: TextStyle(color: Colors.grey[400], fontSize: 16)),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => provider.loadFriendRequests(),
          child: ListView.builder(
            itemCount: provider.friendRequests.length,
            itemBuilder: (context, index) {
              final request = provider.friendRequests[index];
              return ListTile(
                leading: AvatarWidget(url: request.fromAvatarUrl, name: request.fromNickname, size: 44),
                title: Text(request.fromNickname, style: const TextStyle(fontWeight: FontWeight.w500)),
                subtitle: Text(request.message ?? '请求添加好友', maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                trailing: request.isPending
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextButton(
                            onPressed: () => provider.handleFriendRequest(request.requestId, false),
                            child: const Text('拒绝', style: TextStyle(color: AppTheme.textSecondary)),
                          ),
                          const SizedBox(width: 4),
                          ElevatedButton(
                            onPressed: () => provider.handleFriendRequest(request.requestId, true),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              minimumSize: const Size(0, 32),
                            ),
                            child: const Text('同意'),
                          ),
                        ],
                      )
                    : Text(request.statusName,
                        style: TextStyle(
                          color: request.isAccepted ? AppTheme.successColor : AppTheme.textSecondary,
                          fontSize: 13,
                        )),
              );
            },
          ),
        );
      },
    );
  }
}
