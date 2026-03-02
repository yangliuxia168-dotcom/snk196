/// 好友模型
class FriendModel {
  final int userId;
  final String username;
  final String nickname;
  final String? avatarUrl;
  final String? signature;
  final String? remark;
  final String? groupName;
  final bool isOnline;

  FriendModel({
    required this.userId,
    required this.username,
    required this.nickname,
    this.avatarUrl,
    this.signature,
    this.remark,
    this.groupName,
    this.isOnline = false,
  });

  factory FriendModel.fromJson(Map<String, dynamic> json) {
    return FriendModel(
      userId: (json['userId'] as num?)?.toInt() ?? (json['friendId'] as num?)?.toInt() ?? 0,
      username: (json['username'] as String?) ?? '',
      nickname: (json['nickname'] as String?) ?? '',
      avatarUrl: json['avatarUrl'] as String?,
      signature: json['signature'] as String?,
      remark: json['remark'] as String?,
      groupName: json['groupName'] as String?,
      isOnline: (json['isOnline'] as bool?) ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'username': username,
      'nickname': nickname,
      'avatarUrl': avatarUrl,
      'signature': signature,
      'remark': remark,
      'groupName': groupName,
      'isOnline': isOnline,
    };
  }

  String get displayName => remark ?? nickname;
}

/// 好友请求模型
class FriendRequestModel {
  final int requestId;
  final int fromUserId;
  final String fromUsername;
  final String fromNickname;
  final String? fromAvatarUrl;
  final String? message;
  final int status; // 0待处理 1已同意 2已拒绝
  final DateTime createTime;

  FriendRequestModel({
    required this.requestId,
    required this.fromUserId,
    required this.fromUsername,
    required this.fromNickname,
    this.fromAvatarUrl,
    this.message,
    this.status = 0,
    required this.createTime,
  });

  factory FriendRequestModel.fromJson(Map<String, dynamic> json) {
    return FriendRequestModel(
      requestId: (json['requestId'] as num?)?.toInt() ?? 0,
      fromUserId: (json['fromUserId'] as num?)?.toInt() ?? 0,
      fromUsername: (json['fromUsername'] as String?) ?? '',
      fromNickname: (json['fromNickname'] as String?) ?? '',
      fromAvatarUrl: json['fromAvatarUrl'] as String?,
      message: json['message'] as String?,
      status: (json['status'] as num?)?.toInt() ?? 0,
      createTime: json['createTime'] != null
          ? DateTime.parse(json['createTime'] as String)
          : DateTime.now(),
    );
  }

  bool get isPending => status == 0;
  bool get isAccepted => status == 1;
  bool get isRejected => status == 2;

  String get statusName {
    switch (status) {
      case 1:
        return '已同意';
      case 2:
        return '已拒绝';
      default:
        return '待处理';
    }
  }
}
