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
    // prediction API의 응답 필드(predictInfluenceScore, relatedIssueCount)를 매핑
    return Stock(
      rank: json['rank'] ?? 0,
      stockId: json['stockId'] ?? 0,
      // 'name'과 'stockName' 두 가지 키로 들어올 수 있으므로 모두 처리
      name: json['name'] ?? json['stockName'] ?? '',
      symbol: json['symbol'] ?? '',
      imageUrl: json['imageUrl'],
      currentPrice: json['currentPrice'] ?? 0,
      changeRate: (json['changeRate'] ?? 0).toDouble(),
      changeAmount: (json['changeAmount'] ?? 0).toDouble(),
      tradingValue: json['tradingValue'],
      tradingVolume: json['tradingVolume'],
      favorite: json['favorite'] ?? false,
      owned: json['owned'] ?? false,
      // 'prediction'은 'predictInfluenceScore'를 문자열로 변환하여 사용
      prediction: json['predictInfluenceScore']?.toString(),
      predictInfluenceScore: (json['predictInfluenceScore'] ?? 0).toDouble(),
      // 'newsCount'는 'relatedIssueCount'를 사용
      newsCount: json['newsCount'] ?? json['relatedIssueCount'],
    );
  }
}
