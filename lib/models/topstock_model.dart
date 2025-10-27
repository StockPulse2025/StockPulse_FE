import 'package:intl/intl.dart';

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
    // 가격 포매팅
    String formattedPrice = '';
    final priceValue = json['currentPrice'];
    if (priceValue != null) {
      num priceNum = num.tryParse(priceValue.toString()) ?? 0;
      // --- 수정: "원" 추가 ---
      formattedPrice = '${NumberFormat('#,###').format(priceNum.toInt())}원';
    }

    // 등락률 포매팅
    double changeValue = (json['priceChange'] ?? 0.0).toDouble();
    String formattedChange = changeValue >= 0
        ? "+${changeValue.toStringAsFixed(2)}%"
        : "${changeValue.toStringAsFixed(2)}%";

    // 예측 등락률 포매팅
    double predictionValue = (json['influenceScore'] ?? 0.0).toDouble();
    String formattedPrediction = predictionValue >= 0
        ? "+${predictionValue.toStringAsFixed(2)}%"
        : "${predictionValue.toStringAsFixed(2)}%";

    return TopStock(
      rank: (json['rank'] ?? 0).toString(),
      imageUrl: json['stockImage'] ?? '',
      name: json['stockName'] ?? '이름 없음',
      price: formattedPrice,
      change: formattedChange,
      prediction: formattedPrediction,
    );
  }
}