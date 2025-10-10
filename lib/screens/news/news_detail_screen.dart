import 'package:flutter/material.dart';
import '../lounge/create_post_screen.dart';
import '../../models/news_model.dart';
import '../../models/topstock_model.dart';
import '../../services/api_service.dart';

class NewsDetailScreen extends StatefulWidget {
  final News news;

  const NewsDetailScreen({super.key, required this.news});

  @override
  State<NewsDetailScreen> createState() => _NewsDetailScreenState();
}

class _NewsDetailScreenState extends State<NewsDetailScreen> {
  late bool _isBookmarked;
  late Future<List<TopStock>> _topStocksFuture;

  @override
  void initState() {
    super.initState();
    _isBookmarked = widget.news.isBookmarked;
    _topStocksFuture = ApiService().fetchTopStocks(widget.news.newsId);
  }

  Future<void> _toggleBookmark() async {
    setState(() {
      _isBookmarked = !_isBookmarked;
      widget.news.isBookmarked = _isBookmarked;
    });

    try {
      await ApiService().updateBookmarkStatus(widget.news.newsId, _isBookmarked);
    } catch (e) {
      setState(() {
        _isBookmarked = !_isBookmarked;
        widget.news.isBookmarked = _isBookmarked;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('북마크 상태 저장 실패')),
      );
    }
  }

