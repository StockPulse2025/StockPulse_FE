import 'package:flutter/material.dart';
import '../../models/stock_model.dart';

class HomeTop5Section extends StatelessWidget {
  final List<Stock> stockList;

  const HomeTop5Section({required this.stockList, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (stockList.isEmpty) {
      return const Center(child: Text('주식 데이터가 없습니다.'));
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '내 종목 주가 변동률 예측 TOP 5 🔮',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ...stockList.map((stock) {
            return _buildTop5Item(
              stock.rank.toString(),
              stock.name,
              '${stock.currentPrice}원',
              '${stock.changeAmount >= 0 ? '+' : ''}${stock.changeAmount.toStringAsFixed(2)}%',
              '${stock.changeRate >= 0 ? '+' : ''}${stock.changeRate.toStringAsFixed(2)}%',
              0, // newsCount (백엔드에서 주는 경우 연동 가능)
                stock.imageUrl ?? 'https://default-image-url.com/default.png'

            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildTop5Item(String rank, String name, String price, String change, String predictionPercent, int newsCount, String imagePath) {
    const Color positiveColor = Color(0xFFF04E52);
    const Color negativeColor = Color(0xFF3687F6);

    final bool isPriceUp = change.startsWith('+') || !change.startsWith('-');
    final bool isPredictionPositive = predictionPercent.startsWith('+');

    final String icon = isPredictionPositive ? '📈' : '📉';
    final String firstWord = isPredictionPositive ? '최대 ' : '최소 ';
    final String lastPhrase = isPredictionPositive ? ' 상승 예측' : ' 하락 예측';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          Text(rank, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(width: 16),
          CircleAvatar(
            radius: 18,
            backgroundImage: NetworkImage(imagePath),
            backgroundColor: Colors.transparent,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                Row(
                  children: [
                    Text(price, style: const TextStyle(fontSize: 12)),
                    const SizedBox(width: 8),
                    Text(change, style: TextStyle(fontSize: 12, color: isPriceUp ? positiveColor : negativeColor)),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(
            width: 130,
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  fontFamily: 'Pretendard',
                ),
                children: [
                  TextSpan(text: icon),
                  TextSpan(text: firstWord),
                  TextSpan(
                    text: predictionPercent,
                    style: TextStyle(color: isPredictionPositive ? positiveColor : negativeColor),
                  ),
                  TextSpan(text: lastPhrase),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Stack(
            alignment: Alignment.topRight,
            children: [
              const Icon(Icons.article_outlined, color: Color(0xFF2B3A66), size: 28),
              if (newsCount > 0)
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(15)),
                  constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                  child: Text(
                    '$newsCount',
                    style: const TextStyle(color: Colors.white, fontSize: 7),
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
