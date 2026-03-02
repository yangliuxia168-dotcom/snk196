/// 群组模型
class GroupModel {
  final int groupId;
  final String groupName;
  final String? avatarUrl;
  final int ownerId;
  final String? announcement;
  final int memberCount;
  final int maxMembers;
  final bool allowInvite;
  final int status;
  final int? myRole; // 1成员 2管理员 3群主

  GroupModel({
    required this.groupId,
    required this.groupName,
    this.avatarUrl,
    required this.ownerId,
    this.announcement,
    this.memberCount = 0,
    this.maxMembers = 50,
    this.allowInvite = true,
    this.status = 1,
    this.myRole,
  });

  factory GroupModel.fromJson(Map<String, dynamic> json) {
    return GroupModel(
      groupId: (json['groupId'] as num?)?.toInt() ?? 0,
      groupName: (json['groupName'] as String?) ?? '',
      avatarUrl: json['avatarUrl'] as String?,
      ownerId: (json['ownerId'] as num?)?.toInt() ?? 0,
      announcement: json['announcement'] as String?,
      memberCount: (json['memberCount'] as num?)?.toInt() ?? 0,
      maxMembers: (json['maxMembers'] as num?)?.toInt() ?? 50,
      allowInvite: (json['allowInvite'] as bool?) ?? true,
      status: (json['status'] as num?)?.toInt() ?? 1,
      myRole: (json['myRole'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'groupId': groupId,
      'groupName': groupName,
      'avatarUrl': avatarUrl,
      'ownerId': ownerId,
      'announcement': announcement,
      'memberCount': memberCount,
      'maxMembers': maxMembers,
      'allowInvite': allowInvite,
      'status': status,
      'myRole': myRole,
    };
  }

  bool get isOwner => myRole == 3;
  bool get isAdmin => myRole == 2 || myRole == 3;
  bool get isMember => myRole == 1;

  String get myRoleName {
    switch (myRole) {
      case 3:
        return '群主';
      case 2:
        return '管理员';
      case 1:
        return '成员';
      default:
        return '';
    }
  }
}

/// 群成员模型
class GroupMemberModel {
  final int userId;
  final String nickname;
  final String? avatarUrl;
  final String? groupNickname;
  final int role; // 1成员 2管理员 3群主
  final DateTime? mutedUntil;
  final DateTime joinTime;

  GroupMemberModel({
    required this.userId,
    required this.nickname,
    this.avatarUrl,
    this.groupNickname,
    this.role = 1,
    this.mutedUntil,
    required this.joinTime,
  });

  factory GroupMemberModel.fromJson(Map<String, dynamic> json) {
    return GroupMemberModel(
      userId: (json['userId'] as num?)?.toInt() ?? 0,
      nickname: (json['nickname'] as String?) ?? '',
      avatarUrl: json['avatarUrl'] as String?,
      groupNickname: json['groupNickname'] as String?,
      role: (json['role'] as num?)?.toInt() ?? 1,
      mutedUntil: json['mutedUntil'] != null
          ? DateTime.parse(json['mutedUntil'] as String)
          : null,
      joinTime: json['joinTime'] != null
          ? DateTime.parse(json['joinTime'] as String)
          : DateTime.now(),
    );
  }

  String get displayName => groupNickname ?? nickname;
  bool get isOwner => role == 3;
  bool get isAdmin => role == 2;
  bool get isMuted =>
      mutedUntil != null && mutedUntil!.isAfter(DateTime.now());

  String get roleName {
    switch (role) {
      case 3:
        return '群主';
      case 2:
        return '管理员';
      default:
        return '';
    }
  }
}
