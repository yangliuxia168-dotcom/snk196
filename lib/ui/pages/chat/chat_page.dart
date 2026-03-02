import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../../../data/providers/chat_provider.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/models/message_model.dart';
import '../../../core/services/http_client.dart';
import '../../../core/services/websocket_service.dart';
import '../../../ui/theme/app_theme.dart';
import '../../../ui/widgets/avatar_widget.dart';
import '../../../ui/widgets/marquee_banner.dart';

/// 聊天页面
class ChatPage extends StatefulWidget {
  final dynamic targetId;
  final int chatType; // 1私聊 2群聊
  final String name;
  final String? avatarUrl;

  const ChatPage({
    super.key,
    required this.targetId,
    required this.chatType,
    required this.name,
    this.avatarUrl,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();
  bool _showEmojiPanel = false;
  bool _isMoreExpanded = false;
  int _page = 1;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _loadMessages() {
    context.read<ChatProvider>().loadMessages(widget.chatType, widget.targetId, page: _page);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 100) {
      if (_hasMore) {
        _page++;
        _loadMessages();
      }
    }
  }

  void _sendTextMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    context.read<ChatProvider>().sendMessage(
      chatType: widget.chatType,
      targetId: widget.targetId,
      contentType: 1,
      content: text,
    );

    _messageController.clear();
    _scrollToBottom();
  }

