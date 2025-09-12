import 'package:flutter/material.dart';

class MyStockListItem extends StatelessWidget {
  final String rank;
  final String logoPath;
  final String name;
  final String price;
  final String change;
  final String prediction;
  final int newsCount;

  const MyStockListItem({
    super.key,
    required this.rank,
    required this.logoPath,
    required this.name,
    required this.price,
    required this.change,
    required this.prediction,
    required this.newsCount,
  });

  @override
  Widget build(BuildContext context) {
    const Color positiveColor = Color(0xFFFF0000);
    const Color negativeColor = const Color(0xFF0042FF);
    const Color navyColor = Color(0xFF2B3A66);

    final bool isPriceUp = !change.startsWith('-');
    final bool isPredictionPositive = !prediction.startsWith('-');

    final String icon = isPredictionPositive ? '📈' : '📉';
    final String firstWord = isPredictionPositive ? '최대 ' : '최소 ';
    final String lastPhrase = isPredictionPositive ? ' 상승 예측' : ' 하락 예측';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 12.0), // 내부 상하좌우 여백
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Row(
        children: [
          Text(rank, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          ClipOval(
            child: Image.asset(
              logoPath,
              width: 40,
              height: 40,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Text(price, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF585858))),
                    const SizedBox(width: 8),
                    Text(change, style: TextStyle(color: isPriceUp ? positiveColor : negativeColor, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          RichText(
            text: TextSpan(
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: Colors.black,
                fontFamily: 'Pretendard',
              ),
              children: [
                TextSpan(text: icon),
                TextSpan(text: firstWord),
                TextSpan(
                  text: prediction,
                  style: TextStyle(
                    color: isPredictionPositive ? positiveColor : negativeColor,
                  ),
                ),
                TextSpan(text: lastPhrase),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Stack(
            alignment: Alignment.topRight,
            children: [
              Icon(Icons.article_outlined, color: navyColor, size: 28),
              if (newsCount > 0)
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(8)),
                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                  child: Text(
                    '$newsCount',
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}