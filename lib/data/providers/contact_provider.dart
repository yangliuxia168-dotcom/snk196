import 'package:flutter/foundation.dart';
import '../models/friend_model.dart';
import '../models/group_model.dart';
import '../../core/services/http_client.dart';

/// 联系人状态Provider
class ContactProvider extends ChangeNotifier {
  final List<FriendModel> _friends = [];
  final List<GroupModel> _groups = [];
  final List<FriendRequestModel> _friendRequests = [];
  bool _isLoading = false;
  String? _error;

  List<FriendModel> get friends => _friends;
  List<GroupModel> get groups => _groups;
  List<FriendRequestModel> get friendRequests => _friendRequests;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get pendingRequestCount =>
      _friendRequests.where((r) => r.isPending).length;

  /// 加载好友列表
  Future<void> loadFriends() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await HttpClient.instance.get('/api/v1/friends');
      if (response.isSuccess) {
        final list = (response.data as List)
            .map((e) => FriendModel.fromJson(e as Map<String, dynamic>))
            .toList();
        _friends.clear();
        _friends.addAll(list);
      }
    } catch (e) {
      _error = '加载好友列表失败';
    }

    _isLoading = false;
    notifyListeners();
  }

  /// 加载群组列表
  Future<void> loadGroups() async {
    try {
      final response = await HttpClient.instance.get('/api/v1/groups/my');
      if (response.isSuccess) {
        final list = (response.data as List)
            .map((e) => GroupModel.fromJson(e as Map<String, dynamic>))
            .toList();
        _groups.clear();
        _groups.addAll(list);
        notifyListeners();
      }
    } catch (e) {
      _error = '加载群组列表失败';
      notifyListeners();
    }
  }

  /// 加载好友请求
  Future<void> loadFriendRequests() async {
    try {
      final response = await HttpClient.instance.get(
        '/api/v1/friends/requests/pending',
      );
      if (response.isSuccess) {
        final list = (response.data as List)
            .map((e) => FriendRequestModel.fromJson(e as Map<String, dynamic>))
            .toList();
        _friendRequests.clear();
        _friendRequests.addAll(list);
        notifyListeners();
      }
    } catch (e) {
      _error = '加载好友请求失败';
      notifyListeners();
    }
  }

  /// 搜索用户
  Future<List<Map<String, dynamic>>> searchUsers(String keyword) async {
    try {
      final response = await HttpClient.instance.get(
        '/api/v1/users/search',
        params: {'keyword': keyword},
      );
      if (response.isSuccess) {
        return (response.data as List).cast<Map<String, dynamic>>();
      }
    } catch (e) {
      _error = '搜索失败';
    }
    return [];
  }

  /// 发送好友请求
  Future<bool> sendFriendRequest(int userId, String? message) async {
    try {
      final response = await HttpClient.instance.post(
        '/api/v1/friends/request',
        params: {'toUserId': userId, if (message != null) 'message': message},
      );
      return response.isSuccess;
    } catch (e) {
      _error = '发送请求失败';
    }
    return false;
  }

  /// 处理好友请求
  Future<bool> handleFriendRequest(int requestId, bool accept) async {
    try {
      final action = accept ? 'accept' : 'reject';
      final response = await HttpClient.instance.post(
        '/api/v1/friends/requests/$requestId/$action',
      );
      if (response.isSuccess) {
        await loadFriendRequests();
        if (accept) await loadFriends();
        return true;
      }
    } catch (e) {
      _error = '处理请求失败';
    }
    return false;
  }

  /// 删除好友
  Future<bool> deleteFriend(int userId) async {
    try {
      final response = await HttpClient.instance.delete(
        '/api/v1/friends/$userId',
      );
      if (response.isSuccess) {
        _friends.removeWhere((f) => f.userId == userId);
        notifyListeners();
        return true;
      }
    } catch (e) {
      _error = '删除好友失败';
    }
    return false;
  }

  /// 创建群组
  Future<GroupModel?> createGroup(String groupName, List<int> memberIds) async {
    try {
      final response = await HttpClient.instance.post(
        '/api/v1/groups',
        data: {'groupName': groupName, 'memberIds': memberIds},
      );
      if (response.isSuccess) {
        final group = GroupModel.fromJson(
          response.data as Map<String, dynamic>,
        );
        _groups.insert(0, group);
        notifyListeners();
        return group;
      }
    } catch (e) {
      _error = '创建群组失败';
    }
    return null;
  }

  /// 退出群组
  Future<bool> quitGroup(int groupId) async {
    try {
      final response = await HttpClient.instance.post(
        '/api/v1/groups/$groupId/quit',
      );
      if (response.isSuccess) {
        _groups.removeWhere((g) => g.groupId == groupId);
        notifyListeners();
        return true;
      }
    } catch (e) {
      _error = '退出群组失败';
    }
    return false;
  }

  /// 获取群成员
  Future<List<GroupMemberModel>> getGroupMembers(int groupId) async {
    try {
      final response = await HttpClient.instance.get(
        '/api/v1/groups/$groupId/members',
      );
      if (response.isSuccess) {
        return (response.data as List)
            .map((e) => GroupMemberModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      _error = '获取群成员失败';
    }
    return [];
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
