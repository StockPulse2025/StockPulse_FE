import 'package:flutter/material.dart';
import '../../models/news_model.dart';

class HomeNewsSection extends StatelessWidget {
  final List<News> newsList;
  final Function(int) onNewsTap;

  const HomeNewsSection({
    required this.newsList,
    required this.onNewsTap, // 콜백 함수를 필수로 받도록 설정
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (newsList.isEmpty) {
      return const Center(child: Text('뉴스 데이터가 없습니다.'));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.0),
          child: Text(
            '내 종목 최신 뉴스 📢',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 225,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            itemCount: newsList.length,
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              final news = newsList[index];
              return GestureDetector(
                onTap: () => onNewsTap(news.newsId), // 탭하면 콜백 함수 실행
                child: _buildNewsCard(context, news),
              );
            },
          ),
        )
      ],
    );
  }

  Widget _buildNewsCard(BuildContext context, News news) {
    final bool isPredictionPositive = news.isPredictionPositive;
    final bool isGoodNews = news.isGoodNews;

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
                    image: NetworkImage(news.newsImage),
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
                        const TextSpan(text: '예측주가 ', style: TextStyle(color: Colors.black)),
                        TextSpan(
                          text: news.prediction,
                          style: TextStyle(color: isPredictionPositive ? const Color(0xFFFF0000) : const Color(0xFF0042FF)),
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
            news.newsTitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
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
                  (isGoodNews ? '📈호재' : '📉악재'),
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
                backgroundImage: NetworkImage(news.companyLogo),
                backgroundColor: Colors.transparent,
              ),
              const SizedBox(width: 4),
              Text(news.companyName, style: const TextStyle(fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}
