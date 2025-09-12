class News {
  final int id;
  final String imageUrl;
  final String companyLogoUrl;
  final bool isGoodNews;
  final String companyName;
  final String currentPrice;
  final String priceChange;
  final String title;
  final String dateSource;
  final String prediction;
  final bool isPredictionPositive;
  final bool isBookmarkedInitially;

  News({
    required this.id,
    required this.imageUrl,
    required this.companyLogoUrl,
    required this.isGoodNews,
    required this.companyName,
    required this.currentPrice,
    required this.priceChange,
    required this.title,
    required this.dateSource,
    required this.prediction,
    required this.isPredictionPositive,
    this.isBookmarkedInitially = false,
  });
}