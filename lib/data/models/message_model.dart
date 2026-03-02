/// 消息模型
class MessageModel {
  final String msgId;
  final int fromUserId;
  final dynamic toId; // 私聊是userId，群聊是groupId
  final int chatType; // 1私聊 2群聊
  final int contentType; // 1文字 2图片 3表情 4系统
  final String content;
  final String? fileUrl;
  final String? thumbnailUrl;
  final int readStatus;
  final int recallStatus;
  final DateTime sendTime;
  final DateTime? readTime;

  // 发送者信息(群聊时使用)
  final String? senderNickname;
  final String? senderAvatar;

  // 本地状态
  final int sendStatus; // 0发送中 1成功 2失败

  MessageModel({
    required this.msgId,
    required this.fromUserId,
    required this.toId,
    required this.chatType,
    required this.contentType,
    required this.content,
    this.fileUrl,
    this.thumbnailUrl,
    this.readStatus = 0,
    this.recallStatus = 0,
    required this.sendTime,
    this.readTime,
    this.senderNickname,
    this.senderAvatar,
    this.sendStatus = 1,
  });

  /// 解析chatType：支持整数(1/2)和字符串("PRIVATE"/"GROUP")
  static int _parseChatType(dynamic value) {
    if (value == null) return 1;
    if (value is int) return value;
    if (value is num) return value.toInt();
    final s = value.toString().toUpperCase();
    return s == 'GROUP' ? 2 : 1;
  }

  /// 解析contentType：支持整数(1/2/3)和字符串("TEXT"/"IMAGE"/"EMOJI")
  static int _parseContentType(dynamic value) {
    if (value == null) return 1;
    if (value is int) return value;
    if (value is num) return value.toInt();
    switch (value.toString().toUpperCase()) {
      case 'IMAGE':
        return 2;
      case 'EMOJI':
        return 3;
      case 'FILE':
        return 4;
      default:
        return 1; // TEXT
    }
  }

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      msgId: (json['msgId'] as String?) ?? '',
      fromUserId:
          (json['fromUserId'] as num?)?.toInt() ??
          (json['from'] as num?)?.toInt() ??
          0,
      toId: json['toUserId'] ?? json['to'] ?? json['groupId'] ?? 0,
      chatType: _parseChatType(json['chatType']),
      contentType: _parseContentType(json['contentType']),
      content: (json['content'] as String?) ?? '',
      fileUrl: json['fileUrl'] as String?,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      readStatus: (json['readStatus'] as num?)?.toInt() ?? 0,
      recallStatus: (json['recallStatus'] as num?)?.toInt() ?? 0,
      sendTime: json['sendTime'] != null
          ? DateTime.parse(json['sendTime'] as String)
          : DateTime.now(),
      readTime: json['readTime'] != null
          ? DateTime.parse(json['readTime'] as String)
          : null,
      senderNickname:
          (json['senderNickname'] as String?) ?? (json['nickname'] as String?),
      senderAvatar:
          (json['senderAvatar'] as String?) ?? (json['avatarUrl'] as String?),
      sendStatus: (json['sendStatus'] as num?)?.toInt() ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'msgId': msgId,
      'fromUserId': fromUserId,
      'toId': toId,
      'chatType': chatType,
      'contentType': contentType,
      'content': content,
      'fileUrl': fileUrl,
      'thumbnailUrl': thumbnailUrl,
      'readStatus': readStatus,
      'recallStatus': recallStatus,
      'sendTime': sendTime.toIso8601String(),
      'readTime': readTime?.toIso8601String(),
      'senderNickname': senderNickname,
      'senderAvatar': senderAvatar,
      'sendStatus': sendStatus,
    };
  }

  bool get isText => contentType == 1;
  bool get isImage => contentType == 2;
  bool get isEmoji => contentType == 3;
  bool get isSystem => contentType == 4;
  bool get isRecalled => recallStatus == 1;
  bool get isRead => readStatus == 1;
  bool get isSending => sendStatus == 0;
  bool get isSent => sendStatus == 1;
  bool get isFailed => sendStatus == 2;

  MessageModel copyWith({
    int? readStatus,
    int? recallStatus,
    int? sendStatus,
    String? content,
  }) {
    return MessageModel(
      msgId: msgId,
      fromUserId: fromUserId,
      toId: toId,
      chatType: chatType,
      contentType: contentType,
      content: content ?? this.content,
      fileUrl: fileUrl,
      thumbnailUrl: thumbnailUrl,
      readStatus: readStatus ?? this.readStatus,
      recallStatus: recallStatus ?? this.recallStatus,
      sendTime: sendTime,
      readTime: readTime,
      senderNickname: senderNickname,
      senderAvatar: senderAvatar,
      sendStatus: sendStatus ?? this.sendStatus,
    );
  }
}
