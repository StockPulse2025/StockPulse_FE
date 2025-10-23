import 'package:flutter/material.dart';
import '../../models/news_model.dart';

class NewsCard extends StatelessWidget {
  final News news;
  final EdgeInsetsGeometry? margin;
  final VoidCallback onBookmarkToggle; // 북마크 토글 이벤트를 처리할 콜백

  const NewsCard({
    super.key,
    required this.news,
    required this.onBookmarkToggle,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {

    print('--- NewsCard Data ---');
    print('종목명: "${news.companyName}"');
    print('---------------------');

    const Color positiveColor = Color(0xFFF04E52);
    const Color negativeColor = Color(0xFF3687F6);
    // 주가 등락률 파싱 (숫자, '.', '-' 제외한 문자 모두 제거)
    final priceChangeStr = news.priceChange.replaceAll(RegExp(r'[^\d.-]'), '');
    final isPriceUp = (double.tryParse(priceChangeStr) ?? 0) > 0;
    // 주식 관련 정보가 있는지 확인 (종목명이 비어있지 않은 경우로 판단)
    final bool hasStockInfo = news.companyName.isNotEmpty;

    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.all(16.0),
          margin: margin ?? const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), spreadRadius: 1, blurRadius: 5)],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: Container(
                  width: 100,
                  height: 100,
                  color: Colors.grey[200],
                  child: news.newsImage.isNotEmpty
                      ? Image.network(
                    news.newsImage,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                    const Center(child: Icon(Icons.broken_image, size: 40, color: Colors.grey)),
                  )
                      : const Center(child: Icon(Icons.broken_image, size: 40, color: Colors.grey)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 100,
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
                          // 주식 정보가 있을 때만 로고와 가격 정보를 표시
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
                                      Text(news.companyName.substring(0, 1)),
                                )
                                    : const SizedBox.shrink(),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Flexible(child: Text(news.companyName, style: const TextStyle(color: Color(0xFF585858), fontWeight: FontWeight.bold, fontSize: 11), overflow: TextOverflow.ellipsis)),
                                  const SizedBox(width: 4),
                                  Text(news.currentPrice, style: const TextStyle(color: Color(0xFF7C7C7C), fontWeight: FontWeight.bold, fontSize: 9)),
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
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Spacer(),
                      Text(news.dateSource, style: const TextStyle(color: Color(0xFFC2C2C2), fontWeight: FontWeight.bold, fontSize: 12)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 24), // 북마크 아이콘과의 간격
            ],
          ),
        ),
        Positioned(
          top: 8,
          right: 16,
          child: IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: Icon(
              news.isBookmarked ? Icons.bookmark : Icons.bookmark_border,
              color: news.isBookmarked ? const Color(0xFF2B3A66) : Colors.grey,
              size: 24,
            ),
            onPressed: onBookmarkToggle, // 콜백 함수 호출
          ),
        ),
        // 예측주가 정보가 있을 때만 표시
        if (news.prediction.isNotEmpty)
          Positioned(
            bottom: 24,
            right: 32,
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
                    const TextSpan(text: '예측주가 ', style: TextStyle(color: Colors.black)),
                    TextSpan(
                      text: news.prediction,
                      style: TextStyle(color: news.isPredictionPositive ? const Color(0xFFFF0000) : const Color(0xFF0042FF)),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}