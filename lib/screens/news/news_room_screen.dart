import 'package:flutter/material.dart';
import '../../widgets/news/filter_bottom_sheet.dart';
import 'news_detail_screen.dart';
import '../../widgets/news/news_card.dart';
import '../../data/dummy_news_data.dart';
import '../../models/news_model.dart';

class NewsRoomScreen extends StatefulWidget {
  const NewsRoomScreen({super.key});

  @override
  State<NewsRoomScreen> createState() => _NewsRoomScreenState();
}

class _NewsRoomScreenState extends State<NewsRoomScreen> {
  int _currentPage = 1;
  final int _totalPages = 25;
  List<News> _currentNewsList = [];

  @override
  void initState() {
    super.initState();
    _updateNewsListForPage();
  }

  void _updateNewsListForPage() {
    const int newsCountPerPage = 10;
    final int startIndex = (_currentPage - 1) * newsCountPerPage;
    final int endIndex = startIndex + newsCountPerPage;

    setState(() {
      _currentNewsList = dummyNews.sublist(
        startIndex.clamp(0, dummyNews.length),
        endIndex.clamp(0, dummyNews.length),
      );
    });
  }

  void _goToPage(int page) {
    setState(() {
      _currentPage = page.clamp(1, _totalPages);
      _updateNewsListForPage();
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
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        itemCount: _currentNewsList.length + 1,
        itemBuilder: (context, index) {
          if (_currentNewsList.isEmpty) {
            return const Center(child: Text("뉴스가 없습니다."));
          }

          if (index == 0 && _currentPage == 1) {
            final News firstNews = _currentNewsList[0];
            return GestureDetector(
              onTap: () => _navigateToDetail(firstNews),
              child: _buildFeaturedNewsCard(firstNews),
            );
          } else if (index == _currentNewsList.length) {
            return _buildPagination();
          } else {
             final News newsItem = _currentPage == 1 ? _currentNewsList[index] : _currentNewsList[index];
            return GestureDetector(
              onTap: () => _navigateToDetail(newsItem),
              child: NewsCard(news: newsItem),
            );
          }
        },
      ),
    );
  }

  Widget _buildFeaturedNewsCard(News news) {
    const Color positiveColor = Color(0xFFF04E52);
    const Color negativeColor = Color(0xFF3687F6);
    bool isPriceUp = double.parse(news.priceChange.replaceAll(RegExp(r'[^\d.-]'), '')) > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      height: 250,
      decoration: BoxDecoration(
        color: Colors.grey[200],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              news.imageUrl,
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
                          child: Image.asset(
                            news.companyLogoUrl,
                            width: 20,
                            height: 20,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Text(news.companyName.substring(0, 1)),
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
                    news.title,
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