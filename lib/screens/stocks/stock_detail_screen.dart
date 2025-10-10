import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:stomp_dart_client/stomp.dart';
import 'package:stomp_dart_client/stomp_config.dart';
import 'package:stomp_dart_client/stomp_frame.dart';
import 'package:http/http.dart' as https;
import 'dart:convert';

import '../../models/news_model.dart';
import '../../widgets/news/news_card.dart';
import '../../widgets/stocks/stock_detail_chart.dart';

class StockDetailScreen extends StatefulWidget {
  final int stockId;  // stockId 필수 인자

  const StockDetailScreen({super.key, required this.stockId});
  @override
  State<StockDetailScreen> createState() => _StockDetailScreenState();
}

class _StockDetailScreenState extends State<StockDetailScreen> with TickerProviderStateMixin {
  late TabController _tabController;

  String stockName = '';
  String stockSymbol = '';
  String stockImageUrl = '';
  int currentPrice = 0;
  double changeRate = 0.0;
  double changeAmount = 0.0;

  List<Map<String, dynamic>> candleData = [];
  List<Map<String, dynamic>> displayCandleData = [];
  double candleWidth = 8.0;
  double xAxisInterval = 5.0;
  double chartViewportWidth = 0.0;

  List newsList = [];

  StompClient? stompClient;

  final ScrollController _chartScrollController = ScrollController();

  String selectedPeriod = '1일';

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    fetchInitialStockData(); // 초기 데이터 REST API로 불러오기
  }

  // 초기 주식 상세 데이터 요청
  Future<void> fetchInitialStockData() async {
    try {
      final response = await https.get(
        Uri.parse('https://stockpulse.p-e.kr/api/v1/stocks/${widget.stockId}/detail'),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final result = data['result'];
        setState(() {
          stockName = result['name'];      // 주식 이름 저장
          stockSymbol = result['symbol'];  // 주식 심볼 저장
          stockImageUrl = result['imageUrl'];  // 주식 이미지 URL 저장
          currentPrice = (result['currentPrice'] ?? 0).toInt();
          changeRate = (result['changeRate'] ?? 0).toDouble();
          changeAmount = (result['changeAmount'] ?? 0).toDouble();

          candleData = generateCandleData(result['candles']);  // 차트 데이터 가공
          filterCandleData(selectedPeriod);                     // 화면 표시용 차트 데이터 필터링

          newsList = result['news'] ?? [];  // 뉴스 리스트 저장

          isLoading = false;  // 데이터 로드 완료 상태로 변경
        });
        setupWebSocket();  // WebSocket 연결 시작
      } else {
        throw Exception('주식 상세 정보 로드 실패');
      }
    } catch (e) {
      setState(() => isLoading = false);
      print('주식 상세 정보 요청 중 오류 발생: $e');
    }
  }

  // API에서 받은 차트 데이터 포맷 변환 (필요에 따라 구현)
  List<Map<String, dynamic>> generateCandleData(dynamic rawData) {
    if (rawData is List) {
      return rawData.cast<Map<String, dynamic>>();
    }
    return [];
  }

  // 선택된 기간에 따라 차트 데이터 필터링 및 화면 설정
  void filterCandleData(String period) {
    setState(() {
      selectedPeriod = period;
      // 간단한 예시로 전체 차트 데이터 그대로 표시
      displayCandleData = candleData;
      candleWidth = period == '1일' ? 30 : period == '1주' ? 40 : 50;
      xAxisInterval = period == '1일' ? 3 : period == '1주' ? 2 : 1;
      chartViewportWidth = candleWidth * displayCandleData.length;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => scrollToEnd());  // 로딩 후 차트 슬라이더 끝으로 이동
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
                StockDetailChart(
                  candleData: displayCandleData,
                  onTap: (date) => print('선택된 날짜: $date'),
                  candleWidth: candleWidth,
                  xAxisInterval: xAxisInterval,
                  selectedPeriod: selectedPeriod,
                ),
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
