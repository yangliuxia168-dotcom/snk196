import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../config/app_config.dart';
import 'storage_service.dart';

/// WebSocket消息类型
enum WsMsgType { message, ack, typing, read, recall, system, ping, pong }

/// WebSocket服务
class WebSocketService {
  WebSocketService._();
  static final WebSocketService instance = WebSocketService._();

  WebSocketChannel? _channel;
  StreamSubscription? _channelSubscription;
  Timer? _heartbeatTimer;
  Timer? _reconnectTimer;
  bool _isConnected = false;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;
  static const int _heartbeatInterval = 30; // 秒

  final _messageController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get messageStream => _messageController.stream;

  bool get isConnected => _isConnected;

  /// 连接WebSocket
  Future<void> connect() async {
    if (_isConnected) return;

    final token = StorageService.instance.accessToken;
    if (token == null) return;

    try {
      final uri = Uri.parse('${AppConfig.wsUrl}?token=$token');
      _channel = WebSocketChannel.connect(uri);

      _channelSubscription?.cancel();
      _channelSubscription = _channel!.stream.listen(
        _onMessage,
        onError: _onError,
        onDone: _onDone,
      );

      _isConnected = true;
      _reconnectAttempts = 0;
      _startHeartbeat();

      debugPrint('WebSocket connected');
    } catch (e) {
      debugPrint('WebSocket connect error: $e');
      _scheduleReconnect();
    }
  }

  /// 断开连接
  void disconnect() {
    _stopHeartbeat();
    _reconnectTimer?.cancel();
    _channelSubscription?.cancel();
    _channelSubscription = null;
    _channel?.sink.close();
    _channel = null;
    _isConnected = false;
    debugPrint('WebSocket disconnected');
  }

  /// 发送消息
  void send(Map<String, dynamic> data) {
    if (!_isConnected || _channel == null) {
      debugPrint('WebSocket not connected');
      return;
    }
    _channel!.sink.add(jsonEncode(data));
  }

  /// int chatType 转字符串
  static String _chatTypeStr(int chatType) =>
      chatType == 2 ? 'GROUP' : 'PRIVATE';

  /// int contentType 转字符串
  static String _contentTypeStr(int contentType) {
    switch (contentType) {
      case 2:
        return 'IMAGE';
      case 3:
        return 'EMOJI';
      case 4:
        return 'FILE';
      default:
        return 'TEXT';
    }
  }

  /// 发送聊天消息
  void sendChatMessage({
    required String msgId,
    required dynamic toId,
    required int chatType,
    required int contentType,
    required String content,
    String? fileUrl,
  }) {
    send({
      'type': 'MESSAGE',
      'msgId': msgId,
      'to': toId.toString(),
      'chatType': _chatTypeStr(chatType),
      'contentType': _contentTypeStr(contentType),
      'content': content,
      if (fileUrl != null) 'fileUrl': fileUrl,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  /// 发送已读回执
  void sendReadReceipt({
    required String msgId,
    required dynamic fromId,
    required int chatType,
  }) {
    send({
      'type': 'READ',
      'msgId': msgId,
      'from': fromId.toString(),
      'chatType': _chatTypeStr(chatType),
    });
  }

  /// 发送正在输入
  void sendTyping({required dynamic toId, required int chatType}) {
    send({
      'type': 'TYPING',
      'to': toId.toString(),
      'chatType': _chatTypeStr(chatType),
    });
  }

  /// 撤回消息
  void recallMessage({
    required String msgId,
    required dynamic toId,
    required int chatType,
  }) {
    send({
      'type': 'RECALL',
      'msgId': msgId,
      'to': toId.toString(),
      'chatType': _chatTypeStr(chatType),
    });
  }

  void _onMessage(dynamic data) {
    try {
      final message = jsonDecode(data as String) as Map<String, dynamic>;

      // 处理心跳响应
      if (message['type'] == 'PONG') {
        return;
      }

      _messageController.add(message);
    } catch (e) {
      debugPrint('Parse message error: $e');
    }
  }

  void _onError(dynamic error) {
    debugPrint('WebSocket error: $error');
    _isConnected = false;
    _scheduleReconnect();
  }

  void _onDone() {
    debugPrint('WebSocket closed');
    _isConnected = false;
    _scheduleReconnect();
  }

  void _startHeartbeat() {
    _stopHeartbeat();
    _heartbeatTimer = Timer.periodic(
      const Duration(seconds: _heartbeatInterval),
      (_) => _sendPing(),
    );
  }

  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  void _sendPing() {
    if (_isConnected) {
      send({'type': 'PING'});
    }
  }

  void _scheduleReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      debugPrint('Max reconnect attempts reached');
      return;
    }

    _reconnectTimer?.cancel();
    final delay = Duration(seconds: (_reconnectAttempts + 1) * 2);
    _reconnectTimer = Timer(delay, () {
      _reconnectAttempts++;
      debugPrint('Reconnecting... attempt $_reconnectAttempts');
      connect();
    });
  }

  void dispose() {
    disconnect();
    _messageController.close();
  }
}
