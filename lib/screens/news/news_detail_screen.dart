import 'package:flutter/material.dart';
import '../lounge/create_post_screen.dart';
import '../../models/news_model.dart';
import '../../data/dummy_news_data.dart';

class NewsDetailScreen extends StatefulWidget {
  final News news;

  const NewsDetailScreen({super.key, required this.news});

  @override
  State<NewsDetailScreen> createState() => _NewsDetailScreenState();
}

class _NewsDetailScreenState extends State<NewsDetailScreen> {
  late bool _isBookmarked;

  @override
  void initState() {
    super.initState();
    _isBookmarked = widget.news.isBookmarkedInitially;
  }

  void _showSummary() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.4,
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text('뉴스 요약', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            // 실제 요약 내용으로 수정 필요
            Text('ㆍ대한항공은 미국에서 열린 행사에서 약 70조 원 규모의 보잉 항공기 103대와 GE에어로스페이스 예비엔진·엔진정비 서비스 계약을 체결했다.',
              style: const TextStyle(fontWeight: FontWeight.bold),
              textAlign: TextAlign.left,
            ),

            const SizedBox(height: 16),
            Text('ㆍ이번 투자로 대한항공·아시아나항공 등 그룹사는 전체 항공기 중 36%에 해당하는 최신 기체를 도입하게 된다.',
              style: const TextStyle(fontWeight: FontWeight.bold),
              textAlign: TextAlign.left,
            ),

            const SizedBox(height: 16),
            Text('ㆍ증권가는 이번 결정을 초대형 글로벌 항공사로 도약하기 위한 선제적 투자로 평가하고 있다.',
              style: const TextStyle(fontWeight: FontWeight.bold),
              textAlign: TextAlign.left,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final News news = widget.news;
    final News currentNews = dummyNews[0];

    final Color positiveColor = const Color(0xFFF04E52);
    final Color negativeColor = const Color(0xFF3687F6);
    bool isPriceUp = double.parse(news.priceChange.replaceAll('%', '')) > 0;

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
          _buildAppBarAction(Icons.chat_bubble, '토론하기', () {
            Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => CreatePostScreen(newsData: currentNews),
                )
            );
          }),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        children: [

          _buildHeaderImage(news, positiveColor, negativeColor, isPriceUp),
          _buildPredictionSection(news, positiveColor),
          _buildTopStocksSection(news),
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

  Widget _buildHeaderImage(News news, Color positiveColor, Color negativeColor, bool isPriceUp) {
    return Stack(
      children: [
        Container(
          height: 300,
          width: double.infinity,
          color: Colors.grey[300],
          child: Image.asset(
            news.imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => const Center(child: Icon(Icons.broken_image, size: 60, color: Colors.grey)),
          ),
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
                child: Text(news.isGoodNews ? '📈호재' : '📉악재', style: const TextStyle(color: Color(0xFF7C7C7C), fontSize: 10, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 8),
              Text(news.title, style: const TextStyle(color: Colors.white, fontSize: 23, fontWeight: FontWeight.bold)),
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
        ),
        Positioned(
          top: 16,
          right: 16,
          child: IconButton(
            icon: Icon(_isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                color: _isBookmarked ? const Color(0xFF2B3A66) : Colors.grey,
                size: 35),
            onPressed: () => setState(() => _isBookmarked = !_isBookmarked),
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
                  '이번 "${news.title}" 기사 분석 결과, ${news.companyName}의 주가에 ${isPredictionPositive ? '긍정적인' : '부정적인'} 영향을 미칠 것으로 예상됩니다. 특히 해당 이슈가 시장에 미치는 파급 효과와 투자자들의 반응 등을 종합적으로 고려하여 ${news.prediction}의 변동을 예측합니다.', // 예시 내용
                  style: const TextStyle(color: Colors.black54, fontSize: 12, height: 1.5, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildTopStocksSection(News news) {
    List<Widget> topStockItems;

    if (news.id == 1) {
      topStockItems = [
        _buildTopStockItem('1', '한화오션', '110,200원', '+2.2%', '+3.1%', 'assets/images/stock_logo/stock_logo_5.png', news, isFirst: true),
        _buildTopStockItem('2', 'HD한국조선해양', '364,500원', '+5.0%', '+2.5%', 'assets/images/stock_logo/stock_logo_3.png', news, isFirst: false),
        _buildTopStockItem('3', '삼성중공업', '21,600원', '+4.8%', '+2.0%', 'assets/images/stock_logo/stock_logo_7.png', news, isFirst: false),
        _buildTopStockItem('4', '두산에너빌리티', '64,000원', '+1.1%', '+1.5%', 'assets/images/stock_logo/stock_logo_4.png', news, isFirst: false),
        _buildTopStockItem('5', '대한조선', '92,300원', '+2.2', '+1.2%', 'assets/images/stock_logo/stock_logo_9.png', news, isFirst: false),
      ];
    } else if (news.id == 5) {
      topStockItems = [
        _buildTopStockItem('1', '대한항공', '24,250원', '-1.2%', '+0.7%', 'assets/images/stock_logo/stock_logo_2.png', news, isFirst: true),
        _buildTopStockItem('2', '아시아나항공', '9,550원', '-1.4%', '-0.5%', 'assets/images/stock_logo/stock_logo_6.png', news, isFirst: false),
        _buildTopStockItem('3', '한진칼', '112,500원', '-2.0%', '+0.3%', 'assets/images/stock_logo/stock_logo_1.png', news, isFirst: false),
        _buildTopStockItem('4', '한국공항', '62,100원', '-0.6%', '-0.2%', 'assets/images/stock_logo/stock_logo_1.png', news, isFirst: false),
        _buildTopStockItem('5', '진에어', '8,540원', '+0.1%', '+0.1%', 'assets/images/stock_logo/stock_logo_8.png', news, isFirst: false),
      ];
    } else {
      topStockItems = [
        _buildTopStockItem('1', '삼성전자', '70,500원', '+0.2%', '+0.1%', 'assets/images/stock_logo/stock_logo_7.png', news, isFirst: true),
        _buildTopStockItem('2', 'SK하이닉스', '257,500원', '-1.5%', '+0.9%', 'assets/images/stock_logo/stock_logo_17.png', news, isFirst: false),
        _buildTopStockItem('3', '네이버', '217,500원', '-1.5%', '-1.6%', 'assets/images/stock_logo/stock_logo_18.png', news, isFirst: false),
        _buildTopStockItem('4', '카카오', '63,800원', '-1.8%', '-2.0%', 'assets/images/stock_logo/stock_logo_12.png', news, isFirst: false),
        _buildTopStockItem('5', '한화오션', '110,400원', '+2.4%', '+3.1%', 'assets/images/stock_logo/stock_logo_5.png', news, isFirst: false),
      ];
    }

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
          ...topStockItems,
        ],
      ),
    );
  }

  Widget _buildTopStockItem(String rank, String name, String price, String change, String prediction, String imagePath, News news, {bool isFirst = false}) {
    const Color positiveColor = Color(0xFFF04E52);
    const Color negativeColor = Color(0xFF3687F6);
    final bool isPredictionPositive = !prediction.startsWith('-');

    final BoxDecoration? decoration = isFirst
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
            Text(rank, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(width: 16),
            CircleAvatar(
              radius: 17,
              backgroundColor: Colors.transparent,
              child: ClipOval(
                child: Image.asset(
                  imagePath,
                  width: 30,
                  height: 30,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Text(news.companyName.substring(0, 1)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  Row(
                    children: [
                      Text(price, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 8),
                      Text(change, style: TextStyle(fontSize: 12, color: change.startsWith('+') ? positiveColor : negativeColor, fontWeight: FontWeight.bold)),
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
                    text: prediction,
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