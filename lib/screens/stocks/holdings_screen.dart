import 'package:flutter/material.dart';
import '../../models/stock_model.dart';
import '../../widgets/stocks/my_stock_list_item.dart';
import '../../services/api_service.dart';
import '../stocks/stock_detail_screen.dart';

import 'package:stomp_dart_client/stomp_dart_client.dart';
import 'dart:convert';

class HoldingsScreen extends StatefulWidget {
  const HoldingsScreen({super.key});

  @override
  State<HoldingsScreen> createState() => _HoldingsScreenState();
}

class _HoldingsScreenState extends State<HoldingsScreen> {
  final ApiService apiService = ApiService();
  List<Stock> holdings = [];
  bool isLoading = true;

  Map<String, Stock> holdingsMap = {};
  StompClient? stompClient;

  @override
  void initState() {
    super.initState();
    loadHoldings();
  }

  Future<void> loadHoldings() async {
    if (!isLoading) setState(() => isLoading = true);
    try {
      // 'OWN' 타입으로 prediction API 호출
      final result = await apiService.fetchPredictionStocks(myStockType: 'OWN');
      if (mounted) { // 비동기 작업 후 위젯이 여전히 존재하는지 확인
        setState(() {
          holdings = result;
          isLoading = false;
          _connectWebSocketToHoldings(holdings);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
      }
      print('보유 종목 조회 실패: $e');
      // 사용자에게 에러 알림
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('보유 종목을 불러오는데 실패했습니다.')),
      );
    }
  }

  void _connectWebSocketToHoldings(List<Stock> stocks) {
    if (stompClient != null && stompClient!.isActive) {
      stompClient!.deactivate();
    }
    holdingsMap.clear();

    stompClient = StompClient(
      config: StompConfig(
        url: 'ws://stockpulse.p-e.kr/ws-stock',
        onConnect: (frame) {
          for (final stock in stocks) {
            final symbol = stock.symbol;
            if (symbol.isNotEmpty) {
              holdingsMap[symbol] = stock;
              stompClient!.subscribe(
                destination: '/sub/$symbol',
                callback: (frame) {
                  final data = jsonDecode(frame.body!);
                  setState(() {
                    final s = holdingsMap[data['symbol']];
                    if (s != null) {
                      s.currentPrice = (data['currentPrice'] ?? s.currentPrice).toDouble();
                      s.changeRate = (data['changeRate'] ?? s.changeRate).toDouble();
                    }
                  });
                },
              );
            }
          }
        },
        onWebSocketError: (error) => print('웹소켓 오류: $error'),
        onDisconnect: (frame) => print('웹소켓 연결 종료'),
      ),
    );
    stompClient!.activate();
  }

  @override
  void dispose() { // 페이지 종료 시 웹소켓 비활성화
    stompClient?.deactivate();
    super.dispose();
  }

  Map<String, List<Stock>> groupStocksByFirstLetter(List<Stock> stocks) {
    Map<String, List<Stock>> grouped = {};
    for (var stock in stocks) {
      // 한글 자음 추출 로직
      String getKoreanFirstConsonant(String text) {
        const consonants = ['ㄱ','ㄲ','ㄴ','ㄷ','ㄸ','ㄹ','ㅁ','ㅂ','ㅃ','ㅅ','ㅆ','ㅇ','ㅈ','ㅉ','ㅊ','ㅋ','ㅌ','ㅍ','ㅎ'];
        if (text.isEmpty) return '#';
        int unicode = text.codeUnitAt(0);
        if (unicode >= 44032 && unicode <= 55203) { // 한글 범위
          int consonantIndex = (unicode - 44032) ~/ 588;
          return consonants[consonantIndex];
        }
        return text[0].toUpperCase(); // 한글이 아니면 첫 글자
      }
      String firstChar = getKoreanFirstConsonant(stock.name);
      grouped.putIfAbsent(firstChar, () => []).add(stock);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final groupedStocks = groupStocksByFirstLetter(holdings);
    final sortedKeys = groupedStocks.keys.toList()..sort();

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFF9FAFB),
        titleSpacing: 0,
        centerTitle: false,
        title: const Text('보유종목', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : holdings.isEmpty
          ? const Center(child: Text('보유 중인 종목이 없습니다.'))
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
                        loadHoldings();
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