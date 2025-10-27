import 'package:flutter/material.dart';
import '../../models/stock_model.dart';
import '../../widgets/stocks/my_stock_list_item.dart';
import '../../services/api_service.dart';
import '../stocks/stock_detail_screen.dart';
import 'package:intl/intl.dart';
import 'package:collection/collection.dart';

import 'package:stomp_dart_client/stomp_dart_client.dart';
import 'dart:convert';

class WatchlistScreen extends StatefulWidget {
  const WatchlistScreen({super.key});

  @override
  State<WatchlistScreen> createState() => _WatchlistScreenState();
}

class _WatchlistScreenState extends State<WatchlistScreen> {
  final ApiService apiService = ApiService();
  List<Stock> watchlist = [];
  bool isLoading = true;

  StompClient? stompClient;

  @override
  void initState() {
    super.initState();
    loadWatchlist();
  }

  Future<void> loadWatchlist() async {
    // API 호출 시에는 isLoading을 true로 설정
    setState(() => isLoading = true);
    try {
      final result = await apiService.fetchPredictionStocks(myStockType: 'FAVORITE');
      if (mounted) {
        setState(() {
          watchlist = result;
          isLoading = false;
        });
        // 데이터 로딩 성공 후 웹소켓 연결
        _connectWebSocketToWatchlist(watchlist);
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
      }
      print('관심 종목 조회 실패: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('관심 종목을 불러오는데 실패했습니다.')),
        );
      }
    }
  }

  // 웹소켓 데이터 처리 로직 개선
  void _connectWebSocketToWatchlist(List<Stock> stocks) {
    if (stompClient != null && stompClient!.isActive) {
      stompClient!.deactivate();
    }

    stompClient = StompClient(
      config: StompConfig(
        url: 'ws://stockpulse.p-e.kr/ws-stock',
        onConnect: (frame) {
          print('관심종목 화면 웹소켓 연결 성공!');
          for (final stock in stocks) {
            final symbol = stock.symbol;
            if (symbol.isNotEmpty) {
              stompClient!.subscribe(
                destination: '/sub/$symbol',
                callback: (frame) {
                  if (frame.body == null || !mounted) return;

                  final data = jsonDecode(frame.body!);
                  final receivedSymbol = data['symbol'];

                  // 'watchlist' 리스트에서 직접 해당 주식을 찾아 업데이트
                  final targetStock = watchlist.firstWhereOrNull((s) => s.symbol == receivedSymbol);

                  if (targetStock != null) {
                    setState(() {
                      targetStock.currentPrice = (data['currentPrice'] ?? targetStock.currentPrice).toDouble();
                      targetStock.changeRate = (data['changeRate'] ?? targetStock.changeRate).toDouble();
                    });
                  }
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
  void dispose() {
    stompClient?.deactivate();
    super.dispose();
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

    // 숫자 포맷터를 build 메소드 내에 생성
    final priceFormatter = NumberFormat('#,###');

    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFFFFFFF),
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
          : RefreshIndicator( // 새로고침 기능 추가
        onRefresh: loadWatchlist,
        child: ListView.builder(
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
                    // 포맷팅된 가격 문자열 생성
                    final formattedPrice = priceFormatter.format(stock.currentPrice.toInt());

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
                          // 상세 화면에서 돌아왔을 때 데이터 새로고침
                          loadWatchlist();
                        },
                        child: MyStockListItem(
                          rank: stock.rank.toString(),
                          logoPath: stock.imageUrl ?? '',
                          name: stock.name,
                          // 포맷팅된 가격 사용
                          price: '$formattedPrice원',
                          change: '${stock.changeRate.toStringAsFixed(2)}%', // 소수점 두 자리로 변경
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
      ),
    );
  }
}