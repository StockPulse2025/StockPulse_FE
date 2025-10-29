class MarketIndex {
  final double currentPrice;
  final double changeAmount;
  final double changeRate;

  MarketIndex({
    required this.currentPrice,
    required this.changeAmount,
    required this.changeRate,
  });

  factory MarketIndex.fromJson(Map<String, dynamic> json) {
    return MarketIndex(
      currentPrice: (json['currentPrice'] as num?)?.toDouble() ?? 0.0,
      changeAmount: (json['changeAmount'] as num?)?.toDouble() ?? 0.0,
      changeRate: (json['changeRate'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class MarketIndices {
  final MarketIndex kospi;
  final MarketIndex kosdaq;

  MarketIndices({required this.kospi, required this.kosdaq});

  factory MarketIndices.fromJson(Map<String, dynamic> json) {
    return MarketIndices(
      kospi: MarketIndex.fromJson(json['kospi']),
      kosdaq: MarketIndex.fromJson(json['kosdaq']),
    );
  }
}