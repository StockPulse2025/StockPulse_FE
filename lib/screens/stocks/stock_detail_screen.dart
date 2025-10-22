import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:stomp_dart_client/stomp.dart';
import 'package:stomp_dart_client/stomp_config.dart';
// 'package:http/http.dart' as https;'는 삭제
import 'dart:convert';

import '../../models/news_model.dart';
import '../../services/api_service.dart'; // ApiService import
import '../../widgets/news/news_card.dart';
import '../../widgets/stocks/stock_detail_chart.dart';

class StockDetailScreen extends StatefulWidget {
  final int stockId;

  const StockDetailScreen({super.key, required this.stockId});
  @override
  State<StockDetailScreen> createState() => _StockDetailScreenState();
}

class _StockDetailScreenState extends State<StockDetailScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  final ApiService apiService = ApiService(); // ApiService 인스턴스

  String stockName = '';
  String stockSymbol = '';
  String stockImageUrl = '';
  int currentPrice = 0;
  double changeRate = 0.0;
  double changeAmount = 0.0;
  bool isFavorite = false;
  bool isOwned = false;

  List<Map<String, dynamic>> candleData = [];
  double candleWidth = 8.0;
  double xAxisInterval = 5.0;

  List newsList = [];
  StompClient? stompClient;
  final ScrollController _chartScrollController = ScrollController();
  String selectedPeriod = 'DAY'; // API에 맞는 값으로 변경: DAY, WEEK, MONTH
  bool isLoading = true;
  bool isChartLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    fetchInitialStockData(); // 초기 데이터 로드
    fetchChartData(); // 차트 데이터 로드
  }

  // [수정] 종목 기본 정보 요청 (차트 제외)
  Future<void> fetchInitialStockData() async {
    try {
      final result = await apiService.fetchStockDetail(widget.stockId);
      setState(() {
        stockName = result['name'] ?? '';
        stockSymbol = result['symbol'] ?? '';
        stockImageUrl = result['imageUrl'] ?? '';
        currentPrice = (result['currentPrice'] ?? 0).toInt();
        changeRate = (result['changeRate'] ?? 0).toDouble();
        changeAmount = (result['changeAmount'] ?? 0).toDouble();
        isFavorite = result['favorite'] ?? false;
        isOwned = result['owned'] ?? false;
        // newsList는 별도 API 호출이 필요할 수 있음 (Swagger에 상세 정보 조회 시 뉴스가 포함되어 있지 않음)
        // newsList = result['news'] ?? [];
        isLoading = false;
      });
      setupWebSocket();
    } catch (e) {
      setState(() => isLoading = false);
      print('주식 상세 정보 요청 중 오류 발생: $e');
    }
  }

  // [추가] 기간별 차트 데이터 요청
  Future<void> fetchChartData() async {
    setState(() => isChartLoading = true);
    try {
      final rawData = await apiService.fetchCandleData(stockId: widget.stockId, period: selectedPeriod);
      setState(() {
        candleData = parseCandleData(rawData); // 데이터 파싱
        updateChartSettings(); // 차트 설정 업데이트
        isChartLoading = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) => scrollToEnd());
    } catch (e) {
      print('$selectedPeriod 차트 데이터 로딩 실패: $e');
      setState(() {
        isChartLoading = false;
        candleData = []; // 에러 발생 시 데이터 초기화
      });
    }
  }

  // [수정] API 응답(String)을 차트가 사용할 데이터 타입(double, DateTime)으로 변환
  List<Map<String, dynamic>> parseCandleData(List<Map<String, dynamic>> rawData) {
    return rawData.map((d) {
      return {
        'date': DateTime.parse(d['date']),
        'open': double.tryParse(d['openPrice'] ?? '0') ?? 0.0,
        'high': double.tryParse(d['highPrice'] ?? '0') ?? 0.0,
        'low': double.tryParse(d['lowPrice'] ?? '0') ?? 0.0,
        'close': double.tryParse(d['closePrice'] ?? '0') ?? 0.0,
        'volume': double.tryParse(d['totalVolume'] ?? '0') ?? 0.0,
      };
    }).toList();
  }

  // [추가] 차트 기간 변경 시 호출되는 함수
  void onPeriodChanged(String newPeriod) {
    if (selectedPeriod == newPeriod) return;
    setState(() {
      selectedPeriod = newPeriod;
    });
    fetchChartData(); // 새로운 기간으로 데이터 다시 요청
  }

  // [수정] 차트 설정 업데이트 로직 분리
  void updateChartSettings() {
    setState(() {
      switch (selectedPeriod) {
        case 'DAY':
          candleWidth = 8.0;
          xAxisInterval = 5.0;
          break;
        case 'WEEK':
          candleWidth = 12.0;
          xAxisInterval = 4.0;
          break;
        case 'MONTH':
          candleWidth = 16.0;
          xAxisInterval = 2.0;
          break;
      }
    });
  }

  // 차트 스크롤 컨트롤러로 끝까지 스크롤 이동
  void scrollToEnd() {
    if (_chartScrollController.hasClients) {
      _chartScrollController.jumpTo(_chartScrollController.position.maxScrollExtent);
    }
  }

  // WebSocket STOMP 연결 설정 및 구독 시작
  void setupWebSocket() {
    stompClient = StompClient(
      config: StompConfig(
        url: 'ws://your-backend-domain/ws-stock',
        onConnect: (frame) {
          // WebSocket 연결 성공 시 해당 주식 심볼 구독
          stompClient!.subscribe(
            destination: '/sub/$stockSymbol',
            callback: (frame) {
              final data = jsonDecode(frame.body!);
              setState(() {
                currentPrice = (data['currentPrice'] ?? currentPrice).toInt();
                changeRate = (data['changeRate'] ?? changeRate).toDouble();
                changeAmount = (data['changeAmount'] ?? changeAmount).toDouble();
              });
            },
          );
        },
        onWebSocketError: (error) => print('웹소켓 오류 발생: $error'),
        onDisconnect: (frame) => print('웹소켓 연결 종료'),
      ),
    );
    stompClient!.activate();  // 웹소켓 활성화
  }

  @override
  void dispose() {
    stompClient?.deactivate();  // 웹소켓 비활성화
    _chartScrollController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  // 숫자 천 단위 콤마 표시
  String formatPrice(int price) {
    return price.toString().replaceAllMapped(RegExp(r"(\d)(?=(\d{3})+(?!\d))"), (match) => "${match[1]},");
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(
        title: Text(stockName),
        actions: [ // 보유/관심 토글 버튼 추가
          IconButton(
            icon: Icon(Icons.credit_card, color: isOwned ? Color(0xFF2B3A66) : Color(0xFFACB0BF)),
            onPressed: () async {
              final newStatus = await apiService.toggleOwnedStock(widget.stockId);
              setState(() => isOwned = newStatus);
            },
          ),
          IconButton(
            icon: Icon(Icons.favorite, color: isFavorite ? Color(0xFF2B3A66) : Color(0xFFACB0BF)),
            onPressed: () async {
              final newStatus = await apiService.toggleFavoriteStock(widget.stockId);
              setState(() => isFavorite = newStatus);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                if (stockImageUrl.isNotEmpty)
                  Image.network(stockImageUrl, width: 60, height: 60),
                Text('$stockName ($stockSymbol)', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                Text('${formatPrice(currentPrice)}원', style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold)),
                Text('${changeRate.toStringAsFixed(2)} %', style: TextStyle(fontSize: 16, color: changeRate >= 0 ? Colors.red : Colors.blue)),
              ],
            ),
          ),
          TabBar(
            controller: _tabController,
            tabs: const [Tab(text: '차트'), Tab(text: '실시간 뉴스')],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // 차트 탭
                Column(
                  children: [
                    // 기간 선택 버튼
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Wrap(
                        spacing: 8.0,
                        children: ['DAY', 'WEEK', 'MONTH'].map((period) {
                          return ChoiceChip(
                            label: Text(period),
                            selected: selectedPeriod == period,
                            onSelected: (_) => onPeriodChanged(period),
                          );
                        }).toList(),
                      ),
                    ),
                    isChartLoading
                        ? const Expanded(child: Center(child: CircularProgressIndicator()))
                        : StockDetailChart(
                      candleData: candleData,
                      onTap: (date) => print('선택된 날짜: $date'),
                      candleWidth: candleWidth,
                      xAxisInterval: xAxisInterval,
                      selectedPeriod: selectedPeriod,
                    ),
                  ],
                ),
                // 실시간 뉴스 탭
                ListView.builder(
                  itemCount: newsList.length,
                  itemBuilder: (context, index) {
                    return NewsCard(news: News.fromJson(newsList[index]));
                  },
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}