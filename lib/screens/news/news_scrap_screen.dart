import 'package:flutter/material.dart';
import '../../widgets/news/news_card.dart';
import 'news_detail_screen.dart';
import '../../models/news_model.dart';
import '../../services/api_service.dart';

class NewsScrapScreen extends StatefulWidget {
  const NewsScrapScreen({super.key});

  @override
  _NewsScrapScreenState createState() => _NewsScrapScreenState();
}

class _NewsScrapScreenState extends State<NewsScrapScreen> {
  late Future<List<News>> bookmarkedNewsFuture;

  @override
  void initState() {
    super.initState();
    bookmarkedNewsFuture = ApiService().fetchBookmarkedNewsList();
  }

  void _navigateToDetail(News news) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => NewsDetailScreen(news: news)),
    );
  }

  @override
  Widget build(BuildContext context) {
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
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: FutureBuilder<List<News>>(
        future: bookmarkedNewsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('스크랩 뉴스 로드 실패: ${snapshot.error}'));
          }
          final bookmarkedNews = snapshot.data ?? [];
          if (bookmarkedNews.isEmpty) {
            return const Center(child: Text('스크랩한 뉴스가 없습니다.'));
          }

          return ListView.builder(
            itemCount: bookmarkedNews.length,
            itemBuilder: (context, index) {
              final newsItem = bookmarkedNews[index];
              return GestureDetector(
                onTap: () => _navigateToDetail(newsItem),
                child: NewsCard(news: newsItem),
              );
            },
          );
        },
      ),
    );
  }
}
