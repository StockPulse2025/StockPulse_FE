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
  final ApiService _apiService = ApiService();
  List<News>? _bookmarkedNews;
  String? _errorMessage;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBookmarkedNews();
  }

  Future<void> _loadBookmarkedNews() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final news = await _apiService.fetchNewsWithFilter(
        favoriteStock: true, // 스크랩된 뉴스만 가져오도록 설정
        allStock: false,
      );
      setState(() {
        _bookmarkedNews = news;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = '스크랩한 뉴스를 불러오지 못했습니다.\n$e';
        _isLoading = false;
      });
    }
  }

  void _navigateToDetail(News news) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => NewsDetailScreen(newsId: news.newsId)),
    ).then((_) {
      // 상세 화면에서 돌아왔을 때 목록을 새로고침하여
      // 스크랩 상태 변경이 있었을 경우 반영
      _loadBookmarkedNews();
    });
  }

  Future<void> _unScrapNews(int newsId) async {
    if (_bookmarkedNews == null) return;

    final index = _bookmarkedNews!.indexWhere((news) => news.newsId == newsId);
    if (index == -1) return;

    // 낙관적 업데이트: UI에서 먼저 제거
    final removedNews = _bookmarkedNews!.removeAt(index);
    setState(() {});

    try {
      // API 호출하여 서버 상태 변경
      await _apiService.updateBookmarkStatus(newsId);
    } catch (e) {
      // API 호출 실패 시, 제거했던 뉴스를 다시 목록에 추가
      setState(() {
        _bookmarkedNews!.insert(index, removedNews);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('스크랩 해제에 실패했습니다.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 1,
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
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null) {
      return Center(child: Text(_errorMessage!));
    }
    if (_bookmarkedNews == null || _bookmarkedNews!.isEmpty) {
      return const Center(child: Text('스크랩한 뉴스가 없습니다.'));
    }

    return RefreshIndicator(
      onRefresh: _loadBookmarkedNews,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        itemCount: _bookmarkedNews!.length,
        itemBuilder: (context, index) {
          final newsItem = _bookmarkedNews![index];
          return GestureDetector(
            onTap: () => _navigateToDetail(newsItem),
            child: NewsCard(
              news: newsItem,
              // 스크랩 화면의 뉴스 카드는 클릭 시 스크랩 해제 기능만 수행
              onBookmarkToggle: () => _unScrapNews(newsItem.newsId),
            ),
          );
        },
      ),
    );
  }
}