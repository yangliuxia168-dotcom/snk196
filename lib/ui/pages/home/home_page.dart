import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:badges/badges.dart' as badges;
import '../../../data/providers/auth_provider.dart';
import '../../../data/providers/chat_provider.dart';
import '../../../data/providers/contact_provider.dart';
import '../../../core/services/websocket_service.dart';
import '../../../ui/theme/app_theme.dart';
import 'message_list_page.dart';
import 'contact_page.dart';
import 'mine_page.dart';

/// 主页
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    MessageListPage(),
    ContactPage(),
    MinePage(),
  ];

  @override
  void initState() {
    super.initState();
    _initData();
  }

  void _initData() {
    // 连接WebSocket
    WebSocketService.instance.connect();
    // 加载数据
    Future.microtask(() {
      context.read<ChatProvider>().loadConversations();
      context.read<ContactProvider>().loadFriends();
      context.read<ContactProvider>().loadGroups();
      context.read<ContactProvider>().loadFriendRequests();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Consumer2<ChatProvider, ContactProvider>(
        builder: (context, chatProvider, contactProvider, _) {
          return BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
            items: [
              BottomNavigationBarItem(
                icon: _buildBadgeIcon(Icons.chat_bubble_outline, chatProvider.totalUnread),
                activeIcon: _buildBadgeIcon(Icons.chat_bubble, chatProvider.totalUnread),
                label: '消息',
              ),
              BottomNavigationBarItem(
                icon: _buildBadgeIcon(Icons.people_outline, contactProvider.pendingRequestCount),
                activeIcon: _buildBadgeIcon(Icons.people, contactProvider.pendingRequestCount),
                label: '联系人',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                activeIcon: Icon(Icons.person),
                label: '我的',
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBadgeIcon(IconData icon, int count) {
    if (count <= 0) {
      return Icon(icon);
    }
    return badges.Badge(
      badgeContent: Text(
        count > 99 ? '99+' : count.toString(),
        style: const TextStyle(color: Colors.white, fontSize: 10),
      ),
      badgeStyle: const badges.BadgeStyle(
        badgeColor: AppTheme.errorColor,
        padding: EdgeInsets.all(4),
      ),
      child: Icon(icon),
    );
  }
}
