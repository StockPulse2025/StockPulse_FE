import 'package:flutter/material.dart';

typedef StockData = Map<String, String>;

class StockSelectionScreen extends StatelessWidget {
  const StockSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<StockData> stockList = [
      {'name': '한화오션', 'price': '11,200원', 'change': '+2.2%', 'logoPath': 'assets/images/stock_logo/stock_logo_5.png'},
      {'name': '두산에너빌리티', 'price': '64,000원', 'change': '+1.1%', 'logoPath': 'assets/images/stock_logo/stock_logo_4.png'},
      {'name': 'HD현대미포', 'price': '217,500원', 'change': '+15.3%', 'logoPath': 'assets/images/stock_logo/stock_logo_3.png'},
      {'name': '삼성중공업', 'price': '21,600원', 'change': '+4.8%', 'logoPath': 'assets/images/stock_logo/stock_logo_7.png'},
      {'name': '에스엔시스', 'price': '49,500원', 'change': '+11.1%', 'logoPath': 'assets/images/stock_logo/stock_logo_11.png'},
      {'name': 'HD현대중공업', 'price': '500,000원', 'change': '+6.8%', 'logoPath': 'assets/images/stock_logo/stock_logo_3.png'},
      {'name': 'HD한국조선해양', 'price': '364,500원', 'change': '+5.0%', 'logoPath': 'assets/images/stock_logo/stock_logo_3.png'},
      {'name': '삼성전자', 'price': '70,500원', 'change': '+0.2%', 'logoPath': 'assets/images/stock_logo/stock_logo_7.png'},
      {'name': '대한조선', 'price': '92,300원', 'change': '+2.2%', 'logoPath': 'assets/images/stock_logo/stock_logo_9.png'},
      {'name': '지투지바이오', 'price': '142,100원', 'change': '+2.7%', 'logoPath': 'assets/images/stock_logo/stock_logo_10.png'},
      {'name': '네이버', 'price': '217,500원', 'change': '-1.5%', 'logoPath': 'assets/images/stock_logo/stock_logo_18.png'},
      {'name':'삼양식품', 'price': '1,491,000원', 'change': '-0.6%', 'logoPath': 'assets/images/stock_logo/stock_logo_15.png'},
      {'name':'카카오', 'price': '63,800원', 'change': '-1.8%', 'logoPath': 'assets/images/stock_logo/stock_logo_16.png',},
      {'name':'카카오페이', 'price': '60,900원', 'change': '+0.4%', 'logoPath': 'assets/images/stock_logo/stock_logo_12.png',},
      {'name':'SK하이닉스', 'price': '257,500원', 'change': '-1.5%', 'logoPath': 'assets/images/stock_logo/stock_logo_17.png'},
      {'name':'한국전력', 'price': '63,800원', 'change': '+0.8%', 'logoPath': 'assets/images/stock_logo/stock_logo_13.png',},
      {'name':'한국항공우주', 'price': '63,800원', 'change': '-1.0%', 'logoPath': 'assets/images/stock_logo/stock_logo_14.png',},
    ];

    return Scaffold(
      // --- [수정됨] 배경색 흰색 ---
      backgroundColor: Colors.white,
      appBar: AppBar(
        // --- [수정됨] AppBar 스타일 ---
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 1,
        title: const Text('종목 선택', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
      ),
      // --- [수정됨] ListView를 Separated로 변경하여 구분선 추가 ---
      body: ListView.separated(
        // --- [수정됨] 좌우 여백 추가 ---
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
        itemCount: stockList.length,
        itemBuilder: (context, index) {
          final stock = stockList[index];
          final bool isUp = stock['change']!.startsWith('+');
          return ListTile(
            contentPadding: EdgeInsets.zero, // ListTile 기본 패딩 제거
            leading: CircleAvatar(backgroundImage: AssetImage(stock['logoPath']!)),
            title: Text(stock['name']!, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Row(
              children: [
                Text(stock['price']!),
                const SizedBox(width: 8),
                Text(stock['change']!, style: TextStyle(color: isUp ? Colors.red : Colors.blue)),
              ],
            ),
            onTap: () {
              Navigator.pop(context, stock);
            },
          );
        },
        // --- [수정됨] 구분선 빌더 ---
        separatorBuilder: (context, index) => const Divider(
          color: Color(0xFFE8EBF2), // 구분선 색상
          height: 1,
        ),
      ),
    );
  }
}