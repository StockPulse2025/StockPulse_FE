class NotificationModel {
  final String stockName;
  final String impact;
  final String newsTitle;
  final String newsImagePath;
  final String stockLogoPath;
  final String relatedStockName;

  NotificationModel({
    required this.stockName,
    required this.impact,
    required this.newsTitle,
    required this.newsImagePath,
    required this.stockLogoPath,
    required this.relatedStockName,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      stockName: json['stockName'],
      impact: json['impact'],
      newsTitle: json['newsTitle'],
      newsImagePath: json['newsImagePath'],
      stockLogoPath: json['stockLogoPath'],
      relatedStockName: json['relatedStockName'],
    );
  }
}
