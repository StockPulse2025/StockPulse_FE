class NotificationModel {
  final int id;
  final int newsId;
  final String stockName;
  final double impactRate;
  final String newsTitle;
  final int stockId;
  final String stockImgUrl;
  final String createdAt;

  NotificationModel({
    required this.id,
    required this.newsId,
    required this.stockName,
    required this.impactRate,
    required this.newsTitle,
    required this.stockId,
    required this.stockImgUrl,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] ?? 0,
      newsId: json['newsId'] ?? 0,
      stockName: json['stockName'] ?? '알 수 없는 종목',
      impactRate: (json['impactRate'] as num?)?.toDouble() ?? 0.0,
      newsTitle: json['title'] ?? '제목 없음',
      stockId: json['stockId'] ?? 0,
      stockImgUrl: json['stockImgUrl'] ?? '',
      createdAt: json['createdAt'] ?? '',
    );
  }
}