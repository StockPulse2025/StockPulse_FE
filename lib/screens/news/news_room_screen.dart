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
  // 메인 뉴스와 뉴스 목록을 별도의 Future로 관리
  late Future<News> mainNewsFuture;
  late Future<List<News>> newsListFuture;

  @override
  void initState() {
    super.initState();
    // 두 API를 동시에 호출
    mainNewsFuture = ApiService().fetchMainNews();
    newsListFuture = ApiService().fetchNewsWithFilter();
  }

  // 데이터를 새로고침하는 함수
  void _refreshNews() {
    setState(() {
      mainNewsFuture = ApiService().fetchMainNews();
      newsListFuture = ApiService().fetchNewsWithFilter();
    });
  }

  void _showFilter() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const FilterBottomSheet(),
    ).then((filterResult) {
      // FilterBottomSheet가 닫히면서 필터 값을 전달하면, 해당 값으로 API를 호출
      if (filterResult != null) {
        setState(() {
          // 메인 뉴스는 고정, 목록만 필터링된 결과로 새로고침
          newsListFuture = ApiService().fetchNewsWithFilter(
            sort: filterResult['sort'],
            allStock: filterResult['allStock'],
            ownedStock: filterResult['ownedStock'],
            favoriteStock: filterResult['favoriteStock'],
            industries: filterResult['industries'],
          );
        });
      }
    });
  }

  void _navigateToDetail(News news) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => NewsDetailScreen(newsId: news.newsId),
      ),
    );
  }

  Future<void> _toggleBookmark(News news) async {
    final originalBookmarkStatus = news.isBookmarked; // 에러 발생 시 복구를 위해 원래 상태 저장

    setState(() {
      news.isBookmarked = !news.isBookmarked;
    });

    try {
     final newStatus = await ApiService().updateBookmarkStatus(news.newsId);
      setState(() {
        news.isBookmarked = newStatus;
      });
    } catch (e) {
      // 에러 발생 시 상태를 원래대로
      setState(() {
        news.isBookmarked = originalBookmarkStatus;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("북마크 상태 변경에 실패했습니다.")),
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
        title: const Text('뉴스룸', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.tune, color: Colors.black),
            onPressed: _showFilter,
          ),
        ],
      ),
      body: FutureBuilder<News>(
        future: mainNewsFuture,
        builder: (context, mainNewsSnapshot) {
          if (mainNewsSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (mainNewsSnapshot.hasError) {
            return Center(child: Text('메인 뉴스 로드 실패: ${mainNewsSnapshot.error}'));
          }
          final mainNews = mainNewsSnapshot.data!;

          return FutureBuilder<List<News>>(
            future: newsListFuture,
            builder: (context, newsListSnapshot) {
              if (newsListSnapshot.connectionState == ConnectionState.waiting) {
                // 메인 뉴스는 이미 로드, 목록 로딩 중에도 보여줄 수 있음
                return SingleChildScrollView(
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: () => _navigateToDetail(mainNews),
                        child: _buildFeaturedNewsCard(mainNews),
                      ),
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    ],
                  ),
                );
              }
              if (newsListSnapshot.hasError) {
                return Center(child: Text('뉴스 목록 로드 실패: ${newsListSnapshot.error}'));
              }
              final newsList = newsListSnapshot.data ?? [];

              return ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                itemCount: newsList.length,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    // 메인 뉴스는 별도로 로드 완료, 이제 mainNews 변수 사용
                    return GestureDetector(
                      onTap: () => _navigateToDetail(mainNews),
                      child: _buildFeaturedNewsCard(mainNews),
                    );
                  }
                  if (newsList[index].newsId == mainNews.newsId) {
                    return const SizedBox.shrink();
                  }
                  final newsItem = newsList[index];
                  return GestureDetector(
                    onTap: () => _navigateToDetail(newsItem),
                    child: NewsCard(news: newsItem),
                  );
                },
              );
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
            child: news.newsImage.isNotEmpty
                ? Image.network(
              news.newsImage,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                color: Colors.grey[300],
                child: const Center(
                  child: Icon(Icons.broken_image, color: Colors.grey),
                ),
              ),
            )
                : Container(
              color: Colors.grey[300],
              child: const Center(
                child: Icon(Icons.broken_image, color: Colors.grey),
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
            child: IconButton(
              icon: Icon(
                  news.isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                  color: news.isBookmarked ? Colors.yellow : Colors.white
              ),
              onPressed: () => _toggleBookmark(news),
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
                          child: news.companyLogo.isNotEmpty
                              ? Image.network(
                            news.companyLogo,
                            width: 20,
                            height: 20,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Text(news.companyName.isNotEmpty ? news.companyName.substring(0, 1) : ''),
                          )
                              : const SizedBox.shrink(),
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
}