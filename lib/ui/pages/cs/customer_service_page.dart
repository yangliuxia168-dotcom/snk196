import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import '../../../core/services/http_client.dart';
import '../../../core/services/storage_service.dart';
import '../../../ui/theme/app_theme.dart';

/// 客服咨询页面
class CustomerServicePage extends StatefulWidget {
  const CustomerServicePage({super.key});

  @override
  State<CustomerServicePage> createState() => _CustomerServicePageState();
}

class _CustomerServicePageState extends State<CustomerServicePage> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  String? _sessionId;
  int _status = -1; // -1未开始 0排队中 1进行中 2已结束
  int _queueNumber = 0;
  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _createSession();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _createSession() async {
    setState(() => _isLoading = true);

    final response = await HttpClient.instance.post('/api/cs/session/create');
    if (response.isSuccess) {
      final data = response.data;
      setState(() {
        _sessionId = data['sessionId'] as String?;
        _status = (data['status'] as num?)?.toInt() ?? 0;
        _queueNumber = (data['queueNumber'] as num?)?.toInt() ?? 0;
      });
      if (_sessionId != null) {
        _loadMessages();
      }
    } else {
      EasyLoading.showError(response.message);
    }

    setState(() => _isLoading = false);
  }

  Future<void> _loadMessages() async {
    if (_sessionId == null) return;

    final response = await HttpClient.instance.get(
      '/api/cs/session/$_sessionId/messages',
      params: {'page': 1, 'size': 50},
    );

    if (response.isSuccess) {
      setState(() {
        _messages = List<Map<String, dynamic>>.from(response.data as Iterable? ?? []);
        _messages = _messages.reversed.toList();
      });
      _scrollToBottom();
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _sessionId == null) return;

    _messageController.clear();

    // 先添加到本地
    setState(() {
      _messages.add({
        'senderType': 1,
        'content': text,
        'contentType': 1,
        'sendTime': DateTime.now().toIso8601String(),
        'senderName': '我',
      });
    });
    _scrollToBottom();

    // 发送到服务器
    final response = await HttpClient.instance.post(
      '/api/cs/message/send',
      data: {
        'sessionId': _sessionId,
        'content': text,
        'contentType': 1,
      },
    );

    if (!response.isSuccess) {
      EasyLoading.showError('发送失败');
    }
  }

  Future<void> _endSession() async {
    if (_sessionId == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('结束咨询'),
        content: const Text('确定要结束本次咨询吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('确定')),
        ],
      ),
    );

    if (confirm != true) return;

    final response = await HttpClient.instance.post('/api/cs/session/$_sessionId/end');
    if (response.isSuccess) {
      setState(() => _status = 2);
      _showRatingDialog();
    }
  }

  void _showRatingDialog() {
    int rating = 5;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('请为本次服务评分'),
          content: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              return IconButton(
                icon: Icon(
                  index < rating ? Icons.star : Icons.star_border,
                  color: const Color(0xFFFFAA00),
                  size: 36,
                ),
                onPressed: () => setDialogState(() => rating = index + 1),
              );
            }),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('跳过'),
            ),
            ElevatedButton(
              onPressed: () async {
                await HttpClient.instance.post(
                  '/api/cs/session/$_sessionId/rate',
                  params: {'rating': rating},
                );
                if (ctx.mounted) Navigator.pop(ctx);
                EasyLoading.showSuccess('感谢您的评价');
              },
              child: const Text('提交'),
            ),
          ],
        ),
      ),
    );
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('在线客服'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (_status == 1)
            TextButton(
              onPressed: _endSession,
              child: const Text('结束', style: TextStyle(color: AppTheme.errorColor)),
            ),
        ],
      ),
      body: Column(
        children: [
          // 状态提示
          _buildStatusBanner(),

          // 消息列表
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(12),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      return _buildMessageItem(msg);
                    },
                  ),
          ),

          // 输入区域
          if (_status == 0 || _status == 1) _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildStatusBanner() {
    if (_status == 0) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 10),
        color: const Color(0xFFFFF7E6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.access_time, size: 16, color: Color(0xFFFAAD14)),
            const SizedBox(width: 6),
            Text(
              '排队中，您前面还有 $_queueNumber 人...',
              style: const TextStyle(color: Color(0xFFFAAD14), fontSize: 13),
            ),
          ],
        ),
      );
    }
    if (_status == 1) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 10),
        color: const Color(0xFFF6FFED),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.headset_mic, size: 16, color: Color(0xFF52C41A)),
            SizedBox(width: 6),
            Text('客服已接入', style: TextStyle(color: Color(0xFF52C41A), fontSize: 13)),
          ],
        ),
      );
    }
    if (_status == 2) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 10),
        color: AppTheme.backgroundColor,
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 16, color: AppTheme.textSecondary),
            SizedBox(width: 6),
            Text('会话已结束', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildMessageItem(Map<String, dynamic> msg) {
    final senderType = msg['senderType'] ?? 1;
    final isUser = senderType == 1;
    final isSystem = senderType == 3;
    final content = (msg['content'] ?? '') as String;

    if (isSystem) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.05),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(content, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 18,
              backgroundColor: AppTheme.primaryColor,
              child: const Icon(Icons.headset_mic, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isUser ? AppTheme.bubbleSelf : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(12),
                  topRight: const Radius.circular(12),
                  bottomLeft: isUser ? const Radius.circular(12) : const Radius.circular(4),
                  bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(12),
                ),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 1)),
                ],
              ),
              child: Text(content, style: const TextStyle(fontSize: 15)),
            ),
          ),
          if (isUser) const SizedBox(width: 8),
        ],
      ),
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
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.backgroundColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: TextField(
                  controller: _messageController,
                  decoration: const InputDecoration(
                    hintText: '输入您的问题...',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.send, color: AppTheme.primaryColor),
              onPressed: _sendMessage,
            ),
          ],
        ),
      ),
    );
  }
}
