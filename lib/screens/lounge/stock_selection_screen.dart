import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'package:stockpulse2/models/stock_model.dart';

typedef StockData = Map<String, String>;

class StockSelectionScreen extends StatefulWidget {
  const StockSelectionScreen({Key? key}) : super(key: key);

  @override
  _StockSelectionScreenState createState() => _StockSelectionScreenState();
}

class _StockSelectionScreenState extends State<StockSelectionScreen> {
  final ApiService apiService = ApiService();
  List<Stock> stocks = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadStocks();
  }

  Future<void> loadStocks() async {
    try {
      final result = await apiService.fetchAllStocks(1); // 첫 페이지 호출
      setState(() {
        stocks = result;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('종목 조회 실패: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        // 기존 UI 설정 유지
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        itemCount: stocks.length,
        separatorBuilder: (context, index) => const Divider(color: Color(0xFFE1E1E3), height: 1),
        itemBuilder: (context, index) {
          final stock = stocks[index];
          final isUp = stock.changeRate >= 0;
          return ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              backgroundImage: NetworkImage(stock.imageUrl ?? ''),
            ),
            title: Text(stock.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Row(
              children: [
                Text('${stock.currentPrice}원'),
                const SizedBox(width: 8),
                Text(
                  '${isUp ? "+" : ""}${stock.changeRate.toStringAsFixed(2)}%',
                  style: TextStyle(color: isUp ? Colors.red : Colors.blue),
                ),
              ],
            ),
            onTap: () {
              Navigator.pop(context, stock);
            },
          );
        },
      ),
    );
  }
}