  void _showSummary() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.4,
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                '뉴스 요약',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text(
                widget.news.summary ?? '요약 정보가 없습니다.',
                style: const TextStyle(fontWeight: FontWeight.bold),
                textAlign: TextAlign.left,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToDiscussion() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CreatePostScreen(newsData: widget.news),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final news = widget.news;
    bool isPriceUp =
        (double.tryParse(news.priceChange.replaceAll(RegExp(r'[^\d.-]'), '')) ?? 0) > 0;
    Color positiveColor = const Color(0xFFF04E52);
    Color negativeColor = const Color(0xFF3687F6);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          _buildAppBarAction(Icons.article, '뉴스요약', _showSummary),
          _buildAppBarAction(Icons.chat_bubble, '토론하기', _navigateToDiscussion),
          IconButton(
            icon: Icon(
              _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
              color: _isBookmarked ? const Color(0xFF2B3A66) : Colors.grey,
              size: 35,
            ),
            onPressed: _toggleBookmark,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        children: [
          _buildHeaderImage(news, positiveColor, negativeColor, isPriceUp),
          _buildPredictionSection(news, positiveColor),
          FutureBuilder<List<TopStock>>(
            future: _topStocksFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('주식 정보 로드 실패: ${snapshot.error}'));
              }
              final topStocks = snapshot.data ?? [];
              if (topStocks.isEmpty) {
                return const Center(child: Text('예측 등락률 TOP 종목 정보가 없습니다.'));
              }
              return _buildTopStocksSection(topStocks);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAppBarAction(IconData icon, String label, VoidCallback onPressed) {
    return InkWell(
      onTap: onPressed,
      child: Container(
        height: kToolbarHeight,
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 4),
            Icon(icon, color: const Color(0xFF2B3A66), size: 28),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF2B3A66),
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderImage(
      News news, Color positiveColor, Color negativeColor, bool isPriceUp) {
    return Stack(
      children: [
        Container(
          height: 300,
          width: double.infinity,
          color: Colors.grey[300],
          child: news.newsImage.isNotEmpty
              ? Image.network(
            news.newsImage,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
            const Center(child: Icon(Icons.broken_image, size: 60, color: Colors.grey)),
          )
              : const Center(child: Icon(Icons.broken_image, size: 60, color: Colors.grey)),
        ),
        Container(
          height: 300,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [Colors.black.withOpacity(0.8), Colors.transparent],
              stops: const [0.0, 0.6],
            ),
          ),
        ),
        Positioned(
          bottom: 16,
          left: 16,
          right: 16,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
              const SizedBox(height: 8),
              Text(news.newsTitle,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 23, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(news.dateSource,
                  style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
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
                            errorBuilder: (context, error, stackTrace) {
                              if (news.companyName.isNotEmpty) {
                                return Text(news.companyName.substring(0, 1));
                              }
                              return const SizedBox.shrink();
                            },
                          )
                              : const SizedBox.shrink(),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(news.companyName,
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 8),
                      Text(news.currentPrice,
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 4),
                      Text(news.priceChange,
                          style: TextStyle(
                              color: isPriceUp ? positiveColor : negativeColor,
                              fontSize: 12,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const Text('원문 기사 바로가기 >',
                      style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              )
            ],
          ),
        )
      ],
    );
  }

  Widget _buildPredictionSection(News news, Color positiveColor) {
    bool isPredictionPositive = news.isPredictionPositive;
    Color predictionColor = isPredictionPositive ? positiveColor : const Color(0xFF3687F6);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.sentiment_satisfied_alt, color: Color(0xFF2B3A66), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: const TextStyle(color: Colors.black, fontSize: 15, fontFamily: 'Pretendard', fontWeight: FontWeight.bold),
                    children: [
                      const TextSpan(
                        text: 'StorkPulse',
                        style: TextStyle(color: Color(0xFF2B3A66)),
                      ),
                      const TextSpan(text: '는 '),
                      TextSpan(
                        text: '"${news.companyName}"',
                        style: const TextStyle(color: Color(0xFFFEB12C)),
                      ),
                      const TextSpan(text: ' 주가가 '),
                      TextSpan(
                        text: '${news.prediction} ',
                        style: TextStyle(color: predictionColor),
                      ),
                      const TextSpan(text: '될 것으로 예측합니다!'),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '이번 "${news.newsTitle}" 기사 분석 결과, ${news.companyName}의 주가에 ${isPredictionPositive ? '긍정적인' : '부정적인'} 영향을 미칠 것으로 예상됩니다. 특히 해당 이슈가 시장에 미치는 파급 효과와 투자자들의 반응 등을 종합적으로 고려하여 ${news.prediction}의 변동을 예측합니다.',
                  style: const TextStyle(color: Colors.black54, fontSize: 12, height: 1.5, fontWeight: FontWeight.bold),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildTopStocksSection(List<TopStock> topStocks) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('기사 기반 예측 등락률 TOP 종목', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...topStocks.map((stock) => _buildTopStockItem(stock)).toList(),
        ],
      ),
    );
  }

  Widget _buildTopStockItem(TopStock stock) {
    const Color positiveColor = Color(0xFFF04E52);
    const Color negativeColor = Color(0xFF3687F6);
    final bool isPredictionPositive = !stock.prediction.startsWith('-');

    final BoxDecoration? decoration = stock.rank == '1'
        ? BoxDecoration(
      color: const Color(0xFFF7F9FF),
      borderRadius: BorderRadius.circular(8),
    )
        : null;

    return Container(
      decoration: decoration,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 12.0),
        child: Row(
          children: [
            Text(stock.rank, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(width: 16),
            CircleAvatar(
              radius: 17,
              backgroundColor: Colors.transparent,
              child: ClipOval(
                child: Image.network(
                  stock.imageUrl,
                  width: 30,
                  height: 30,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    if (stock.name.isNotEmpty) {
                      return Text(stock.name.substring(0, 1));
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(stock.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  Row(
                    children: [
                      Text(stock.price, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 8),
                      Text(
                        stock.change,
                        style: TextStyle(
                          fontSize: 12,
                          color: stock.change.startsWith('+') ? positiveColor : negativeColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            RichText(
              text: TextSpan(
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black, fontFamily: 'Pretendard'),
                children: [
                  TextSpan(text: isPredictionPositive ? '📈최대 ' : '📉최소 '),
                  TextSpan(
                    text: stock.prediction,
                    style: TextStyle(color: isPredictionPositive ? positiveColor : negativeColor),
                  ),
                  TextSpan(text: isPredictionPositive ? ' 상승 예측' : ' 하락 예측'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}