  Future<void> _sendImageMessage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1920, maxHeight: 1920);
    if (image == null) return;

    // 上传图片
    final response = await HttpClient.instance.upload(
      '/api/file/upload/image',
      filePath: image.path,
    );

    if (response.isSuccess && mounted) {
      final fileUrl = response.data['fileUrl'] as String?;
      final thumbnailUrl = response.data['thumbnailUrl'] as String?;

      context.read<ChatProvider>().sendMessage(
        chatType: widget.chatType,
        targetId: widget.targetId,
        contentType: 2,
        content: '[图片]',
        fileUrl: fileUrl,
      );
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (!mounted) return;
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = context.read<AuthProvider>().user?.userId ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            Text(widget.name, style: const TextStyle(fontSize: 16)),
            if (widget.chatType == 2)
              const Text('群聊', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_horiz),
            onPressed: () {
              // TODO: 聊天设置
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 跑马灯广告横幅
          const MarqueeBanner(),

          // 消息列表
          Expanded(
            child: Consumer<ChatProvider>(
              builder: (context, chatProvider, _) {
                final messages = chatProvider.getMessages(widget.chatType, widget.targetId);

                if (messages.isEmpty) {
                  return Center(
                    child: Text('暂无消息，快来说点什么吧', style: TextStyle(color: Colors.grey[400])),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isSelf = message.fromUserId == currentUserId;
                    
                    // 时间分割线
                    Widget? timeWidget;
                    if (index == messages.length - 1 || 
                        messages[index].sendTime.difference(messages[index + 1 < messages.length ? index + 1 : index].sendTime).abs() > const Duration(minutes: 5)) {
                      timeWidget = _buildTimeLabel(message.sendTime);
                    }

                    return Column(
                      children: [
                        if (timeWidget != null) timeWidget,
                        _MessageBubble(
                          message: message,
                          isSelf: isSelf,
                          showSenderName: widget.chatType == 2 && !isSelf,
                          onLongPress: () => _showMessageMenu(context, message, isSelf),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),

          // 输入区域
          _buildInputBar(),

          // 表情面板
          if (_showEmojiPanel) _buildEmojiPanel(),

          // 更多功能面板
          if (_isMoreExpanded) _buildMorePanel(),
        ],
      ),
    );
  }

  Widget _buildTimeLabel(DateTime time) {
    final now = DateTime.now();
    String text;
    if (time.year == now.year && time.month == now.month && time.day == now.day) {
      text = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    } else {
      text = '${time.month}/${time.day} ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(text, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppTheme.dividerColor, width: 0.5)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // 表情按钮
            IconButton(
              icon: Icon(
                _showEmojiPanel ? Icons.keyboard : Icons.emoji_emotions_outlined,
                color: AppTheme.textSecondary,
              ),
              onPressed: () {
                setState(() {
                  _showEmojiPanel = !_showEmojiPanel;
                  _isMoreExpanded = false;
                  if (_showEmojiPanel) {
                    _focusNode.unfocus();
                  } else {
                    _focusNode.requestFocus();
                  }
                });
              },
            ),

            // 输入框
            Expanded(
              child: Container(
                constraints: const BoxConstraints(maxHeight: 100),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: TextField(
                  controller: _messageController,
                  focusNode: _focusNode,
                  maxLines: null,
                  decoration: const InputDecoration(
                    hintText: '输入消息...',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    hintStyle: TextStyle(color: AppTheme.textDisabled),
                  ),
                  onTap: () {
                    setState(() {
                      _showEmojiPanel = false;
                      _isMoreExpanded = false;
                    });
                  },
                  onSubmitted: (_) => _sendTextMessage(),
                ),
              ),
            ),

            // 更多/发送按钮
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: _messageController,
              builder: (context, value, _) {
                if (value.text.trim().isNotEmpty) {
                  return IconButton(
                    icon: const Icon(Icons.send, color: AppTheme.primaryColor),
                    onPressed: _sendTextMessage,
                  );
                }
                return IconButton(
                  icon: const Icon(Icons.add_circle_outline, color: AppTheme.textSecondary),
                  onPressed: () {
                    setState(() {
                      _isMoreExpanded = !_isMoreExpanded;
                      _showEmojiPanel = false;
                      _focusNode.unfocus();
                    });
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmojiPanel() {
    // 常用emoji列表
    final emojis = [
      '\u{1F600}', '\u{1F601}', '\u{1F602}', '\u{1F603}', '\u{1F604}', '\u{1F605}', '\u{1F606}', '\u{1F607}',
      '\u{1F608}', '\u{1F609}', '\u{1F60A}', '\u{1F60B}', '\u{1F60C}', '\u{1F60D}', '\u{1F60E}', '\u{1F60F}',
      '\u{1F610}', '\u{1F611}', '\u{1F612}', '\u{1F613}', '\u{1F614}', '\u{1F615}', '\u{1F616}', '\u{1F617}',
      '\u{1F618}', '\u{1F619}', '\u{1F61A}', '\u{1F61B}', '\u{1F61C}', '\u{1F61D}', '\u{1F61E}', '\u{1F61F}',
      '\u{1F620}', '\u{1F621}', '\u{1F622}', '\u{1F623}', '\u{1F624}', '\u{1F625}', '\u{1F626}', '\u{1F627}',
      '\u{2764}', '\u{1F44D}', '\u{1F44E}', '\u{1F44A}', '\u{270C}', '\u{1F44B}', '\u{1F44F}', '\u{1F64F}',
    ];

    return Container(
      height: 260,
      color: AppTheme.backgroundColor,
      child: GridView.builder(
        padding: const EdgeInsets.all(8),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 8,
          mainAxisSpacing: 4,
          crossAxisSpacing: 4,
        ),
        itemCount: emojis.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () {
              _messageController.text += emojis[index];
              _messageController.selection = TextSelection.fromPosition(
                TextPosition(offset: _messageController.text.length),
              );
            },
            child: Center(
              child: Text(emojis[index], style: const TextStyle(fontSize: 28)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMorePanel() {
    return Container(
      height: 180,
      color: AppTheme.backgroundColor,
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMoreItem(Icons.photo_library, '相册', _sendImageMessage),
          const SizedBox(width: 24),
          _buildMoreItem(Icons.camera_alt, '拍照', () async {
            final picker = ImagePicker();
            final image = await picker.pickImage(source: ImageSource.camera);
            if (image != null) {
              final response = await HttpClient.instance.upload('/api/file/upload/image', filePath: image.path);
              if (response.isSuccess && mounted) {
                context.read<ChatProvider>().sendMessage(
                  chatType: widget.chatType, targetId: widget.targetId,
                  contentType: 2, content: '[图片]', fileUrl: response.data['fileUrl'] as String?,
                );
              }
            }
          }),
        ],
      ),
    );
  }

  Widget _buildMoreItem(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: AppTheme.textSecondary, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
        ],
      ),
    );
  }

  void _showMessageMenu(BuildContext context, MessageModel message, bool isSelf) {
    if (message.isRecalled) return;

    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (message.isText)
              ListTile(
                leading: const Icon(Icons.copy),
                title: const Text('复制'),
                onTap: () {
                  Clipboard.setData(ClipboardData(text: message.content));
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已复制')));
                },
              ),
            if (isSelf && DateTime.now().difference(message.sendTime).inMinutes < 2)
              ListTile(
                leading: const Icon(Icons.undo, color: AppTheme.warningColor),
                title: const Text('撤回'),
                onTap: () {
                  context.read<ChatProvider>().recallMessage(
                    message.msgId, widget.chatType, widget.targetId,
                  );
                  Navigator.pop(context);
                },
              ),
          ],
        ),
      ),
    );
  }
}

/// 消息气泡组件
class _MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isSelf;
  final bool showSenderName;
  final VoidCallback? onLongPress;

  const _MessageBubble({
    required this.message,
    required this.isSelf,
    this.showSenderName = false,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    // 系统消息
    if (message.isSystem) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.05),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(message.content, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
          ),
        ),
      );
    }

    // 撤回消息
    if (message.isRecalled) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Center(
          child: Text(
            isSelf ? '你撤回了一条消息' : '对方撤回了一条消息',
            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isSelf ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isSelf) ...[
            AvatarWidget(
              url: message.senderAvatar,
              name: message.senderNickname ?? '',
              size: 36,
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isSelf ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (showSenderName && message.senderNickname != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text(message.senderNickname!,
                        style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                  ),
                GestureDetector(
                  onLongPress: onLongPress,
                  child: _buildContent(context),
                ),
                // 发送状态
                if (isSelf && message.isSending)
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 1.5)),
                  ),
                if (isSelf && message.isFailed)
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Icon(Icons.error, color: AppTheme.errorColor, size: 16),
                  ),
              ],
            ),
          ),
          if (isSelf) ...[
            const SizedBox(width: 8),
            AvatarWidget(
              url: context.read<AuthProvider>().user?.avatarUrl,
              name: context.read<AuthProvider>().user?.nickname ?? '',
              size: 36,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (message.isImage) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 200, maxHeight: 200),
          child: Image.network(
            message.fileUrl ?? message.content,
            fit: BoxFit.cover,
            loadingBuilder: (_, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                width: 150, height: 150,
                color: AppTheme.backgroundColor,
                child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
              );
            },
            errorBuilder: (_, __, ___) => Container(
              width: 150, height: 150,
              color: AppTheme.backgroundColor,
              child: const Icon(Icons.broken_image, color: AppTheme.textDisabled),
            ),
          ),
        ),
      );
    }

    if (message.isEmoji) {
      return Image.network(
        message.fileUrl ?? message.content,
        width: 120, height: 120,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => const Text('[表情]'),
      );
    }

    // 文本消息
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isSelf ? AppTheme.bubbleSelf : AppTheme.bubbleOther,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(12),
          topRight: const Radius.circular(12),
          bottomLeft: isSelf ? const Radius.circular(12) : const Radius.circular(4),
          bottomRight: isSelf ? const Radius.circular(4) : const Radius.circular(12),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Text(
        message.content,
        style: TextStyle(
          fontSize: 15,
          color: isSelf ? Colors.black87 : AppTheme.textPrimary,
        ),
      ),
    );
  }
}
