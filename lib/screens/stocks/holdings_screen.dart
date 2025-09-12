import 'package:flutter/material.dart';
import '../../widgets/stocks/stock_list_item.dart';
class HoldingsScreen extends StatelessWidget {
  const HoldingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          color: const Color(0xFFF9FAFB),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        titleSpacing: 0,
        centerTitle: false,
        title: const Text(
            '보유종목',
            style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold
            )
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: ListView(
          children: [
            _buildSectionHeader('ㄴ'),

            const StockListItem(name: '네이버', price: '217,500원', change: '-1.5%', imagePath: 'assets/images/stock_logo/stock_logo_18.png', iconType: IconType.holdings,),
            const SizedBox(height: 10),

            _buildSectionHeader('ㅅ'),

            const StockListItem(name: '삼성바이오로직스', price: '1,020,000원', change: '+0.09%', imagePath: 'assets/images/stock_logo/stock_logo_7.png', iconType: IconType.holdings,),
            const SizedBox(height: 5),
            const StockListItem(name: '삼성전자', price: '70,500원', change: '-+0.2%', imagePath: 'assets/images/stock_logo/stock_logo_7.png', iconType: IconType.holdings,),
            const SizedBox(height: 5),
            const StockListItem(name: '삼양식품', price: '1,491,000원', change: '-0.6%', imagePath: 'assets/images/stock_logo/stock_logo_15.png', iconType: IconType.holdings,),
            const SizedBox(height: 10),

            _buildSectionHeader('ㅋ'),

            const StockListItem(name: '카카오', price: '63,800원', change: '-1.8%', imagePath: 'assets/images/stock_logo/stock_logo_16.png', iconType: IconType.holdings,),
            const SizedBox(height: 10),

            _buildSectionHeader('ㅎ'),

            const StockListItem(name: '한화오션', price: '110,400원', change: '+2.4%', imagePath: 'assets/images/stock_logo/stock_logo_5.png', iconType: IconType.holdings,),
            const SizedBox(height: 10),

            _buildSectionHeader('S'),

            const StockListItem(name: 'SK하이닉스', price: '257,500원', change: '-1.5%', imagePath: 'assets/images/stock_logo/stock_logo_17.png', iconType: IconType.holdings,),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 0.0, bottom: 10.0),
      child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
    );
  }
}