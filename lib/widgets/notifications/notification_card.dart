import 'package:flutter/material.dart';

class NotificationCard extends StatelessWidget {
  final String stockName;
  final String impact;
  final String newsTitle;
  final String newsImagePath;
  final String stockLogoPath;
  final String relatedStockName;

  const NotificationCard({
    super.key,
    required this.stockName,
    required this.impact,
    required this.newsTitle,
    required this.newsImagePath,
    required this.stockLogoPath,
    required this.relatedStockName,
  });

  @override
  Widget build(BuildContext context) {
    final bool isUp = !impact.startsWith('-');
    const Color positiveColor = Color(0xFFF04E52);
    const Color negativeColor = Color(0xFF3687F6);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8.0),
            child: Image.asset(
              newsImagePath,
              width: 70,
              height: 70,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: const TextStyle(color: Colors.black, fontSize: 13, fontWeight: FontWeight.bold, fontFamily: 'Pretendard'),
                    children: [
                      TextSpan(text: '"$stockName" 주가변동 예측 영향도 '),
                      TextSpan(
                        text: impact,
                        style: TextStyle(color: isUp ? positiveColor : negativeColor),
                      ),
                      const TextSpan(text: ' 포착 📸'),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                    newsTitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    ClipOval(
                      child: Image.asset(
                        stockLogoPath,
                        width: 20,
                        height: 20,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 7),
                    Text(relatedStockName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}