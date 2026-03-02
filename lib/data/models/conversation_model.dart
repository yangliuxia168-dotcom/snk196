/// 会话模型
class ConversationModel {
  final dynamic targetId; // 私聊是userId，群聊是groupId
  final int chatType; // 1私聊 2群聊
  final String name;
  final String? avatarUrl;
  final String? lastMessage;
  final int lastContentType;
  final DateTime? lastTime;
  final int unreadCount;
  final bool isTop;
  final bool isMuted;

  // 群聊特有
  final int? memberCount;

  ConversationModel({
    required this.targetId,
    required this.chatType,
    required this.name,
    this.avatarUrl,
    this.lastMessage,
    this.lastContentType = 1,
    this.lastTime,
    this.unreadCount = 0,
    this.isTop = false,
    this.isMuted = false,
    this.memberCount,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    return ConversationModel(
      targetId: json['targetId'] ?? json['userId'] ?? json['groupId'],
      chatType: (json['chatType'] as num?)?.toInt() ?? 1,
      name: (json['name'] as String?) ?? (json['nickname'] as String?) ?? (json['groupName'] as String?) ?? '',
      avatarUrl: json['avatarUrl'] as String?,
      lastMessage: json['lastMessage'] as String?,
      lastContentType: (json['lastContentType'] as num?)?.toInt() ?? 1,
      lastTime: json['lastTime'] != null
          ? DateTime.parse(json['lastTime'] as String)
          : null,
      unreadCount: (json['unreadCount'] as num?)?.toInt() ?? 0,
      isTop: (json['isTop'] as bool?) ?? false,
      isMuted: (json['isMuted'] as bool?) ?? false,
      memberCount: (json['memberCount'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'targetId': targetId,
      'chatType': chatType,
      'name': name,
      'avatarUrl': avatarUrl,
      'lastMessage': lastMessage,
      'lastContentType': lastContentType,
      'lastTime': lastTime?.toIso8601String(),
      'unreadCount': unreadCount,
      'isTop': isTop,
      'isMuted': isMuted,
      'memberCount': memberCount,
    };
  }

  bool get isPrivate => chatType == 1;
  bool get isGroup => chatType == 2;

  String get lastMessageDisplay {
    if (lastMessage == null) return '';
    switch (lastContentType) {
      case 2:
        return '[图片]';
      case 3:
        return '[表情]';
      case 4:
        return lastMessage!;
      default:
        return lastMessage!;
    }
  }

  ConversationModel copyWith({
    String? lastMessage,
    int? lastContentType,
    DateTime? lastTime,
    int? unreadCount,
    bool? isTop,
    bool? isMuted,
  }) {
    return ConversationModel(
      targetId: targetId,
      chatType: chatType,
      name: name,
      avatarUrl: avatarUrl,
      lastMessage: lastMessage ?? this.lastMessage,
      lastContentType: lastContentType ?? this.lastContentType,
      lastTime: lastTime ?? this.lastTime,
      unreadCount: unreadCount ?? this.unreadCount,
      isTop: isTop ?? this.isTop,
      isMuted: isMuted ?? this.isMuted,
      memberCount: memberCount,
    );
  }
}
