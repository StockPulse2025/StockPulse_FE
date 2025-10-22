import 'news_model.dart';
import 'topstock_model.dart';

class NewsDetail {
  final News newsInfo;
  final List<TopStock> topStocks;

  NewsDetail({required this.newsInfo, required this.topStocks});

  factory NewsDetail.fromJson(Map<String, dynamic> json) {
    // 뉴스 정보 부분은 News.fromJson을 재활용하여 파싱
    final newsData = News.fromJson(json);

    // topImpactStockRank 리스트를 파싱하여 List<TopStock>으로 변환
    final topStocksList = (json['topImpactStockRank'] as List? ?? [])
        .map((stockJson) => TopStock.fromJson(stockJson))
        .toList();

    return NewsDetail(
      newsInfo: newsData,
      topStocks: topStocksList,
    );
  }
}