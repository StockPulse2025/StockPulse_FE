import 'package:flutter/material.dart';

class HomeTop5Section extends StatelessWidget {
  const HomeTop5Section({super.key});

  @override
  Widget build(BuildContext context) {
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
          _buildTop5Item('1', '한화오션', '110,400원', '+2.4%', '+3.1%', 7, 'assets/images/stock_logo/stock_logo_5.png'),
          _buildTop5Item('2', '카카오', '63,800원', '-1.8%', '-2.0%', 2, 'assets/images/stock_logo/stock_logo_12.png'),
          _buildTop5Item('3', '네이버', '217,500원', '-1.5%', '-1.6%', 1, 'assets/images/stock_logo/stock_logo_18.png'),
          _buildTop5Item('4', 'SK하이닉스', '257,500원', '-1.5%', '+0.9%', 4, 'assets/images/stock_logo/stock_logo_17.png'),
          _buildTop5Item('5', '삼성전자', '70,500원', '+0.2%', '+0.1%', 5, 'assets/images/stock_logo/stock_logo_7.png'),
        ],
      ),
    );
  }

  Widget _buildTop5Item(String rank, String name, String price, String change, String predictionPercent, int newsCount, String imagePath) {
    const Color positiveColor = Color(0xFFF04E52);
    const Color negativeColor = Color(0xFF3687F6);

    final bool isPriceUp = !change.startsWith('-');
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
            backgroundImage: AssetImage(imagePath),
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
                    style: TextStyle(
                      color: isPredictionPositive ? positiveColor : negativeColor,
                    ),
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