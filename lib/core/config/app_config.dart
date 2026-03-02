/// 应用配置
class AppConfig {
  AppConfig._();

  /// 服务器地址 - 构建时由脚本替换 __SERVER_IP__ 为实际IP
  static const String serverHost = '103.237.92.183';

  /// API基础地址
  static const String baseUrl = 'http://$serverHost/api';

  /// WebSocket地址
  static const String wsUrl = 'ws://$serverHost/ws';

  /// 文件服务地址
  static const String fileUrl = 'http://$serverHost/api';

  /// 客服服务地址
  static const String csUrl = 'http://$serverHost/api';

  /// 版本检查地址
  static const String versionCheckUrl = 'http://$serverHost/api/version/check';

  /// 连接超时时间
  static const int connectTimeout = 15000;

  /// 接收超时时间
  static const int receiveTimeout = 15000;

  /// Token刷新提前�?�?
  static const int tokenRefreshAdvance = 3600;

  /// 消息分页大小
  static const int messagePageSize = 20;

  /// 联系人分页大�?
  static const int contactPageSize = 50;

  /// 图片最大大�?字节)
  static const int maxImageSize = 10 * 1024 * 1024;

  /// 表情最大大�?字节)
  static const int maxEmojiSize = 2 * 1024 * 1024;
}
