/// 版本信息模型
class VersionInfo {
  final bool hasUpdate;
  final String latestVersion;
  final int versionCode;
  final String downloadUrl;
  final bool forceUpdate;
  final String description;
  final int? fileSize;
  final String? md5Hash;

  VersionInfo({
    required this.hasUpdate,
    required this.latestVersion,
    required this.versionCode,
    required this.downloadUrl,
    required this.forceUpdate,
    required this.description,
    this.fileSize,
    this.md5Hash,
  });

  factory VersionInfo.fromJson(Map<String, dynamic> json) {
    return VersionInfo(
      hasUpdate: json['hasUpdate'] as bool? ?? false,
      latestVersion: json['latestVersion'] as String? ?? '',
      versionCode: (json['versionCode'] as num?)?.toInt() ?? 0,
      downloadUrl: json['downloadUrl'] as String? ?? '',
      forceUpdate: json['forceUpdate'] as bool? ?? false,
      description: json['description'] as String? ?? '',
      fileSize: (json['fileSize'] as num?)?.toInt(),
      md5Hash: json['md5Hash'] as String?,
    );
  }

  factory VersionInfo.noUpdate() {
    return VersionInfo(
      hasUpdate: false,
      latestVersion: '',
      versionCode: 0,
      downloadUrl: '',
      forceUpdate: false,
      description: '',
    );
  }
}
