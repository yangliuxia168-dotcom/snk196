import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/providers/chat_provider.dart';
import '../../../data/models/conversation_model.dart';
import '../../../ui/theme/app_theme.dart';
import '../../../ui/widgets/avatar_widget.dart';
import '../chat/chat_page.dart';

/// 消息列表页
class MessageListPage extends StatelessWidget {
  const MessageListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('消息'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: 搜索
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.add_circle_outline),
            onSelected: (value) {
              // TODO: 处理菜单
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'addFriend', child: Row(
                children: [Icon(Icons.person_add, size: 20), SizedBox(width: 8), Text('添加好友')],
              )),
              const PopupMenuItem(value: 'createGroup', child: Row(
                children: [Icon(Icons.group_add, size: 20), SizedBox(width: 8), Text('创建群聊')],
              )),
            ],
          ),
        ],
      ),
      body: Consumer<ChatProvider>(
        builder: (context, chatProvider, _) {
          if (chatProvider.isLoading && chatProvider.conversations.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (chatProvider.conversations.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text('暂无消息', style: TextStyle(color: Colors.grey[400], fontSize: 16)),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => chatProvider.loadConversations(),
            child: ListView.builder(
              itemCount: chatProvider.conversations.length,
              itemBuilder: (context, index) {
                final conversation = chatProvider.conversations[index];
                return _ConversationItem(
                  conversation: conversation,
                  onTap: () {
                    chatProvider.clearUnread(conversation.chatType, conversation.targetId);
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ChatPage(
                          targetId: conversation.targetId,
                          chatType: conversation.chatType,
                          name: conversation.name,
                          avatarUrl: conversation.avatarUrl,
                        ),
                      ),
                    );
                  },
                  onLongPress: () {
                    _showConversationMenu(context, chatProvider, conversation);
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }

  void _showConversationMenu(BuildContext context, ChatProvider provider, ConversationModel conv) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.delete_outline, color: AppTheme.errorColor),
              title: const Text('删除会话', style: TextStyle(color: AppTheme.errorColor)),
              onTap: () {
                provider.deleteConversation(conv.chatType, conv.targetId);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// 会话列表项
class _ConversationItem extends StatelessWidget {
  final ConversationModel conversation;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _ConversationItem({
    required this.conversation,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppTheme.dividerColor, width: 0.5)),
        ),
        child: Row(
          children: [
            // 头像
            AvatarWidget(
              url: conversation.avatarUrl,
              name: conversation.name,
              size: 48,
              isGroup: conversation.isGroup,
            ),
            const SizedBox(width: 12),
            // 内容
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          conversation.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (conversation.lastTime != null)
                        Text(
                          _formatTime(conversation.lastTime!),
                          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          conversation.lastMessageDisplay,
                          style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (conversation.unreadCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: conversation.isMuted ? AppTheme.textDisabled : AppTheme.errorColor,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            conversation.unreadCount > 99 ? '99+' : conversation.unreadCount.toString(),
                            style: const TextStyle(color: Colors.white, fontSize: 11),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) return '刚刚';
    if (diff.inHours < 1) return '${diff.inMinutes}分钟前';

    if (time.year == now.year && time.month == now.month && time.day == now.day) {
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    }

    final yesterday = now.subtract(const Duration(days: 1));
    if (time.year == yesterday.year && time.month == yesterday.month && time.day == yesterday.day) {
      return '昨天';
    }

    if (time.year == now.year) {
      return '${time.month}/${time.day}';
    }

    return '${time.year}/${time.month}/${time.day}';
  }
}
