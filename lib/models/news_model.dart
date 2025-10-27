import 'package:intl/intl.dart';

class News {
  final int newsId;
  final String newsImage;
  final String companyLogo;
  final String newsTitle;
  final String dateSource;
  final String companyName;
  final String currentPrice; // 포매팅된 가격 문자열
  final String priceChange;
  final bool isGoodNews;
  final String prediction;
  final String? summary;
  bool isBookmarked;
  final String? newsUrl;

  // --- 추가된 필드: 아이콘 로직을 위한 원시 데이터 ---
  final double influenceScore;

  // influenceScore 기반 계산 getter
  bool get isPredictionPositive => influenceScore >= 0;

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
    required this.prediction,
    this.summary,
    required this.isBookmarked,
    this.newsUrl,
    required this.influenceScore,
  });

  factory News.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic> sourceForStockData = {};

    if (json.containsKey('topImpactStockRank') &&
        (json['topImpactStockRank'] as List).isNotEmpty) {
      sourceForStockData = (json['topImpactStockRank'] as List).first;
    } else if (json.containsKey('stockInfo') && json['stockInfo'] != null) {
      sourceForStockData = json['stockInfo'];
    } else {
      sourceForStockData = json;
    }

    final sentiment = (json['sentiment'] ?? '').toString().toUpperCase();
    final double localInfluenceScore = (sourceForStockData['influenceScore'] ??
        0.0).toDouble();

    String formattedDate = '';
    if (json['publishedDate'] != null) {
      try {
        DateTime parsedDate = DateTime.parse(json['publishedDate']);
        formattedDate = DateFormat('yyyy.MM.dd').format(parsedDate);
      } catch (e) {
        formattedDate = '날짜 없음';
      }
    }

    String predictionText = localInfluenceScore >= 0
        ? "+${localInfluenceScore.toStringAsFixed(2)}%"
        : "${localInfluenceScore.toStringAsFixed(2)}%";

    double priceChangeValue = (sourceForStockData['priceChange'] ?? 0.0)
        .toDouble();
    String priceChangeText = priceChangeValue >= 0
        ? "+${priceChangeValue.toStringAsFixed(2)}%"
        : "${priceChangeValue.toStringAsFixed(2)}%";

    String formattedCurrentPrice = ''; // 기본값
    final priceValue = sourceForStockData['currentPrice'];
    // currentPrice가 null이 아니고, 비어있지 않은 문자열일 경우에만 포매팅
    if (priceValue != null && priceValue.toString().isNotEmpty) {
      num priceNum = num.tryParse(priceValue.toString()) ?? 0;
      final formatter = NumberFormat('#,###');
      // "원"을 여기서 추가합니다.
      formattedCurrentPrice = '${formatter.format(priceNum.toInt())}원';
    }

    return News(
      newsId: json['newsId'] ?? 0,
      newsImage: json['newsImage'] ?? '',
      newsTitle: json['newsTitle'] ?? '',
      dateSource: "${json['press'] ?? '정보 없음'} | $formattedDate",
      isBookmarked: json['scrapped'] ?? false,
      isGoodNews: sentiment == 'POSITIVE',
      summary: json['reason'],
      newsUrl: json['newsUrl'],
      companyLogo: sourceForStockData['stockImage'] ?? '',
      companyName: sourceForStockData['stockName'] ?? '',
      currentPrice: formattedCurrentPrice,
      priceChange: priceChangeText,
      prediction: predictionText,
      influenceScore: localInfluenceScore, // 원시 데이터 저장
    );
  }
}