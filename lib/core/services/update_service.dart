import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/models/version_info.dart';
import '../config/app_config.dart';

/// 应用更新服务
class UpdateService {
  UpdateService._();
  static final UpdateService instance = UpdateService._();

  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  /// 获取当前平台标识
  String get _platform {
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    if (Platform.isWindows) return 'windows';
    return 'web';
  }

  /// 检查更新
  Future<VersionInfo?> checkForUpdate() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersionCode = int.tryParse(packageInfo.buildNumber) ?? 0;

      final response = await _dio.get(
        AppConfig.versionCheckUrl,
        queryParameters: {
          'platform': _platform,
          'currentVersionCode': currentVersionCode,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        if (data['code'] == 200 && data['data'] != null) {
          return VersionInfo.fromJson(data['data'] as Map<String, dynamic>);
        }
      }
      return null;
    } catch (e) {
      // 版本检查失败不阻塞应用启动
      debugPrint('版本检查失败: $e');
      return null;
    }
  }

  /// 显示更新对话框
  Future<void> showUpdateDialog(BuildContext context, VersionInfo info) async {
    if (!info.hasUpdate) return;

    final fileSizeStr = info.fileSize != null
        ? _formatFileSize(info.fileSize!)
        : '';

    await showDialog(
      context: context,
      barrierDismissible: !info.forceUpdate,
      builder: (ctx) => PopScope(
        canPop: !info.forceUpdate,
        child: AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.system_update, color: Color(0xFF1890FF)),
              const SizedBox(width: 8),
              const Text('发现新版本'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '最新版本: v${info.latestVersion}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (fileSizeStr.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  '安装包大小: $fileSizeStr',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
              ],
              const SizedBox(height: 12),
              const Text(
                '更新内容:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 4),
              Container(
                constraints: const BoxConstraints(maxHeight: 200),
                child: SingleChildScrollView(
                  child: Text(
                    info.description.isNotEmpty ? info.description : '优化体验，修复已知问题',
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  ),
                ),
              ),
              if (info.forceUpdate) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    '此版本为强制更新，请立即升级',
                    style: TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),
              ],
            ],
          ),
          actions: [
            if (!info.forceUpdate)
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('稍后再说'),
              ),
            ElevatedButton(
              onPressed: () {
                _handleUpdate(info.downloadUrl);
                if (!info.forceUpdate) {
                  Navigator.of(ctx).pop();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1890FF),
                foregroundColor: Colors.white,
              ),
              child: const Text('立即更新'),
            ),
          ],
        ),
      ),
    );
  }

  /// 执行更新操作
  void _handleUpdate(String downloadUrl) async {
    final uri = Uri.parse(downloadUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  /// 格式化文件大小
  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
  }
}
