import 'package:intl/intl.dart';

class News {
  final int newsId;
  final String newsImage;
  final String companyLogo;
  final String newsTitle;
  final String dateSource; // 'press'와 'publishedDate'를 조합
  final String companyName;
  final String currentPrice;
  final String priceChange;
  final bool isGoodNews; // 'sentiment' 기반으로 계산
  final bool isPredictionPositive; // 'influenceScore' 기반으로 계산
  final String prediction; // 'influenceScore' 기반으로 생성
  final String? summary; // 요약은 별도 API 호출 필요
  bool isBookmarked; // DTO의 'scrapped'에 해당

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
    this.summary,
    required this.isBookmarked,
  });

  // 백엔드 응답(NewsDTO)을 News 모델로 변환하는 팩토리 생성자
  factory News.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> sourceForStockData;
    if (json.containsKey('stockInfo') && json['stockInfo'] is Map<String, dynamic>) {
      sourceForStockData = json['stockInfo'];
    } else {
      sourceForStockData = json;
    }

    final sentiment = (json['sentiment'] ?? '').toString().toUpperCase();

    final influenceScore = (sourceForStockData['influenceScore'] ?? 0.0).toDouble();

    String formattedDate = '';
    if (json['publishedDate'] != null) {
      try {
        DateTime parsedDate = DateTime.parse(json['publishedDate']);
        formattedDate =
        "${parsedDate.year}.${parsedDate.month.toString().padLeft(
            2, '0')}.${parsedDate.day.toString().padLeft(2, '0')}";
      } catch (e) {
        formattedDate = json['publishedDate'];
      }
    }

    String predictionText = influenceScore > 0 ? "+${influenceScore
        .toStringAsFixed(2)}%" : "${influenceScore.toStringAsFixed(2)}%";

    double priceChangeValue = (sourceForStockData['priceChange'] ?? 0.0).toDouble();
    String priceChangeText = priceChangeValue > 0
        ? "+${priceChangeValue.toStringAsFixed(2)}%"
        : "${priceChangeValue.toStringAsFixed(2)}%";


    String formattedCurrentPrice = '0'; // 기본값
    final priceValue = sourceForStockData['currentPrice'];
    if (priceValue != null) {
       num priceNum = 0;
      if (priceValue is num) {
        priceNum = priceValue;
      } else if (priceValue is String) {
        priceNum = num.tryParse(priceValue) ?? 0;
      }

     final formatter = NumberFormat('#,###');
      formattedCurrentPrice = formatter.format(priceNum.toInt());
    }


    return News(
     newsId: json['newsId'] ?? 0,
      newsImage: json['newsImage'] ?? '',
      newsTitle: json['newsTitle'] ?? '',
      dateSource: "${json['press'] ?? '정보 없음'} | $formattedDate",
      isBookmarked: json['scrapped'] ?? false,
      isGoodNews: sentiment == 'POSITIVE',

      companyLogo: sourceForStockData['stockImage'] ?? '',
      companyName: sourceForStockData['stockName'] ?? '',

      currentPrice: formattedCurrentPrice,
      priceChange: priceChangeText,

      // influenceScore로 계산된 값들
      isPredictionPositive: influenceScore >= 0,
      prediction: predictionText,
      summary: json['reason'],
    );
  }
}