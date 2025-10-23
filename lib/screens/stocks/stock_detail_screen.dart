import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import 'dart:convert';

import '../../models/news_model.dart';
import '../../services/api_service.dart';
import '../../widgets/news/news_card.dart';
import '../../widgets/stocks/stock_detail_chart.dart';
import '../news/news_detail_screen.dart';

class StockDetailScreen extends StatefulWidget {
  final int stockId;

  const StockDetailScreen({super.key, required this.stockId});
  @override
  State<StockDetailScreen> createState() => _StockDetailScreenState();
}

class _StockDetailScreenState extends State<StockDetailScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  final ApiService apiService = ApiService();

  // ----- 상태 변수 선언 -----
  String stockName = '';
  String stockSymbol = '';
  String stockImageUrl = '';
  int currentPrice = 0;
  double changeRate = 0.0;
  double changeAmount = 0.0;
  bool isFavorite = false;
  bool isOwned = false;
  double previousClosePrice = 0.0;
  List<Map<String, dynamic>> candleData = [];
  double candleWidth = 8.0;
  double xAxisInterval = 5.0;

  // ===== 뉴스 관련 상태 변수 추가 =====
  List<News> newsList = []; // 타입을 News 모델로 변경
  bool isNewsLoading = true; // 뉴스 로딩 상태 추가

  StompClient? stompClient;
  final ScrollController _chartScrollController = ScrollController();
  String selectedPeriod = 'DAY';
  bool isLoading = true;
  bool isChartLoading = true;

  final Color navyColor = const Color(0xFF2B3A66);
  final Color positiveColor = const Color(0xFFFF0000);
  final Color negativeColor = const Color(0xFF0042FF);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    fetchInitialStockData();
    fetchChartData();
    fetchNewsData(); // ===== 뉴스 데이터 로드 함수 호출 추가 =====
  }

  // 종목 기본 정보 요청
  Future<void> fetchInitialStockData() async {
    try {
      final result = await apiService.fetchStockDetail(widget.stockId);
      final double newCurrentPrice = (result['currentPrice'] ?? 0).toDouble();
      final double fetchedPreviousPrice = (result['changeAmount'] ?? 0).toDouble();

      setState(() {
        stockName = result['name'] ?? '';
        stockSymbol = result['symbol'] ?? '';
        stockImageUrl = result['imageUrl'] ?? '';
        currentPrice = newCurrentPrice.toInt();
        previousClosePrice = fetchedPreviousPrice;
        isFavorite = result['favorite'] ?? false;
        isOwned = result['owned'] ?? false;

        if (previousClosePrice > 0) {
          changeAmount = newCurrentPrice - previousClosePrice;
          changeRate = (changeAmount / previousClosePrice) * 100;
        } else {
          changeAmount = 0;
          changeRate = 0;
        }
        isLoading = false;
      });
      setupWebSocket();
    } catch (e) {
      setState(() => isLoading = false);
      print('주식 상세 정보 요청 중 오류 발생: $e');
    }
  }

  // WebSocket STOMP 연결 및 구독 설정
  void setupWebSocket() {
    stompClient = StompClient(
      config: StompConfig(
        url: 'ws://stockpulse.p-e.kr/ws-stock',
        onConnect: (frame) {
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
          stompClient!.subscribe(
            destination: '/sub/${stockSymbol}_candle',
            callback: (frame) {
              final data = jsonDecode(frame.body!);
              setState(() {
                final newCandle = {
                  'date': DateTime.parse(data['date']),
                  'open': double.tryParse(data['openPrice'] ?? '0') ?? 0.0,
                  'high': double.tryParse(data['highPrice'] ?? '0') ?? 0.0,
                  'low': double.tryParse(data['lowPrice'] ?? '0') ?? 0.0,
                  'close': double.tryParse(data['closePrice'] ?? '0') ?? 0.0,
                  'volume': double.tryParse(data['totalVolume'] ?? '0') ?? 0.0,
                };
                if (candleData.isNotEmpty && candleData.last['date'] == newCandle['date']) {
                  candleData[candleData.length - 1] = newCandle;
                } else {
                  candleData.add(newCandle);
                }
              });
            },
          );
          print('웹소켓 구독 시작 - 가격 및 캔들 데이터');
        },
        onWebSocketError: (error) => print('웹소켓 오류 발생: $error'),
        onDisconnect: (frame) => print('웹소켓 연결 종료'),
      ),
    );
    stompClient!.activate();
  }

  // 기간별 차트 데이터 요청
  Future<void> fetchChartData() async {
    setState(() => isChartLoading = true);
    try {
      final rawData = await apiService.fetchCandleData(stockId: widget.stockId, period: selectedPeriod);
      setState(() {
        candleData = parseCandleData(rawData);
        updateChartSettings();
        isChartLoading = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) => scrollToEnd());
    } catch (e) {
      print('$selectedPeriod 차트 데이터 로딩 실패: $e');
      setState(() {
        isChartLoading = false;
        candleData = [];
      });
    }
  }

  // ===== 종목 관련 최신 뉴스 데이터 요청 함수 추가 =====
  Future<void> fetchNewsData() async {
    setState(() => isNewsLoading = true);
    try {
      final fetchedNews = await apiService.fetchLatestNewsForStock(widget.stockId);
      setState(() {
        newsList = fetchedNews;
        isNewsLoading = false;
      });
    } catch (e) {
      print('종목 뉴스 로딩 실패: $e');
      setState(() {
        isNewsLoading = false;
        newsList = [];
      });
    }
  }

  // ===== 뉴스 상세 화면으로 이동하는 함수 추가 =====
  void _navigateToDetail(int newsId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => NewsDetailScreen(newsId: newsId),
      ),
    );
  }

  // ===== 뉴스 북마크 상태를 변경하는 함수 추가 =====
  Future<void> _toggleBookmark(News newsItem) async {
    final originalStatus = newsItem.isBookmarked;

    // UI 즉시 업데이트
    setState(() {
      newsItem.isBookmarked = !originalStatus;
    });

    try {
      final newStatus = await apiService.updateBookmarkStatus(newsItem.newsId);
      // 서버 응답과 UI가 다를 경우, 서버 값으로 동기화
      if (newsItem.isBookmarked != newStatus) {
        setState(() {
          newsItem.isBookmarked = newStatus;
        });
      }
    } catch (e) {
      // 에러 발생 시 원래 상태로 복구
      setState(() {
        newsItem.isBookmarked = originalStatus;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('북마크 상태 변경에 실패했습니다.')),
        );
      }
    }
  }

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

  void onPeriodChanged(String newPeriod) {
    if (selectedPeriod == newPeriod) return;
    setState(() => selectedPeriod = newPeriod);
    fetchChartData();
  }

  void updateChartSettings() {
    switch (selectedPeriod) {
      case 'DAY':
        candleWidth = 30.0;
        xAxisInterval = 3.0;
        break;
      case 'WEEK':
        candleWidth = 40.0;
        xAxisInterval = 2.0;
        break;
      case 'MONTH':
        candleWidth = 50.0;
        xAxisInterval = 1.0;
        break;
    }
  }

  void scrollToEnd() {
    if (_chartScrollController.hasClients) {
      _chartScrollController.jumpTo(_chartScrollController.position.maxScrollExtent);
    }
  }

  Future<void> _toggleOwned() async {
    try {
      final newStatus = await apiService.toggleOwnedStock(widget.stockId);
      setState(() => isOwned = newStatus);
    } catch (e) {
      print('보유 상태 토글 실패: $e');
    }
  }

  Future<void> _toggleFavorite() async {
    try {
      final newStatus = await apiService.toggleFavoriteStock(widget.stockId);
      setState(() => isFavorite = newStatus);
    } catch (e) {
      print('관심 상태 토글 실패: $e');
    }
  }

  @override
  void dispose() {
    stompClient?.deactivate();
    _chartScrollController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  String formatPrice(int price) {
    return NumberFormat('###,###,###,###').format(price);
  }

  String formatChangeAmount(double amount) {
    return '${NumberFormat('+###,###,###,##0.##;-###,###,###,##0.##').format(amount)}원';
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: _buildHeader(),
          ),
          const SizedBox(height: 15),
          Stack(
            alignment: Alignment.bottomCenter,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.0),
                child: Divider(height: 1, thickness: 2, color: Color(0xFFE8EBF2)),
              ),
              TabBar(
                controller: _tabController,
                labelColor: navyColor,
                unselectedLabelColor: Colors.grey,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                indicatorColor: navyColor,
                indicatorWeight: 3.0,
                indicatorSize: TabBarIndicatorSize.label,
                dividerColor: Colors.transparent,
                tabs: const [Tab(text: '      차트      '), Tab(text: '    최신 뉴스    ')],
              ),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildChartTab(),
                _buildRealtimeNewsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: Colors.grey[200],
              backgroundImage: stockImageUrl.isNotEmpty ? NetworkImage(stockImageUrl) : null,
              child: stockImageUrl.isEmpty ? const Icon(Icons.business, color: Colors.grey) : null,
            ),
            const SizedBox(width: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(stockName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(width: 4),
                Text('KOSPI $stockSymbol', style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
              ],
            ),
            const Spacer(),
            IconButton(
              iconSize: 30,
              icon: Icon(Icons.credit_card, color: isOwned ? navyColor : Colors.grey[300]),
              onPressed: _toggleOwned,
            ),
            IconButton(
              iconSize: 30,
              icon: Icon(Icons.favorite, color: isFavorite ? navyColor : Colors.grey[300]),
              onPressed: _toggleFavorite,
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text('${formatPrice(currentPrice)}원', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
        Row(
          children: [
            const Text('어제보다 ', style: TextStyle(fontSize: 16, color: Color(0xFF7C7C7C), fontWeight: FontWeight.bold)),
            Text('${formatChangeAmount(changeAmount)} (${changeRate.toStringAsFixed(2)}%)', style: TextStyle(fontSize: 16, color: changeRate >= 0 ? positiveColor : negativeColor, fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }

  Widget _buildChartTab() {
    double chartViewportWidth = (candleWidth + (candleWidth * 0.5)) * candleData.length + 20.0;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                _buildPeriodFilter(),
                const SizedBox(height: 16),
              ],
            ),
          ),
          if (isChartLoading)
            const Center(child: Padding(
              padding: EdgeInsets.all(50.0),
              child: CircularProgressIndicator(),
            ))
          else if (candleData.isEmpty)
            const Center(child: Padding(
              padding: EdgeInsets.all(50.0),
              child: Text("차트 데이터가 없습니다."),
            ))
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              controller: _chartScrollController,
              child: SizedBox(
                width: chartViewportWidth,
                height: 300,
                child: StockDetailChart(
                  candleData: candleData,
                  onTap: (date) => print('선택된 날짜: $date'),
                  candleWidth: candleWidth,
                  xAxisInterval: xAxisInterval,
                  selectedPeriod: selectedPeriod,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPeriodFilter() {
    return Row(
      children: [
        _buildPeriodButton('1일', 'DAY', selectedPeriod == 'DAY'),
        const SizedBox(width: 8),
        _buildPeriodButton('1주', 'WEEK', selectedPeriod == 'WEEK'),
        const SizedBox(width: 8),
        _buildPeriodButton('1개월', 'MONTH', selectedPeriod == 'MONTH'),
      ],
    );
  }

  Widget _buildPeriodButton(String label, String period, bool isSelected) {
    return GestureDetector(
      onTap: () => onPeriodChanged(period),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFD1D8EB) : const Color(0xFFEEF0F6),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
    );
  }

  // ===== 실시간 뉴스 탭 위젯 수정 =====
  Widget _buildRealtimeNewsTab() {
    if (isNewsLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (newsList.isEmpty) {
      return const Center(child: Text("실시간 뉴스가 없습니다."));
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      itemCount: newsList.length,
      itemBuilder: (context, index) {
        final newsItem = newsList[index];
        // GestureDetector를 추가하여 상세 화면으로 이동
        return GestureDetector(
          onTap: () => _navigateToDetail(newsItem.newsId),
          // NewsCard에 onBookmarkToggle 콜백 전달
          child: NewsCard(
            news: newsItem,
            onBookmarkToggle: () => _toggleBookmark(newsItem),
          ),
        );
      },
    );
  }
}