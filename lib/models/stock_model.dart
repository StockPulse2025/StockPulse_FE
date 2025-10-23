class Stock {
  final int rank;
  final int stockId;
  final String name;
  final String symbol;
  final String? imageUrl;
  double currentPrice;
  double changeRate;
  final double changeAmount;
  final int? tradingValue;
  final int? tradingVolume;
  final bool favorite;
  final bool owned;
  final String? prediction;
  final double predictInfluenceScore;
  final int? newsCount;

  Stock({
    required this.rank,
    required this.stockId,
    required this.name,
    required this.symbol,
    this.imageUrl,
    required this.currentPrice,
    required this.changeRate,
    required this.changeAmount,
    this.tradingValue,
    this.tradingVolume,
    required this.favorite,
    required this.owned,
    this.prediction,
    required this.predictInfluenceScore,
    this.newsCount,
  });

  factory Stock.fromJson(Map<String, dynamic> json) {
    double parseToDouble(dynamic value) {
      if (value is int) {
        return value.toDouble();
      } else if (value is double) {
        return value;
      } else {
        return 0.0;
      }
    }

    return Stock(
      rank: json['rank'] ?? 0,
      stockId: json['stockId'] ?? 0,
      name: json['name'] ?? json['stockName'] ?? '',
      symbol: json['symbol'] ?? '',
      imageUrl: json['imageUrl'],
      currentPrice: parseToDouble(json['currentPrice']),
      changeRate: parseToDouble(json['changeRate']),
      changeAmount: parseToDouble(json['changeAmount']),
      tradingValue: json['tradingValue'],
      tradingVolume: json['tradingVolume'],
      favorite: json['favorite'] ?? false,
      owned: json['owned'] ?? false,
      prediction: json['predictInfluenceScore']?.toString(),
      predictInfluenceScore: parseToDouble(json['predictInfluenceScore']),
      newsCount: json['newsCount'] ?? json['relatedIssueCount'],
    );
  }
}
