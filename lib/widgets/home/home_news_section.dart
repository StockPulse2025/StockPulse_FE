import 'package:flutter/material.dart';

class HomeNewsSection extends StatelessWidget {
  const HomeNewsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: const Text(
            '내 종목 최신 뉴스 📢',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 225,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            children: [
              _buildNewsCard(
                context,
                'assets/images/news_logo/news_logo_1.jpg',
                '한화 필리조선소 찾은 李대통령... 조선주 "들썩"',
                '한화오션',
                '호재',
                '+3.1%',
                'assets/images/stock_logo/stock_logo_5.png',
              ),
              const SizedBox(width: 16),
              _buildNewsCard(
                context,
                'assets/images/news_logo/news_logo_3.jpg',
                '한미 회담 분위기 좋길래 주식 샀더니... 노란봉투법에 "발목"',
                '한화오션',
                '악재',
                '+3.1%',
                'assets/images/stock_logo/stock_logo_5.png',
              ),
              const SizedBox(width: 16),
              _buildNewsCard(
                context,
                'assets/images/news_logo/news_logo_5.jpg',
                '시총 9조 대한항공, 70조 대미투자... 초대형 항공사 목표?',
                '대한항공',
                '호재',
                '+1.2%',
                'assets/images/stock_logo/stock_logo_2.png',
              ),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildNewsCard(BuildContext context, String newsImagePath, String title, String stockName, String tag, String prediction, String stockLogoPath) {
    final bool isPredictionPositive = prediction.startsWith('+');
    final bool isGoodNews = tag == '호재';

    return Container(
      width: 170,
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(7.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8.0),
                  image: DecorationImage(
                    image: AssetImage(newsImagePath),
                    fit: BoxFit.cover,
                  ),
                ),
              ),

              Positioned(
                top: 0,
                left: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isPredictionPositive ? const Color(0xFFF9B8B0) : const Color(0xFF95C1FF),
                    borderRadius: BorderRadius.circular(5.0),
                  ),
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                      children: [
                        const TextSpan(
                          text: '예측주가 ',
                          style: TextStyle(color: Colors.black),
                        ),
                        TextSpan(
                          text: prediction,
                          style: TextStyle(
                            color: isPredictionPositive ? const Color(0xFFFF0000) : const Color(0xFF0042FF),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)
          ),
          const SizedBox(height: 15),

          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isGoodNews ? const Color(0xFFF3C6C8) : const Color(0xFFC6D1F3),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isGoodNews ? '📈$tag' : '📉$tag',
                  style: const TextStyle(
                      color: Color(0xFF7C7C7C),
                      fontSize: 10,
                      fontWeight: FontWeight.bold
                  ),
                ),
              ),
              const SizedBox(width: 8),
              CircleAvatar(
                radius: 10,
                backgroundImage: AssetImage(stockLogoPath),
                backgroundColor: Colors.transparent,
              ),
              const SizedBox(width: 4),
              Text(stockName, style: const TextStyle(fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}