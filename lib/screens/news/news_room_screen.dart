import 'package:flutter/material.dart';
import '../../widgets/news/filter_bottom_sheet.dart';
import 'news_detail_screen.dart';
import '../../widgets/news/news_card.dart';
import '../../models/news_model.dart';
import '../../services/api_service.dart';

class NewsRoomScreen extends StatefulWidget {
  const NewsRoomScreen({super.key});

  @override
  State<NewsRoomScreen> createState() => _NewsRoomScreenState();
}

class _NewsRoomScreenState extends State<NewsRoomScreen> {
  int _currentPage = 1;
  final int _totalPages = 25;
  late Future<List<News>> newsFuture;

  @override
  void initState() {
    super.initState();
    newsFuture = ApiService().fetchNewsByPage(_currentPage);
  }

  Future<void> _goToPage(int page) async {
    if (page < 1 || page > _totalPages) return;
    setState(() {
      _currentPage = page;
      newsFuture = ApiService().fetchNewsByPage(_currentPage);
    });
  }

  void _jumpPages(int amount) {
    _goToPage(_currentPage + amount);
  }

  void _showFilter() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const FilterBottomSheet(),
    );
  }

  void _navigateToDetail(News news) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => NewsDetailScreen(news: news)),
    );
  }

  Future<void> _toggleBookmark(News news) async {
    setState(() {
      news.isBookmarked = !news.isBookmarked;
    });

    try {
      // 서버에 북마크 상태 변경 전송
      await ApiService().updateBookmarkStatus(news.newsId, news.isBookmarked);
    } catch (e) {
      // 에러 발생 시 상태 원복
      setState(() {
        news.isBookmarked = !news.isBookmarked;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("북마크 저장 실패")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: const Text('뉴스룸', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.tune, color: Colors.black),
            onPressed: _showFilter,
          ),
        ],
      ),
      body: FutureBuilder<List<News>>(
        future: newsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('뉴스 로드 실패: ${snapshot.error}'));
          }
          final newsList = snapshot.data ?? [];
          if (newsList.isEmpty) return const Center(child: Text("뉴스가 없습니다."));

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            itemCount: newsList.length + 1,
            itemBuilder: (context, index) {
              if (index == 0 && _currentPage == 1) {
                final News firstNews = newsList[0];
                return GestureDetector(
                  onTap: () => _navigateToDetail(firstNews),
                  child: _buildFeaturedNewsCard(firstNews),
                );
              } else if (index == newsList.length) {
                return _buildPagination();
              } else {
                final News newsItem = newsList[index];
                return GestureDetector(
                  onTap: () => _navigateToDetail(newsItem),
                  child: Stack(
                    children: [
                      NewsCard(news: newsItem),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: IconButton(
                          icon: Icon(
                            newsItem.isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                            color: newsItem.isBookmarked ? Colors.yellow : Colors.grey,
                          ),
                          onPressed: () => _toggleBookmark(newsItem),
                        ),
                      ),
                    ],
                  ),
                );
              }
            },
          );
        },
      ),
    );
  }

  Widget _buildFeaturedNewsCard(News news) {
    const Color positiveColor = Color(0xFFF04E52);
    const Color negativeColor = Color(0xFF3687F6);
    bool isPriceUp = (double.tryParse(news.priceChange.replaceAll(RegExp(r'[^\d.-]'), '')) ?? 0) > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      height: 250,
      decoration: BoxDecoration(
        color: Colors.grey[200],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.network(
              news.newsImage,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                color: Colors.grey[300],
                child: const Center(
                  child: Icon(Icons.broken_image, color: Colors.grey),
                ),
              ),
            ),
          ),

          Positioned(
            top: 10,
            left: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: news.isPredictionPositive ? const Color(0xFFF9B8B0) : const Color(0xFF95C1FF),
                borderRadius: BorderRadius.circular(5.0),
              ),
              child: RichText(
                text: TextSpan(
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, fontFamily: 'Pretendard'),
                  children: [
                    const TextSpan(
                      text: '예측주가 ',
                      style: TextStyle(color: Colors.black),
                    ),
                    TextSpan(
                      text: news.prediction,
                      style: TextStyle(
                        color: news.isPredictionPositive ? const Color(0xFFFF0000) : const Color(0xFF0042FF),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          Positioned(
            top: 10,
            right: 10,
            child: Container(
              child: IconButton(
                icon: const Icon(Icons.bookmark_border, color: Colors.white),
                onPressed: () {
                  // 북마크 기능 추가 예정
                },
              ),
            ),
          ),

          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: news.isGoodNews ? const Color(0xFFF3C6C8) : const Color(0xFFC6D1F3),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          news.isGoodNews ? '📈호재' : '📉악재',
                          style: const TextStyle(
                            color: Color(0xFF7C7C7C),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      CircleAvatar(
                        radius: 10,
                        backgroundColor: Colors.transparent,
                        child: ClipOval(
                          child: Image.network(
                            news.companyLogo,
                            width: 20,
                            height: 20,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Text(news.companyName.isNotEmpty ? news.companyName.substring(0, 1) : ''),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Row(
                          children: [
                            Text(news.companyName, style: const TextStyle(color: Color(0xFFC2C2C2), fontWeight: FontWeight.bold, fontSize: 11)),
                            const SizedBox(width: 4),
                            Text(news.currentPrice, style: const TextStyle(color: Color(0xFFC2C2C2), fontWeight: FontWeight.bold, fontSize: 9)),
                            const SizedBox(width: 4),
                            Text(news.priceChange, style: TextStyle(color: isPriceUp ? positiveColor : negativeColor, fontWeight: FontWeight.bold, fontSize: 9)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    news.newsTitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    news.dateSource,
                    style: const TextStyle(color: Color(0xFFC2C2C2), fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPagination() {
    const Color selectedColor = Color(0xFF2B3A66);
    const Color unselectedColor = Color(0xFFACB0BF);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
              icon: const Icon(Icons.keyboard_double_arrow_left),
              color: unselectedColor,
              splashColor: selectedColor.withOpacity(0.2),
              highlightColor: selectedColor.withOpacity(0.1),
              onPressed: () => _jumpPages(-10),
              visualDensity: VisualDensity.compact
          ),
          IconButton(
              icon: const Icon(Icons.keyboard_arrow_left),
              color: unselectedColor,
              splashColor: selectedColor.withOpacity(0.2),
              highlightColor: selectedColor.withOpacity(0.1),
              onPressed: () => _jumpPages(-1),
              visualDensity: VisualDensity.compact
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text.rich(
                TextSpan(
                    style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Pretendard'),
                    children: [
                      TextSpan(
                        text: '$_currentPage', // 현재 페이지
                        style: const TextStyle(color: selectedColor, fontSize: 14),
                      ),
                      TextSpan(
                        text: ' / $_totalPages', // 총 페이지
                        style: const TextStyle(color: unselectedColor, fontSize: 14),
                      ),
                    ]
                )
            ),
          ),

          IconButton(
              icon: const Icon(Icons.keyboard_arrow_right),
              color: unselectedColor,
              splashColor: selectedColor.withOpacity(0.2),
              highlightColor: selectedColor.withOpacity(0.1),
              onPressed: () => _jumpPages(1),
              visualDensity: VisualDensity.compact
          ),
          IconButton(
              icon: const Icon(Icons.keyboard_double_arrow_right),
              color: unselectedColor,
              splashColor: selectedColor.withOpacity(0.2),
              highlightColor: selectedColor.withOpacity(0.1),
              onPressed: () => _jumpPages(10),
              visualDensity: VisualDensity.compact
          ),
        ],
      ),
    );
  }
}
