import 'dart:math';
import '../models/news_model.dart';
import 'dummy_news_data.dart';

// 6개월 (약 180일) 분량의 일봉 데이터 생성 함수
List<Map<String, dynamic>> generateSamsungCandleData() {
  final List<Map<String, dynamic>> data = [];
  final Random random = Random();
  double lastClose = 72000;
  final DateTime today = DateTime(2025, 8, 28);

  for (int i = 0; i < 180; i++) {
    final DateTime date = today.subtract(Duration(days: i));
    if (date.weekday == DateTime.saturday || date.weekday == DateTime.sunday) {
      continue;
    }
    final double open = lastClose;
    final double high = open * (1 + (random.nextDouble() * 0.04));
    final double low = open * (1 - (random.nextDouble() * 0.04));
    final double close = low + random.nextDouble() * (high - low);

    data.add({'date': date, 'high': high, 'low': low, 'open': open, 'close': close});
    lastClose = close;
  }
  return data.reversed.toList();
}

// 특정 날짜와 연관된 뉴스 ID 목록
final Map<DateTime, List<int>> newsForDate = {
  DateTime(2025, 8, 28): [15, 16, 17],
  DateTime(2025, 8, 25): [11, 12],
  DateTime(2025, 8, 20): [13, 14],
  DateTime(2025, 8, 11): [18, 19],
  DateTime(2025, 7, 10): [20, 21],
};

// 특정 날짜에 해당하는 뉴스 목록을 반환하는 함수
List<News> getNewsForDate(DateTime date) {
  final targetDate = DateTime(date.year, date.month, date.day);
  final newsIds = newsForDate[targetDate];

  if (newsIds == null) return [];

  return dummyNews.where((news) => newsIds.contains(news.id)).toList();
}

// 특정 기간에 해당하는 모든 뉴스 목록을 반환하는 함수
List<News> getNewsForPeriod(DateTime start, DateTime end) {
  List<int> allNewsIds = [];
  newsForDate.forEach((date, ids) {
    final targetDate = DateTime(date.year, date.month, date.day);
    if (!targetDate.isBefore(start) && !targetDate.isAfter(end)) {
      allNewsIds.addAll(ids);
    }
  });

  final uniqueIds = allNewsIds.toSet().toList();
  if (uniqueIds.isEmpty) return [];

  return dummyNews.where((news) => uniqueIds.contains(news.id)).toList();
}