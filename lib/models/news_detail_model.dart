import 'news_model.dart';
import 'topstock_model.dart';

class NewsDetail {
  final News newsInfo;
  final List<TopStock> topStocks;

  NewsDetail({required this.newsInfo, required this.topStocks});

  factory NewsDetail.fromJson(Map<String, dynamic> json) {
    final newsData = News.fromJson(json);

    final topStocksList = (json['topImpactStockRank'] as List? ?? [])
        .map((stockJson) => TopStock.fromJson(stockJson))
        .toList();

    return NewsDetail(
      newsInfo: newsData,
      topStocks: topStocksList,
    );
  }
}