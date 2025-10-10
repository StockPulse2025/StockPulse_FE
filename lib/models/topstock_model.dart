class TopStock {
  final String rank;
  final String name;
  final String price;
  final String change;
  final String prediction;
  final String imageUrl;

  TopStock({
    required this.rank,
    required this.name,
    required this.price,
    required this.change,
    required this.prediction,
    required this.imageUrl,
  });

  factory TopStock.fromJson(Map<String, dynamic> json) {
    return TopStock(
      rank: json['rank']?.toString() ?? '',
      name: json['name'] ?? '',
      price: json['price'] ?? '',
      change: json['change'] ?? '',
      prediction: json['prediction'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
    );
  }
}
