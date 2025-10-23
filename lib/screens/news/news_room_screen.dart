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
  final ApiService _apiService = ApiService();
  News? _mainNews;
  List<News>? _newsList;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _refreshNews();
  }

  Future<void> _refreshNews({Map<String, dynamic>? filter}) async {
    setState(() {
      // 로딩 상태로 초기화
      _mainNews = null;
      _newsList = null;
      _errorMessage = '';
    });

    try {
      // 메인 뉴스와 필터링된 뉴스 목록을 동시에 요청
      final results = await Future.wait([
        _apiService.fetchMainNews(),
        _apiService.fetchNewsWithFilter(
          sort: filter?['sort'] ?? 'LATEST',
          allStock: filter?['allStock'] ?? true,
          ownedStock: filter?['ownedStock'] ?? false,
          favoriteStock: filter?['favoriteStock'] ?? false,
          industries: filter?['industries'] ?? [],
        ),
      ]);
      setState(() {
        _mainNews = results[0] as News;
        _newsList = results[1] as List<News>;
      });
    } catch (e) {
      setState(() {
        _errorMessage = '뉴스 로딩에 실패했습니다: $e';
      });
    }
  }

  void _showFilter() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const FilterBottomSheet(),
    ).then((filterResult) {
      if (filterResult != null) {
        // 필터 결과로 목록만 새로고침
        _applyFilter(filterResult);
      }
    });
  }

  Future<void> _applyFilter(Map<String, dynamic> filterResult) async {
    setState(() {
      _newsList = null; // 목록만 로딩 상태로 변경
    });
    try {
      final filteredList = await _apiService.fetchNewsWithFilter(
        sort: filterResult['sort'],
        allStock: filterResult['allStock'],
        ownedStock: filterResult['ownedStock'],
        favoriteStock: filterResult['favoriteStock'],
        industries: filterResult['industries'],
      );
      setState(() {
        _newsList = filteredList;
      });
    } catch (e) {
      setState(() {
        _errorMessage = '뉴스 필터링에 실패했습니다: $e';
      });
    }
  }

  void _navigateToDetail(int newsId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => NewsDetailScreen(newsId: newsId),
      ),
    );
  }

  Future<void> _toggleBookmark(int newsId) async {
    // 업데이트할 뉴스를 메인 뉴스와 목록에서 찾음
    News? targetNews;
    int? listIndex;

    if (_mainNews?.newsId == newsId) {
      targetNews = _mainNews;
    }
    if (_newsList != null) {
      final index = _newsList!.indexWhere((news) => news.newsId == newsId);
      if (index != -1) {
        targetNews = _newsList![index];
        listIndex = index;
      }
    }

    if (targetNews == null) return;

    final originalBookmarkStatus = targetNews.isBookmarked;

    // UI 즉시 업데이트
    setState(() {
      targetNews!.isBookmarked = !originalBookmarkStatus;
      if (listIndex != null) {
        _newsList![listIndex] = targetNews;
      }
      if (_mainNews?.newsId == newsId) {
        _mainNews = targetNews;
      }
    });

    try {
      final newStatus = await _apiService.updateBookmarkStatus(newsId);
      // 서버 응답과 UI 상태가 다를 경우 서버 응답에 맞춰 동기화
      if (targetNews.isBookmarked != newStatus) {
        setState(() {
          targetNews!.isBookmarked = newStatus;
          if (listIndex != null) {
            _newsList![listIndex] = targetNews;
          }
          if (_mainNews?.newsId == newsId) {
            _mainNews = targetNews;
          }
        });
      }
    } catch (e) {
      // 에러 발생 시 원래 상태로 복구
      setState(() {
        targetNews!.isBookmarked = originalBookmarkStatus;
        if (listIndex != null) {
          _newsList![listIndex] = targetNews;
        }
        if (_mainNews?.newsId == newsId) {
          _mainNews = targetNews;
        }
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
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_mainNews == null || _newsList == null) {
      if (_errorMessage.isNotEmpty) {
        return Center(child: Text(_errorMessage));
      }
      return const Center(child: CircularProgressIndicator());
    }

    // 메인 뉴스가 목록에 중복으로 나타나지 않도록 필터링
    final displayList = _newsList!.where((news) => news.newsId != _mainNews!.newsId).toList();

    return RefreshIndicator(
      onRefresh: _refreshNews,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        itemCount: displayList.length + 1, // 메인 뉴스 카드 포함
        itemBuilder: (context, index) {
          if (index == 0) {
            return GestureDetector(
              onTap: () => _navigateToDetail(_mainNews!.newsId),
              child: _buildFeaturedNewsCard(_mainNews!),
            );
          }
          final newsItem = displayList[index - 1];
          return GestureDetector(
            onTap: () => _navigateToDetail(newsItem.newsId),
            child: NewsCard(
              news: newsItem,
              onBookmarkToggle: () => _toggleBookmark(newsItem.newsId),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFeaturedNewsCard(News news) {
    const Color positiveColor = Color(0xFFF04E52);
    const Color negativeColor = Color(0xFF3687F6);
    final priceChangeStr = news.priceChange.replaceAll(RegExp(r'[^\d.-]'), '');
    bool isPriceUp = (double.tryParse(priceChangeStr) ?? 0) > 0;
    final bool hasStockInfo = news.companyName.isNotEmpty;

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
          if (news.prediction.isNotEmpty)
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
                color: news.isBookmarked ? Colors.yellow : Colors.white,
              ),
              onPressed: () => _toggleBookmark(news.newsId), // 수정된 부분
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
                      if (hasStockInfo) ...[
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
                              errorBuilder: (context, error, stackTrace) =>
                                  Text(news.companyName.isNotEmpty ? news.companyName.substring(0, 1) : ''),
                            )
                                : const SizedBox.shrink(),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Row(
                            children: [
                              Flexible(child: Text(news.companyName, style: const TextStyle(color: Color(0xFFC2C2C2), fontWeight: FontWeight.bold, fontSize: 11), overflow: TextOverflow.ellipsis,)),
                              const SizedBox(width: 4),
                              Text(news.currentPrice, style: const TextStyle(color: Color(0xFFC2C2C2), fontWeight: FontWeight.bold, fontSize: 9)),
                              const SizedBox(width: 4),
                              Text(news.priceChange, style: TextStyle(color: isPriceUp ? positiveColor : negativeColor, fontWeight: FontWeight.bold, fontSize: 9)),
                            ],
                          ),
                        ),
                      ],
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