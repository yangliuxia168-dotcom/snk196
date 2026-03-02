import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../ui/theme/app_theme.dart';
import '../../../ui/widgets/avatar_widget.dart';

/// 个人资料编辑页
class ProfileEditPage extends StatefulWidget {
  const ProfileEditPage({super.key});

  @override
  State<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends State<ProfileEditPage> {
  final _nicknameController = TextEditingController();
  final _signatureController = TextEditingController();
  int _gender = 0;
  String? _birthday;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    if (user != null) {
      _nicknameController.text = user.nickname;
      _signatureController.text = user.signature ?? '';
      _gender = user.gender;
      _birthday = user.birthday;
    }
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _signatureController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final nickname = _nicknameController.text.trim();
    if (nickname.isEmpty || nickname.length < 2) {
      EasyLoading.showError('昵称至少2个字符');
      return;
    }

    EasyLoading.show(status: '保存中...');

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.updateUserInfo(
      nickname: nickname,
      signature: _signatureController.text.trim(),
      gender: _gender,
      birthday: _birthday,
    );

    EasyLoading.dismiss();

    if (success) {
      EasyLoading.showSuccess('保存成功');
      if (mounted) Navigator.of(context).pop();
    } else {
      EasyLoading.showError(authProvider.error ?? '保存失败');
    }
  }

  Future<void> _pickBirthday() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _birthday != null ? DateTime.tryParse(_birthday!) ?? now : now,
      firstDate: DateTime(1950),
      lastDate: now,
      locale: const Locale('zh', 'CN'),
    );
    if (date != null) {
      setState(() {
        _birthday = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('编辑资料'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('保存', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: ListView(
        children: [
          // 头像
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: GestureDetector(
                onTap: () {
                  // TODO: 更换头像
                },
                child: Stack(
                  children: [
                    AvatarWidget(url: user?.avatarUrl, name: user?.nickname ?? '', size: 80),
                    Positioned(
                      right: 0, bottom: 0,
                      child: Container(
                        width: 28, height: 28,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(Icons.camera_alt, color: Colors.white, size: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // 昵称
          Container(
            color: Colors.white,
            child: ListTile(
              title: const Text('昵称', style: TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
              subtitle: TextField(
                controller: _nicknameController,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: '2-20个字符',
                  contentPadding: EdgeInsets.zero,
                ),
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
          const Divider(height: 0.5, indent: 16),

          // 个性签名
          Container(
            color: Colors.white,
            child: ListTile(
              title: const Text('个性签名', style: TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
              subtitle: TextField(
                controller: _signatureController,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: '写点什么介绍自己...',
                  contentPadding: EdgeInsets.zero,
                ),
                style: const TextStyle(fontSize: 16),
                maxLines: 2,
                maxLength: 100,
              ),
            ),
          ),
          const SizedBox(height: 8),

          // 性别
          Container(
            color: Colors.white,
            child: ListTile(
              title: const Text('性别'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ChoiceChip(
                    label: const Text('男'),
                    selected: _gender == 1,
                    onSelected: (_) => setState(() => _gender = 1),
                    selectedColor: AppTheme.primaryColor.withOpacity(0.2),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('女'),
                    selected: _gender == 2,
                    onSelected: (_) => setState(() => _gender = 2),
                    selectedColor: AppTheme.primaryColor.withOpacity(0.2),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('保密'),
                    selected: _gender == 0,
                    onSelected: (_) => setState(() => _gender = 0),
                    selectedColor: AppTheme.primaryColor.withOpacity(0.2),
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 0.5, indent: 16),

          // 生日
          Container(
            color: Colors.white,
            child: ListTile(
              title: const Text('生日'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_birthday ?? '未设置', style: const TextStyle(color: AppTheme.textSecondary)),
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_right, color: AppTheme.textDisabled),
                ],
              ),
              onTap: _pickBirthday,
            ),
          ),
          const SizedBox(height: 8),

          // 用户名(不可修改)
          Container(
            color: Colors.white,
            child: ListTile(
              title: const Text('用户名'),
              trailing: Text(user?.username ?? '', style: const TextStyle(color: AppTheme.textSecondary)),
            ),
          ),
          const Divider(height: 0.5, indent: 16),

          // 用户ID
          Container(
            color: Colors.white,
            child: ListTile(
              title: const Text('用户ID'),
              trailing: Text('${user?.userId ?? ''}', style: const TextStyle(color: AppTheme.textSecondary)),
            ),
          ),
        ],
      ),
    );
  }
}
