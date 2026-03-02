import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/models/user_model.dart';
import '../../../ui/theme/app_theme.dart';

/// VIP会员信息页
class VipInfoPage extends StatelessWidget {
  const VipInfoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('会员中心'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          final user = authProvider.user;
          if (user == null) return const SizedBox.shrink();

          return SingleChildScrollView(
            child: Column(
              children: [
                // VIP状态卡片
                _VipStatusCard(user: user),
                const SizedBox(height: 16),

                // 会员等级说明
                _buildVipLevelInfo(),
                const SizedBox(height: 16),

                // 开通说明
                _buildOpenVipInfo(context),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildVipLevelInfo() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('会员等级权益', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          const Divider(height: 0.5),
          _buildLevelItem('普通用户', '免费', '群人数上限50人', Icons.person, Colors.grey),
          const Divider(height: 0.5, indent: 56),
          _buildLevelItem('普通会员', 'VIP1', '群人数上限200人', Icons.diamond, const Color(0xFF1890FF)),
          const Divider(height: 0.5, indent: 56),
          _buildLevelItem('高级会员', 'VIP2', '群人数上限500人', Icons.diamond, const Color(0xFFFFAA00)),
          const Divider(height: 0.5, indent: 56),
          _buildLevelItem('超级会员', 'VIP3', '群人数上限2000人', Icons.diamond, const Color(0xFFFF4D4F)),
        ],
      ),
    );
  }

  Widget _buildLevelItem(String name, String tag, String desc, IconData icon, Color color) {
    return ListTile(
      leading: Icon(icon, color: color, size: 28),
      title: Row(
        children: [
          Text(name, style: const TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Text(tag, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      subtitle: Text(desc, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
    );
  }

  Widget _buildOpenVipInfo(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('如何开通会员', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _buildStepItem(1, '联系在线客服，说明需要开通的会员等级'),
          _buildStepItem(2, '按照客服指引完成付款'),
          _buildStepItem(3, '客服确认收款后，会在后台为您开通会员'),
          _buildStepItem(4, '开通完成后，刷新页面即可看到会员生效'),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                // TODO: 跳转客服页面
                Navigator.of(context).pop();
              },
              icon: const Icon(Icons.headset_mic),
              label: const Text('联系客服开通'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFAA00),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepItem(int step, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22, height: 22,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text('$step', style: const TextStyle(fontSize: 12, color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary))),
        ],
      ),
    );
  }
}

/// VIP状态卡片
class _VipStatusCard extends StatelessWidget {
  final UserModel user;

  const _VipStatusCard({required this.user});

  @override
  Widget build(BuildContext context) {
    final isVip = user.isVip;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isVip
              ? [const Color(0xFFFFAA00), const Color(0xFFFF8800)]
              : [const Color(0xFF666666), const Color(0xFF444444)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (isVip ? const Color(0xFFFFAA00) : Colors.grey).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.diamond, color: Colors.white, size: 32),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isVip ? user.vipLevelName : '普通用户',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isVip ? '到期时间: ${_formatDate(user.vipExpireTime)}' : '开通会员享更多特权',
                    style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.8)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('群上限', '${user.maxGroupSize}人'),
                Container(width: 1, height: 30, color: Colors.white.withOpacity(0.3)),
                _buildStatItem('等级', 'VIP${user.vipLevel}'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.7))),
      ],
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '未知';
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
