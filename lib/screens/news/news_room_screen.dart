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
  bool _isLoading = true; // 로딩 상태를 명시적으로 관리

  // --- 1. 필터 상태를 관리할 변수 추가 ---
  Map<String, dynamic>? _currentFilters;

  @override
  void initState() {
    super.initState();
    _refreshNews();
  }

  // --- 2. _refreshNews와 _applyFilter를 통합하여 하나의 함수로 관리 ---
  Future<void> _loadNewsData({bool isRefresh = false}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // isRefresh가 true일 때만 메인 뉴스를 새로고침
      final mainNewsFuture = isRefresh ? _apiService.fetchMainNews() : Future.value(_mainNews);

      // 현재 필터 값을 사용하여 뉴스 목록 요청
      final newsListFuture = _apiService.fetchNewsWithFilter(
        sort: _currentFilters?['sort'] ?? 'LATEST',
        allStock: _currentFilters?['allStock'] ?? true,
        ownedStock: _currentFilters?['ownedStock'] ?? false,
        favoriteStock: _currentFilters?['favoriteStock'] ?? false,
        industries: List<String>.from(_currentFilters?['industries'] ?? []),
        positiveFilter: _currentFilters?['positive'],
        negativeFilter: _currentFilters?['negative'],
        neutralFilter: _currentFilters?['neutral'],
      );

      final results = await Future.wait([mainNewsFuture, newsListFuture]);

      if (mounted) {
        setState(() {
          // isRefresh일 때만 메인 뉴스 업데이트, 아닐 경우 기존 값 유지
          if (isRefresh) {
            _mainNews = results[0] as News?;
          }
          _newsList = results[1] as List<News>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = '뉴스 로딩에 실패했습니다: $e';
          _isLoading = false;
        });
      }
    }
  }

  // 화면 새로고침 (Pull-to-refresh)
  Future<void> _refreshNews() async {
    // 필터 초기화 후 데이터 로드
    setState(() {
      _currentFilters = null;
    });
    await _loadNewsData(isRefresh: true);
  }

  // --- 3. _showFilter 메소드 수정 ---
  void _showFilter() async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        // 필터 시트를 열 때 현재 필터 값을 전달
        return FilterBottomSheet(initialFilters: _currentFilters);
      },
    );

    if (result != null) {
      // 사용자가 '적용하기'를 누르면, 상태를 업데이트하고 뉴스 목록만 다시 로드
      setState(() {
        _currentFilters = result;
      });
      // isRefresh를 false로 하여 메인 뉴스는 새로고침하지 않음
      await _loadNewsData(isRefresh: false);
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
                color: news.isBookmarked ? Color(0xFF2B3A66) : Colors.white,
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