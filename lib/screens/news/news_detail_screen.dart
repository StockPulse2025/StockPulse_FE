import 'package:flutter/material.dart';

import 'package:stockpulse2/models/news_detail_model.dart';
import '../lounge/create_post_screen.dart';
import '../../models/news_model.dart';
import '../../models/topstock_model.dart';
import '../../services/api_service.dart';

class NewsDetailScreen extends StatefulWidget {
  final int newsId;
  const NewsDetailScreen({super.key, required this.newsId});

  @override
  State<NewsDetailScreen> createState() => _NewsDetailScreenState();
}

class _NewsDetailScreenState extends State<NewsDetailScreen> {
  late Future<NewsDetail> _newsDetailFuture;

  @override
  void initState() {
    super.initState();
    _newsDetailFuture = ApiService().fetchNewsDetail(widget.newsId);
  }

  Future<void> _toggleBookmark(News news) async {
    // 서버에 토글 요청
    await ApiService().updateBookmarkStatus(news.newsId);

    // 요청 성공 후 화면 데이터를 새로고침
    if (mounted) {
      setState(() {
        _newsDetailFuture = ApiService().fetchNewsDetail(widget.newsId);
      });
    }
  }

  void _showSummary(News news) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final summaryText = await ApiService().fetchNewsSummary(news.newsId);
      if (!mounted) return;
      Navigator.pop(context); // 로딩 다이얼로그 닫기

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
                  summaryText,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.left,
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // 에러 발생 시에도 로딩 다이얼로그 닫기
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("요약 정보 로드에 실패했습니다: ${e.toString()}")),
      );
    }
  }

  void _navigateToDiscussion(News news) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CreatePostScreen(newsData: news),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<NewsDetail>(
      future: _newsDetailFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(backgroundColor: Colors.white, surfaceTintColor: Colors.white, elevation: 1),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(backgroundColor: Colors.white, surfaceTintColor: Colors.white, elevation: 1),
            body: Center(child: Text('상세 정보를 불러오지 못했습니다: ${snapshot.error}')),
          );
        }
        if (!snapshot.hasData) {
          return Scaffold(
            appBar: AppBar(backgroundColor: Colors.white, surfaceTintColor: Colors.white, elevation: 1),
            body: const Center(child: Text('뉴스 데이터가 없습니다.')),
          );
        }

        final newsDetail = snapshot.data!;
        final news = newsDetail.newsInfo;
        final topStocks = newsDetail.topStocks;

        bool isPriceUp = (double.tryParse(news.priceChange.replaceAll(RegExp(r'[^\d.-]'), '')) ?? 0) > 0;
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
              _buildAppBarAction(Icons.article, '뉴스요약', () => _showSummary(news)),
              _buildAppBarAction(Icons.chat_bubble, '토론하기', () => _navigateToDiscussion(news)),
              IconButton(
                icon: Icon(
                  news.isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                  color: news.isBookmarked ? const Color(0xFF2B3A66) : Colors.grey,
                  size: 35,
                ),
                onPressed: () => _toggleBookmark(news),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: ListView(
            padding: EdgeInsets.zero,
            children: [
              _buildHeaderImage(news, positiveColor, negativeColor, isPriceUp),
              _buildPredictionSection(news, positiveColor),
              _buildTopStocksSection(topStocks),
            ],
          ),
        );
      },
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

  Widget _buildHeaderImage(News news, Color positiveColor, Color negativeColor, bool isPriceUp) {
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
              Text(news.newsTitle, style: const TextStyle(color: Colors.white, fontSize: 23, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(news.dateSource, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
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
                      Text(news.companyName, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 8),
                      Text(news.currentPrice, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 4),
                      Text(news.priceChange, style: TextStyle(color: isPriceUp ? positiveColor : negativeColor, fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const Text('원문 기사 바로가기 >', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
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
                      const TextSpan(text: 'StorkPulse', style: TextStyle(color: Color(0xFF2B3A66))),
                      const TextSpan(text: '는 '),
                      TextSpan(text: '"${news.companyName}"', style: const TextStyle(color: Color(0xFFFEB12C))),
                      const TextSpan(text: ' 주가가 '),
                      TextSpan(text: '${news.prediction} ', style: TextStyle(color: predictionColor)),
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
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black, fontFamily: 'Pretendard'),
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