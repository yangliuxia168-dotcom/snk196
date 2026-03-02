import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/models/user_model.dart';
import '../../../ui/theme/app_theme.dart';
import '../../../ui/widgets/avatar_widget.dart';
import '../profile/profile_edit_page.dart';
import '../profile/password_change_page.dart';
import '../profile/vip_info_page.dart';
import '../cs/customer_service_page.dart';
import '../auth/login_page.dart';

/// 我的页面
class MinePage extends StatelessWidget {
  const MinePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('我的'),
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          final user = authProvider.user;
          if (user == null) {
            return const Center(child: Text('未登录'));
          }

          return ListView(
            children: [
              // 用户信息卡片
              _UserInfoCard(user: user),
              const SizedBox(height: 8),

              // VIP信息
              _buildMenuItem(
                icon: Icons.diamond_outlined,
                iconColor: const Color(0xFFFFAA00),
                title: '我的会员',
                subtitle: user.isVip ? user.vipLevelName : '开通会员享更多特权',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const VipInfoPage()),
                ),
              ),
              _buildDivider(),

              // 功能列表
              _buildMenuItem(
                icon: Icons.edit_outlined,
                title: '编辑资料',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ProfileEditPage()),
                ),
              ),
              _buildDivider(),
              _buildMenuItem(
                icon: Icons.lock_outlined,
                title: '修改密码',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const PasswordChangePage()),
                ),
              ),
              _buildDivider(),
              _buildMenuItem(
                icon: Icons.headset_mic_outlined,
                title: '在线客服',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CustomerServicePage()),
                ),
              ),
              _buildDivider(),
              _buildMenuItem(
                icon: Icons.info_outline,
                title: '关于CQ',
                onTap: () {
                  showAboutDialog(
                    context: context,
                    applicationName: 'CQ',
                    applicationVersion: '1.0.0',
                    applicationLegalese: 'CQ即时通讯',
                  );
                },
              ),
              const SizedBox(height: 32),

              // 退出登录
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: OutlinedButton(
                  onPressed: () => _showLogoutDialog(context, authProvider),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.errorColor,
                    side: const BorderSide(color: AppTheme.errorColor),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('退出登录', style: TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    Color? iconColor,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      color: Colors.white,
      child: ListTile(
        leading: Icon(icon, color: iconColor ?? AppTheme.textSecondary, size: 24),
        title: Text(title, style: const TextStyle(fontSize: 15)),
        subtitle: subtitle != null ? Text(subtitle, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)) : null,
        trailing: const Icon(Icons.chevron_right, color: AppTheme.textDisabled),
        onTap: onTap,
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      color: Colors.white,
      child: const Divider(height: 0.5, indent: 56),
    );
  }

  void _showLogoutDialog(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('退出登录'),
        content: const Text('确定要退出登录吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await authProvider.logout();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
}

/// 用户信息卡片
class _UserInfoCard extends StatelessWidget {
  final UserModel user;

  const _UserInfoCard({required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          AvatarWidget(url: user.avatarUrl, name: user.nickname, size: 64),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(user.nickname, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    if (user.isVip) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFFFFAA00), Color(0xFFFF8800)]),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(user.vipLevelName,
                            style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w500)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text('ID: ${user.username}', style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                if (user.signature != null && user.signature!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(user.signature!, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                ],
              ],
            ),
          ),
          const Icon(Icons.qr_code, color: AppTheme.textSecondary, size: 24),
        ],
      ),
    );
  }
}
