/// 用户模型
class UserModel {
  final int userId;
  final String username;
  final String nickname;
  final String? avatarUrl;
  final String? signature;
  final int gender;
  final String? birthday;
  final int vipLevel;
  final DateTime? vipExpireTime;
  final int maxGroupSize;
  final int status;

  UserModel({
    required this.userId,
    required this.username,
    required this.nickname,
    this.avatarUrl,
    this.signature,
    this.gender = 0,
    this.birthday,
    this.vipLevel = 0,
    this.vipExpireTime,
    this.maxGroupSize = 50,
    this.status = 1,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      userId: (json['userId'] as num?)?.toInt() ?? 0,
      username: (json['username'] as String?) ?? '',
      nickname: (json['nickname'] as String?) ?? '',
      avatarUrl: json['avatarUrl'] as String?,
      signature: json['signature'] as String?,
      gender: (json['gender'] as num?)?.toInt() ?? 0,
      birthday: json['birthday'] as String?,
      vipLevel: (json['vipLevel'] as num?)?.toInt() ?? 0,
      vipExpireTime: json['vipExpireTime'] != null
          ? DateTime.parse(json['vipExpireTime'] as String)
          : null,
      maxGroupSize: (json['maxGroupSize'] as num?)?.toInt() ?? 50,
      status: (json['status'] as num?)?.toInt() ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'username': username,
      'nickname': nickname,
      'avatarUrl': avatarUrl,
      'signature': signature,
      'gender': gender,
      'birthday': birthday,
      'vipLevel': vipLevel,
      'vipExpireTime': vipExpireTime?.toIso8601String(),
      'maxGroupSize': maxGroupSize,
      'status': status,
    };
  }

  String get vipLevelName {
    switch (vipLevel) {
      case 1:
        return '普通会员';
      case 2:
        return '高级会员';
      case 3:
        return '超级会员';
      default:
        return '普通用户';
    }
  }

  bool get isVip => vipLevel > 0 && 
      (vipExpireTime == null || vipExpireTime!.isAfter(DateTime.now()));
}
