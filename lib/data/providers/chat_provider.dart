import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/message_model.dart';
import '../models/conversation_model.dart';
import '../../core/services/http_client.dart';
import '../../core/services/websocket_service.dart';
import '../../core/services/storage_service.dart';

/// 聊天状态Provider
class ChatProvider extends ChangeNotifier {
  final List<ConversationModel> _conversations = [];
  final Map<String, List<MessageModel>> _messages = {};
  bool _isLoading = false;
  int _totalUnread = 0;
  StreamSubscription<Map<String, dynamic>>? _wsSubscription;

  List<ConversationModel> get conversations => _conversations;
  bool get isLoading => _isLoading;
  int get totalUnread => _totalUnread;

  ChatProvider() {
    _init();
  }

  void _init() {
    // 监听WebSocket消息
    _wsSubscription = WebSocketService.instance.messageStream.listen(
      _handleWsMessage,
    );
  }

  @override
  void dispose() {
    _wsSubscription?.cancel();
    super.dispose();
  }

  void _handleWsMessage(Map<String, dynamic> data) {
    final type = data['type'] as String?;

    switch (type) {
      case 'MESSAGE':
        _handleNewMessage(data);
        break;
      case 'ACK':
        _handleAck(data);
        break;
      case 'READ':
        _handleRead(data);
        break;
      case 'RECALL':
        _handleRecall(data);
        break;
    }
  }

  void _handleNewMessage(Map<String, dynamic> data) {
    final message = MessageModel.fromJson(data);
    final key = _getConversationKey(
      message.chatType,
      message.chatType == 1 ? message.fromUserId : message.toId,
    );

    if (!_messages.containsKey(key)) {
      _messages[key] = [];
    }
    _messages[key]!.insert(0, message);

    // 更新会话列表
    _updateConversation(message);

    notifyListeners();
  }

  void _handleAck(Map<String, dynamic> data) {
    final msgId = data['msgId'] as String?;
    if (msgId == null) return;

    // 更新消息发送状态
    for (var msgs in _messages.values) {
      final index = msgs.indexWhere((m) => m.msgId == msgId);
      if (index != -1) {
        msgs[index] = msgs[index].copyWith(sendStatus: 1);
        notifyListeners();
        break;
      }
    }
  }

  void _handleRead(Map<String, dynamic> data) {
    final msgId = data['msgId'] as String?;
    if (msgId == null) return;

    for (var msgs in _messages.values) {
      final index = msgs.indexWhere((m) => m.msgId == msgId);
      if (index != -1) {
        msgs[index] = msgs[index].copyWith(readStatus: 1);
        notifyListeners();
        break;
      }
    }
  }

  void _handleRecall(Map<String, dynamic> data) {
    final msgId = data['msgId'] as String?;
    if (msgId == null) return;

    for (var msgs in _messages.values) {
      final index = msgs.indexWhere((m) => m.msgId == msgId);
      if (index != -1) {
        msgs[index] = msgs[index].copyWith(recallStatus: 1, content: '[消息已撤回]');
        notifyListeners();
        break;
      }
    }
  }

  void _updateConversation(MessageModel message) {
    final targetId = message.chatType == 1 ? message.fromUserId : message.toId;
    final index = _conversations.indexWhere(
      (c) => c.targetId == targetId && c.chatType == message.chatType,
    );

    if (index != -1) {
      final conv = _conversations[index];
      _conversations[index] = conv.copyWith(
        lastMessage: message.content,
        lastContentType: message.contentType,
        lastTime: message.sendTime,
        unreadCount: conv.unreadCount + 1,
      );
      // 移动到顶部
      final updated = _conversations.removeAt(index);
      _conversations.insert(0, updated);
    }

    _calculateTotalUnread();
  }

  void _calculateTotalUnread() {
    _totalUnread = _conversations.fold(0, (sum, c) => sum + c.unreadCount);
  }

  String _getConversationKey(int chatType, dynamic targetId) {
    return '${chatType}_$targetId';
  }

  /// 获取会话列表
  Future<void> loadConversations() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await HttpClient.instance.get(
        '/api/v1/messages/conversations',
      );
      if (response.isSuccess) {
        final list = (response.data as List)
            .map((e) => ConversationModel.fromJson(e as Map<String, dynamic>))
            .toList();
        _conversations.clear();
        _conversations.addAll(list);
        _calculateTotalUnread();
      }
    } catch (e) {
      debugPrint('Load conversations error: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  /// 获取消息历史
  Future<void> loadMessages(
    int chatType,
    dynamic targetId, {
    int page = 1,
  }) async {
    final key = _getConversationKey(chatType, targetId);

    try {
      final path = chatType == 1
          ? '/api/v1/messages/private/$targetId'
          : '/api/v1/messages/group/$targetId';
      final response = await HttpClient.instance.get(
        path,
        params: {'page': page},
      );

      if (response.isSuccess) {
        final list = (response.data as List)
            .map((e) => MessageModel.fromJson(e as Map<String, dynamic>))
            .toList();

        if (page == 1) {
          _messages[key] = list;
        } else {
          _messages[key]?.addAll(list);
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Load messages error: $e');
    }
  }

  /// 获取会话消息
  List<MessageModel> getMessages(int chatType, dynamic targetId) {
    final key = _getConversationKey(chatType, targetId);
    return _messages[key] ?? [];
  }

  /// 发送消息
  Future<void> sendMessage({
    required int chatType,
    required dynamic targetId,
    required int contentType,
    required String content,
    String? fileUrl,
  }) async {
    final msgId = const Uuid().v4();
    final userInfo = StorageService.instance.userInfo;
    final userId = (userInfo?['userId'] as num?)?.toInt() ?? 0;

    // 创建本地消息
    final message = MessageModel(
      msgId: msgId,
      fromUserId: userId,
      toId: targetId,
      chatType: chatType,
      contentType: contentType,
      content: content,
      fileUrl: fileUrl,
      sendTime: DateTime.now(),
      sendStatus: 0, // 发送中
    );

    // 添加到本地消息列表
    final key = _getConversationKey(chatType, targetId);
    if (!_messages.containsKey(key)) {
      _messages[key] = [];
    }
    _messages[key]!.insert(0, message);
    notifyListeners();

    // 通过WebSocket发送
    WebSocketService.instance.sendChatMessage(
      msgId: msgId,
      toId: targetId,
      chatType: chatType,
      contentType: contentType,
      content: content,
      fileUrl: fileUrl,
    );
  }

  /// 撤回消息
  void recallMessage(String msgId, int chatType, dynamic targetId) {
    WebSocketService.instance.recallMessage(
      msgId: msgId,
      toId: targetId,
      chatType: chatType,
    );
  }

  /// 清除会话未读数
  void clearUnread(int chatType, dynamic targetId) {
    final index = _conversations.indexWhere(
      (c) => c.targetId == targetId && c.chatType == chatType,
    );
    if (index != -1) {
      _conversations[index] = _conversations[index].copyWith(unreadCount: 0);
      _calculateTotalUnread();
      notifyListeners();
    }
  }

  /// 删除会话
  void deleteConversation(int chatType, dynamic targetId) {
    _conversations.removeWhere(
      (c) => c.targetId == targetId && c.chatType == chatType,
    );
    final key = _getConversationKey(chatType, targetId);
    _messages.remove(key);
    _calculateTotalUnread();
    notifyListeners();
  }
}
