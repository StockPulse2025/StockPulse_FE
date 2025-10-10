class Stock {
  final int rank;
  final int stockId;
  final String name;
  final String symbol;
  final String? imageUrl;
  final int currentPrice;
  final double changeRate;
  final double changeAmount;
  final int? tradingValue;
  final int? tradingVolume;
  final bool favorite;
  final bool owned;
  final String? prediction;
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
    this.newsCount,
  });

  factory Stock.fromJson(Map<String, dynamic> json) {
    return Stock(
      rank: json['rank'] ?? 0,
      stockId: json['stockId'] ?? 0,
      name: json['name'] ?? '',
      symbol: json['symbol'] ?? '',
      imageUrl: json['imageUrl'],
      currentPrice: json['currentPrice'] ?? 0,
      changeRate: (json['changeRate'] ?? 0).toDouble(),
      changeAmount: (json['changeAmount'] ?? 0).toDouble(),
      tradingValue: json['tradingValue'],
      tradingVolume: json['tradingVolume'],
      favorite: json['favorite'] ?? false,
      owned: json['owned'] ?? false,
      prediction: json['prediction'],
      newsCount: json['newsCount'],
    );
  }
}
