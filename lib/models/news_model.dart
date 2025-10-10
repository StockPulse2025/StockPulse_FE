class News {
  final int newsId;
  final String newsImage;
  final String companyLogo;
  final String newsTitle;
  final String dateSource;
  final String companyName;
  final String currentPrice;
  final String priceChange;
  final bool isGoodNews;
  final bool isPredictionPositive;
  final String prediction;
  final String? summary;
  bool isBookmarked;

  News({
    required this.newsId,
    required this.newsImage,
    required this.companyLogo,
    required this.newsTitle,
    required this.dateSource,
    required this.companyName,
    required this.currentPrice,
    required this.priceChange,
    required this.isGoodNews,
    required this.isPredictionPositive,
    required this.prediction,
    required this.summary,
    this.isBookmarked = false,
  });

  static bool parseBool(dynamic value, {bool defaultValue = false}) {
    if (value == null) return defaultValue;
    if (value is bool) return value;
    if (value is String) return value.toLowerCase() == 'true';
    if (value is int) return value != 0;
    return defaultValue;
  }

  factory News.fromJson(Map<String, dynamic> json) {
    final stockInfo = json['stockInfo'] ?? {};
    final sentiment = (json['sentiment'] ?? '').toString().toUpperCase();

    return News(
      newsId: json['newsId'] ?? 0,
      newsImage: json['newsImage'] ?? '',
      companyLogo: stockInfo['stockImage'] ?? '',
      newsTitle: json['newsTitle'] ?? '',
      dateSource: json['publishedDate'] ?? '',
      companyName: stockInfo['stockName'] ?? '',
      currentPrice: stockInfo['currentPrice']?.toString() ?? '',
      priceChange: stockInfo['priceChange']?.toString() ?? '',
      isGoodNews: parseBool(json['isGoodNews'], defaultValue: sentiment == 'POSITIVE'),
      isPredictionPositive: parseBool(json['isPredictionPositive'], defaultValue: sentiment == 'POSITIVE'),
      prediction: json['prediction']?.toString() ?? '',
      isBookmarked: parseBool(json['isBookmarked'], defaultValue: false),
      summary: json['summary']?.toString(),
    );
  }
}
