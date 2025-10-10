import 'package:flutter/material.dart';
import '../../models/stock_model.dart';
import '../../widgets/stocks/my_stock_list_item.dart';
import '../../services/api_service.dart';

class HoldingsScreen extends StatefulWidget {
  const HoldingsScreen({Key? key}) : super(key: key);

  @override
  _HoldingsScreenState createState() => _HoldingsScreenState();
}

class _HoldingsScreenState extends State<HoldingsScreen> {
  final ApiService apiService = ApiService();
  List<Stock> holdings = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadHoldings();
  }

  Future<void> loadHoldings() async {
    try {
      final result = await apiService.fetchHoldings();
      setState(() {
        holdings = result;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      print('보유 종목 조회 실패: $e');
    }
  }

  Map<String, List<Stock>> groupStocksByFirstLetter(List<Stock> stocks) {
    Map<String, List<Stock>> grouped = {};
    for (var stock in stocks) {
      String firstChar = stock.name.isNotEmpty ? stock.name[0].toUpperCase() : '#';
      if (!grouped.containsKey(firstChar)) {
        grouped[firstChar] = [];
      }
      grouped[firstChar]!.add(stock);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final groupedStocks = groupStocksByFirstLetter(holdings);
    final sortedKeys = groupedStocks.keys.toList()..sort();

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        titleSpacing: 0,
        centerTitle: false,
        title: const Text('보유종목', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        flexibleSpace: Container(color: const Color(0xFFF9FAFB)),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: sortedKeys.length,
        itemBuilder: (context, index) {
          final key = sortedKeys[index];
          final stocks = groupedStocks[key]!;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 10),
                child: Text(key, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
              ),
              Column(
                children: stocks.map((stock) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: MyStockListItem(
                      rank: stock.rank.toString(),
                      logoPath: stock.imageUrl ?? '',
                      name: stock.name,
                      price: '${stock.currentPrice}원',
                      change: '${stock.changeRate.toStringAsFixed(1)}%',
                      prediction: stock.prediction ?? '',
                      newsCount: stock.newsCount ?? 0,
                    ),
                  );
                }).toList(),
              )
            ],
          );
        },
      ),
    );
  }
}
