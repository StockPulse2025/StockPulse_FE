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
    final safeLogoPath = logoPath.isNotEmpty ? logoPath : 'https://via.placeholder.com/40';
    final bool isPriceUp = !change.startsWith('-');
    final bool isPredictionPositive = !prediction.startsWith('-');

    final icon = isPredictionPositive ? '📈' : '📉';
    final firstWord = isPredictionPositive ? '최대 ' : '최소 ';
    final lastPhrase = isPredictionPositive ? ' 상승 예측' : ' 하락 예측';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          ClipOval(
            child: Image.network(
              safeLogoPath,
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
                    Text(price, style: const TextStyle(color: Color(0xFF585858), fontWeight: FontWeight.bold, fontSize: 12)),
                    const SizedBox(width: 8),
                    Text(change, style: TextStyle(color: isPriceUp ? Colors.red : Colors.blue, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          RichText(
            text: TextSpan(
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black, fontFamily: 'Pretendard'),
              children: [
                TextSpan(text: icon),
                TextSpan(text: firstWord),
                TextSpan(text: prediction, style: TextStyle(color: isPredictionPositive ? Colors.red : Colors.blue)),
                TextSpan(text: lastPhrase),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Stack(
            alignment: Alignment.topRight,
            children: [
              const Icon(Icons.article_outlined, size: 28, color: Colors.black),
              if (newsCount > 0)
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(8)),
                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                  child: Text(
                    newsCount.toString(),
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                    textAlign: TextAlign.center,
                  ),
                )
            ],
          ),
        ],
      ),
    );
  }
}
