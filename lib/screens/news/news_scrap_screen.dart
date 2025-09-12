import 'package:flutter/material.dart';
import '../../widgets/news/news_card.dart';
import 'news_detail_screen.dart';
import '../../data/dummy_news_data.dart'; // 더미 데이터 임포트
import '../../models/news_model.dart'; // News 모델 임포트

class NewsScrapScreen extends StatelessWidget {
  const NewsScrapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 더미 뉴스 데이터에서 isBookmarkedInitially가 true인 뉴스만 필터링합니다.
    // 실제 앱에서는 사용자가 스크랩한 뉴스 목록을 서버에서 가져오거나 로컬 저장소에서 관리할 것입니다.
    final List<News> bookmarkedNews = dummyNews.where((news) => news.isBookmarkedInitially).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        titleSpacing: 0,
        centerTitle: false,
        title: const Text(
            '뉴스 스크랩',
            style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold
            )
        ),
      ),
      body: bookmarkedNews.isEmpty
          ? const Center(child: Text('스크랩한 뉴스가 없습니다.')) // 스크랩된 뉴스가 없을 경우
          : ListView.builder(
        itemCount: bookmarkedNews.length, // 필터링된 뉴스 개수만큼
        itemBuilder: (context, index) {
          final News newsItem = bookmarkedNews[index];
          return GestureDetector(
            onTap: () {
              // NewsDetailScreen으로 이동할 때 해당 뉴스 객체를 전달합니다.
              Navigator.of(context).push(MaterialPageRoute(builder: (context) => NewsDetailScreen(news: newsItem)));
            },
            // NewsCard에 실제 뉴스 데이터를 전달하고, isBookmarkedInitially는 newsItem의 값을 따릅니다.
            child: NewsCard(news: newsItem),
          );
        },
      ),
    );
  }
}