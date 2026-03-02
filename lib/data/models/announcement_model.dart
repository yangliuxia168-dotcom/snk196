/// 公告模型（跑马灯广告）
class AnnouncementModel {
  final int announcementId;
  final String content;

  AnnouncementModel({
    required this.announcementId,
    required this.content,
  });

  factory AnnouncementModel.fromJson(Map<String, dynamic> json) {
    return AnnouncementModel(
      announcementId: (json['announcementId'] as num?)?.toInt() ?? 0,
      content: json['content'] as String? ?? '',
    );
  }

  static List<AnnouncementModel> fromJsonList(List<dynamic> jsonList) {
    return jsonList
        .map((e) => AnnouncementModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
