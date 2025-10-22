import 'package:flutter/material.dart';
import '../../models/stock_model.dart';
import '../../widgets/stocks/my_stock_list_item.dart';
import '../../services/api_service.dart';
import '../stocks/stock_detail_screen.dart';

class WatchlistScreen extends StatefulWidget {
  const WatchlistScreen({super.key});

  @override
  State<WatchlistScreen> createState() => _WatchlistScreenState();
}

class _WatchlistScreenState extends State<WatchlistScreen> {
  final ApiService apiService = ApiService();
  List<Stock> watchlist = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadWatchlist();
  }

  Future<void> loadWatchlist() async {
    if (!isLoading) setState(() => isLoading = true);
    try {
      // 'FAVORITE' 타입으로 prediction API 호출
      final result = await apiService.fetchPredictionStocks(myStockType: 'FAVORITE');
      if (mounted) {
        setState(() {
          watchlist = result;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
      }
      print('관심 종목 조회 실패: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('관심 종목을 불러오는데 실패했습니다.')),
      );
    }
  }

  Map<String, List<Stock>> groupStocksByFirstLetter(List<Stock> stocks) {
    Map<String, List<Stock>> grouped = {};
    for (var stock in stocks) {
      String getKoreanFirstConsonant(String text) {
        const consonants = ['ㄱ','ㄲ','ㄴ','ㄷ','ㄸ','ㄹ','ㅁ','ㅂ','ㅃ','ㅅ','ㅆ','ㅇ','ㅈ','ㅉ','ㅊ','ㅋ','ㅌ','ㅍ','ㅎ'];
        if (text.isEmpty) return '#';
        int unicode = text.codeUnitAt(0);
        if (unicode >= 44032 && unicode <= 55203) {
          int consonantIndex = (unicode - 44032) ~/ 588;
          return consonants[consonantIndex];
        }
        return text[0].toUpperCase();
      }
      String firstChar = getKoreanFirstConsonant(stock.name);
      grouped.putIfAbsent(firstChar, () => []).add(stock);
    }
    return grouped;
  }


  @override
  Widget build(BuildContext context) {
    final groupedStocks = groupStocksByFirstLetter(watchlist);
    final sortedKeys = groupedStocks.keys.toList()..sort();

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFF9FAFB),
        titleSpacing: 0,
        centerTitle: false,
        title: const Text('관심종목', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : watchlist.isEmpty
          ? const Center(child: Text('관심 종목이 없습니다.'))
          : ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: sortedKeys.length,
        itemBuilder: (context, index) {
          final key = sortedKeys[index];
          final stocks = groupedStocks[key]!;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 16, bottom: 10, left: 4),
                child: Text(key, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
              ),
              Column(
                children: stocks.map((stock) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: GestureDetector(
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => StockDetailScreen(stockId: stock.stockId),
                          ),
                        );
                        loadWatchlist();
                      },
                      child: MyStockListItem(
                        rank: stock.rank.toString(),
                        logoPath: stock.imageUrl ?? '',
                        name: stock.name,
                        price: '${stock.currentPrice}원',
                        change: '${stock.changeRate.toStringAsFixed(1)}%',
                        prediction: stock.prediction ?? '',
                        newsCount: stock.newsCount ?? 0,
                      ),
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