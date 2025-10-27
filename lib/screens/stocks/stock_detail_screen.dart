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

  // 🚨 1. 차트 탭 시점의 뉴스 데이터를 위한 상태 변수 추가
  List<News> _timepointNewsList = [];
  bool _isTimepointNewsLoading = false;
  DateTime? _selectedChartDate; // 선택된 날짜를 저장하여 제목에 표시

  // ===== 기존 뉴스 관련 상태 변수 =====
  List<News> newsList = [];
  bool isNewsLoading = true;

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
    fetchNewsData(); // 최신 뉴스 탭을 위한 데이터 로드
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
    setState(() {
      isChartLoading = true;
      // 🚨 차트 데이터를 새로 불러올 때, 이전에 선택했던 뉴스 정보 초기화
      _timepointNewsList = [];
      _selectedChartDate = null;
    });
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

  // '최신 뉴스' 탭을 위한 데이터 로드 함수
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

  // 🚨 2. 차트 막대를 탭했을 때 호출될 함수 (API 호출 로직)
  Future<void> _fetchTimepointNews(DateTime date) async {
    setState(() {
      _isTimepointNewsLoading = true;
      _selectedChartDate = date; // 선택된 날짜 저장
      _timepointNewsList = []; // 이전 목록 비우기
    });

    try {
      final fetchedNews = await apiService.fetchNewsForTimepoint(
        stockId: widget.stockId,
        period: selectedPeriod, // 현재 선택된 차트 기간(DAY, WEEK, MONTH) 사용
        date: date,
      );
      setState(() {
        _timepointNewsList = fetchedNews;
      });
    } catch (e) {
      print('선택 시점 뉴스 로딩 실패: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('뉴스 정보를 불러오는데 실패했습니다: $e')),
      );
    } finally {
      setState(() {
        _isTimepointNewsLoading = false;
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
    List<Map<String, dynamic>> parsedData = rawData.map((d) {
      return {
        'date': DateTime.parse(d['date']),
        'open': double.tryParse(d['openPrice'] ?? '0') ?? 0.0,
        'high': double.tryParse(d['highPrice'] ?? '0') ?? 0.0,
        'low': double.tryParse(d['lowPrice'] ?? '0') ?? 0.0,
        'close': double.tryParse(d['closePrice'] ?? '0') ?? 0.0,
        'volume': double.tryParse(d['totalVolume'] ?? '0') ?? 0.0,
      };
    }).toList();

    // 🔥 [수정] 날짜를 기준으로 오름차순 정렬하여 데이터의 순서를 보장합니다.
    parsedData.sort((a, b) => a['date'].compareTo(b['date']));

    return parsedData;
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

    // SingleChildScrollView를 사용하여 차트와 뉴스 목록을 함께 스크롤
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- 기존 차트 관련 위젯들 ---
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
            const Center(child: Padding(padding: EdgeInsets.all(50.0), child: CircularProgressIndicator()))
          else if (candleData.isEmpty)
            const Center(child: Padding(padding: EdgeInsets.all(50.0), child: Text("차트 데이터가 없습니다.")))
          else
            SizedBox(
              width: double.infinity, // 화면 너비를 꽉 채우도록 설정
              height: 300,
              child: StockDetailChart(
                candleData: candleData,
                onTap: (date) => _fetchTimepointNews(date),
                candleWidth: candleWidth,
                xAxisInterval: xAxisInterval,
                selectedPeriod: selectedPeriod,
                controller: _chartScrollController, // 컨트롤러 전달
              ),
            ),
          _buildTimepointNewsSection(),
        ],
      ),
    );
  }

  // 🚨 5. 선택된 날짜의 뉴스 목록 UI를 그리는 위젯
  Widget _buildTimepointNewsSection() {
    if (_selectedChartDate == null) {
      return const SizedBox.shrink();
    }

    // 🚨 1. Padding 수정: EdgeInsets.all(16.0) -> symmetric(horizontal: 8.0, vertical: 16.0)
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🚨 제목에도 좌우 여백 일관성을 주기 위해 Padding 추가
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              "${DateFormat('yyyy년 MM월 dd일').format(_selectedChartDate!)} 관련 뉴스",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 10),

          if (_isTimepointNewsLoading)
            const Center(child: CircularProgressIndicator())
          else if (_timepointNewsList.isEmpty)
            const Center(child: Padding(padding: EdgeInsets.all(20.0), child: Text("관련 뉴스가 없습니다.")))
          else
            ListView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: _timepointNewsList.length,
              itemBuilder: (context, index) {
                final newsItem = _timepointNewsList[index];
                return GestureDetector(
                  onTap: () => _navigateToDetail(newsItem.newsId),
                  child: NewsCard(
                    news: newsItem,
                    onBookmarkToggle: () => _toggleBookmark(newsItem),
                  ),
                );
              },
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
      // 🚨 2. Padding 수정: 양 옆 여백을 8.0으로 설정
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      itemCount: newsList.length,
      itemBuilder: (context, index) {
        final newsItem = newsList[index];
        return GestureDetector(
          onTap: () => _navigateToDetail(newsItem.newsId),
          child: NewsCard(
            news: newsItem,
            onBookmarkToggle: () => _toggleBookmark(newsItem),
          ),
        );
      },
    );
  }
}