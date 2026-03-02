import 'dart:async';
import 'package:flutter/material.dart';
import '../../data/models/announcement_model.dart';
import '../../core/services/http_client.dart';
import '../theme/app_theme.dart';

/// 跑马灯广告横幅组件
/// 从服务器获取活跃公告，以从右到左滚动的方式展示
class MarqueeBanner extends StatefulWidget {
  const MarqueeBanner({super.key});

  @override
  State<MarqueeBanner> createState() => _MarqueeBannerState();
}

class _MarqueeBannerState extends State<MarqueeBanner>
    with SingleTickerProviderStateMixin {
  List<AnnouncementModel> _announcements = [];
  int _currentIndex = 0;
  bool _loading = true;

  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;

  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: const Offset(-1.0, 0.0),
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.linear,
    ));

    _animationController.addStatusListener(_onAnimationStatus);

    _loadAnnouncements();

    // 每5分钟刷新一次公告列表
    _refreshTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      _loadAnnouncements();
    });
  }

  @override
  void dispose() {
    _animationController.removeStatusListener(_onAnimationStatus);
    _animationController.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _onAnimationStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      // 切换到下一条公告
      if (_announcements.isNotEmpty) {
        setState(() {
          _currentIndex = (_currentIndex + 1) % _announcements.length;
        });
        _animationController.reset();
        _animationController.forward();
      }
    }
  }

  Future<void> _loadAnnouncements() async {
    try {
      final response = await HttpClient.instance.get('/api/announcement/active');
      if (response.isSuccess && response.data != null) {
        final list = AnnouncementModel.fromJsonList(response.data as List);
        if (mounted) {
          setState(() {
            _announcements = list;
            _loading = false;
            _currentIndex = 0;
          });
          if (list.isNotEmpty) {
            _animationController.reset();
            _animationController.forward();
          }
        }
      } else {
        if (mounted) {
          setState(() => _loading = false);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _announcements.isEmpty) {
      return const SizedBox.shrink();
    }

    final currentAnnouncement = _announcements[_currentIndex];

    return Container(
      height: 32,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor.withOpacity(0.08),
            AppTheme.warningColor.withOpacity(0.08),
          ],
        ),
        border: Border(
          bottom: BorderSide(color: AppTheme.dividerColor, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          // 小喇叭图标
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Icon(
              Icons.campaign_outlined,
              size: 16,
              color: AppTheme.warningColor,
            ),
          ),
          // 滚动文字区域
          Expanded(
            child: ClipRect(
              child: SlideTransition(
                position: _slideAnimation,
                child: Center(
                  child: Text(
                    currentAnnouncement.content,
                    maxLines: 1,
                    overflow: TextOverflow.visible,
                    softWrap: false,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
              ),
            ),
          ),
          // 公告计数指示器
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              '${_currentIndex + 1}/${_announcements.length}',
              style: const TextStyle(
                fontSize: 10,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
