import 'package:flutter/material.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import 'dart:convert';
import 'package:collection/collection.dart';

import 'stock_search_screen.dart';
import '../../widgets/stocks/kospi_50_list_item.dart';
import '../../widgets/stocks/my_stock_list_item.dart';
import 'stock_detail_screen.dart';
import '../../models/stock_model.dart';
import '../../services/api_service.dart';

class StockMainScreen extends StatefulWidget {
  const StockMainScreen({super.key});

  @override
  State<StockMainScreen> createState() => _StockMainScreenState();
}

class _StockMainScreenState extends State<StockMainScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  late TabController _kospiTabController;

  List<Stock> _rankedStocks = [];
  List<Stock> _myStocks = [];
  bool _isLoadingRankedStocks = true;
  bool _isLoadingMyStocks = true;

  final ApiService apiService = ApiService();
  String _currentRankingType = 'TRADING_VALUE'; // 기본값: 거래대금

  // 웹소켓 관련 상태 변수
  StompClient? stompClient;
  // 여러 구독을 관리하기 위한 Map. key: 구독 채널(destination), value: 구독 해제 함수
  final Map<String, StompUnsubscribe?> _stompSubscriptions = {};


  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _kospiTabController = TabController(length: 4, vsync: this);

    _kospiTabController.addListener(_handleTabSelection);

    // 내 주식 탭 변경 리스너
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      if (_tabController.index == 1) {  // 내 주식 탭일 때
        _fetchMyStocks();
      }
    });

    _kospiTabController.addListener(_handleTabSelection);

    // 초기 데이터 로드 후 웹소켓 연결
    _initializeData();
  }

  // 초기 데이터 로드와 웹소켓 연결을 함께 처리하는 함수
  Future<void> _initializeData() async {
    // 두 API 호출을 동시에 진행
    await Future.wait([
      _fetchRankedStocks(),
      _fetchMyStocks(),
    ]);
    // 데이터 로딩이 끝난 후 웹소켓 연결 시작
    _connectToWebSocket();
  }

  void _handleTabSelection() {
    if (_kospiTabController.indexIsChanging) return;

    switch (_kospiTabController.index) {
      case 0:
        _currentRankingType = 'TRADING_VALUE';
        break;
      case 1:
        _currentRankingType = 'TRADING_VOLUME';
        break;
      case 2:
        _currentRankingType = 'TOP_GAINERS';
        break;
      case 3:
        _currentRankingType = 'TOP_LOSERS';
        break;
    }
    _fetchRankedStocks(); // 탭 변경 시 새로운 기준으로 데이터 요청
  }

  Future<void> _fetchRankedStocks() async {
    setState(() => _isLoadingRankedStocks = true);
    try {
      final stocks = await apiService.fetchStockRanking(type: _currentRankingType);
      if(mounted) {
        setState(() {
          _rankedStocks = stocks;
          _isLoadingRankedStocks = false;
        });
      }
      // 데이터 로드 성공 후, 웹소켓이 연결상태이고 현재 탭이 '전체 주식'이면 구독 실행
      if (stompClient?.isActive == true && _tabController.index == 0) {
        _subscribeToStocks(_rankedStocks);
      }
    } catch (e) {
      print('종목 순위 로드 실패: $e');
      if(mounted) {
        setState(() => _isLoadingRankedStocks = false);
      }
    }
  }

  Future<void> _fetchMyStocks() async {
    setState(() => _isLoadingMyStocks = true);
    try {
      final stocks = await apiService.fetchMyStocks();
      if(mounted) {
        setState(() {
          _myStocks = stocks;
          _isLoadingMyStocks = false;
        });
      }
      // 데이터 로드 성공 후, 웹소켓이 연결상태이고 현재 탭이 '내 주식'이면 구독 실행
      if (stompClient?.isActive == true && _tabController.index == 1) {
        _subscribeToStocks(_myStocks);
      }
    } catch (e) {
      print('내 주식 로드 실패: $e');
      if(mounted) {
        setState(() => _isLoadingMyStocks = false);
      }
    }
  }


  @override
  void dispose() {
    _tabController.dispose();
    _kospiTabController.removeListener(_handleTabSelection);
    _kospiTabController.dispose();

    // 웹소켓 구독 해제 및 연결 종료
    _unsubscribeFromAllStocks();
    stompClient?.deactivate();

    super.dispose();
  }

  // 웹소켓 핵심 기능 함수들
  // 1. 웹소켓 서버에 연결
  void _connectToWebSocket() {
    // 이미 연결 시도 중이거나 연결된 상태면 중복 실행 방지
    if (stompClient != null && stompClient!.isActive) return;

    stompClient = StompClient(
      config: StompConfig(
        url: 'ws://stockpulse.p-e.kr/ws-stock',
        onConnect: (StompFrame frame) {
          print('주식 홈 화면 웹소켓 연결 성공!');
          // 현재 활성화된 탭의 주식 목록을 구독
          if (_tabController.index == 0) {
            _subscribeToStocks(_rankedStocks);
          } else {
            _subscribeToStocks(_myStocks);
          }
        },
        onWebSocketError: (error) => print('웹소켓 연결 오류: $error'),
        onDisconnect: (frame) => print('웹소켓 연결 해제'),
      ),
    );
    stompClient!.activate();
    print('웹소켓 연결 시도 중...');
  }

  // 2. 주식 목록을 받아 전부 구독
  void _subscribeToStocks(List<Stock> stocks) {
    if (stompClient?.isActive != true) return; // 연결 안되어 있으면 실행 안함

    // 기존 구독 모두 해제
    _unsubscribeFromAllStocks();

    print('${stocks.length}개의 종목 구독 시작...');
    for (final stock in stocks) {
      // stock.symbol이 null이거나 비어있지 않은지 확인
      if (stock.symbol != null && stock.symbol!.isNotEmpty) {
        final destination = '/sub/${stock.symbol}';
        // 이미 구독 중인지 확인
        if (_stompSubscriptions.containsKey(destination)) continue;

        _stompSubscriptions[destination] = stompClient!.subscribe(
          destination: destination,
          callback: _handleRealtimeStockData,
        );
      }
    }
  }

  // 3. 모든 구독 해제
  void _unsubscribeFromAllStocks() {
    for (final unsubscribe in _stompSubscriptions.values) {
      unsubscribe?.call();
    }
    _stompSubscriptions.clear();
    print('모든 구독을 해제했습니다.');
  }

  // 4. 실시간 데이터 처리 및 화면 업데이트
  void _handleRealtimeStockData(StompFrame frame) {
    if (frame.body == null || !mounted) return;

    try {
      final data = jsonDecode(frame.body!) as Map<String, dynamic>;
      final symbol = data['symbol'] as String?;
      if (symbol == null) return;

      bool needsUpdate = false;

      // rankedStocks 리스트에서 해당 symbol을 가진 주식 찾기
      final rankedStock = _rankedStocks.firstWhereOrNull((s) => s.symbol == symbol);
      if (rankedStock != null) {
        rankedStock.currentPrice = (data['currentPrice'] ?? rankedStock.currentPrice).toDouble();
        rankedStock.changeRate = (data['changeRate'] ?? rankedStock.changeRate).toDouble();
        needsUpdate = true;
      }

      // myStocks 리스트에서도 해당 symbol을 가진 주식 찾기
      final myStock = _myStocks.firstWhereOrNull((s) => s.symbol == symbol);
      if (myStock != null) {
        myStock.currentPrice = (data['currentPrice'] ?? myStock.currentPrice).toDouble();
        myStock.changeRate = (data['changeRate'] ?? myStock.changeRate).toDouble();
        needsUpdate = true;
      }

      // 변경 사항이 있을 때만 setState 호출
      if(needsUpdate) {
        setState(() {});
      }

    } catch (e) {
      print('❌ 실시간 데이터 처리 오류: $e');
    }
  }


  final Color navyColor = const Color(0xFF2B3A66);
  final Color positiveColor = const Color(0xFFFF0000);
  final Color negativeColor = const Color(0xFF0042FF);

  bool isMarketOpen() {
    final now = DateTime.now();
    return now.weekday >= 1 && now.weekday <= 5 && now.hour >= 9 &&
        now.hour < 15;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: const Text('주식종목',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.black, size: 28),
            onPressed: () =>
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => const StockSearchScreen())),
          ),
        ],
      ),
      body: Column(
        children: [
          Stack(
            alignment: Alignment.bottomCenter,
            children: [
              const Padding(padding: EdgeInsets.symmetric(horizontal: 24.0),
                  child: Divider(
                      height: 0, thickness: 3, color: Color(0xFFE8EBF2))),
              TabBar(
                controller: _tabController,
                labelColor: navyColor,
                labelStyle: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold),
                unselectedLabelColor: Colors.grey,
                dividerColor: Colors.transparent,
                indicatorColor: navyColor,
                indicatorWeight: 4.0,
                labelPadding: const EdgeInsets.symmetric(horizontal: 16.0),
                indicatorSize: TabBarIndicatorSize.label,
                tabs: const [
                  Tab(text: '      전체 주식      '),
                  Tab(text: '       내 주식       ')
                ],
              ),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [_buildAllStocksTab(), _buildMyStocksTab()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllStocksTab() {
    return _isLoadingRankedStocks
        ? const Center(child: CircularProgressIndicator())
        : Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text('KOSPI 주가지수', style: TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  Text('●', style: TextStyle(
                      color: isMarketOpen() ? positiveColor : Colors.grey,
                      fontSize: 8)),
                  const SizedBox(width: 4),
                  Text(isMarketOpen() ? '장 열림' : '장 닫힘',
                      style: TextStyle(
                          color: isMarketOpen() ? positiveColor : Colors.grey,
                          fontSize: 12,
                          fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildKospiCard(
                      'KOSPI 80 🇰🇷', '3,796.22', '−50.43(−1.31%)', false),
                  const SizedBox(width: 16),
                  _buildKospiCard('코스피 🇰🇷', '3,845.56', '-38.12(-0.98%)', false),
                ],
              ),
              const SizedBox(height: 32),
              const Text('KOSPI 80 실시간 차트',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
            ],
          ),
        ),
        TabBar(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          controller: _kospiTabController,
          labelColor: navyColor,
          unselectedLabelColor: const Color(0xFF585858),
          labelStyle: const TextStyle(
              fontSize: 14, fontWeight: FontWeight.bold),
          indicatorColor: navyColor,
          indicatorPadding: const EdgeInsets.symmetric(horizontal: 8.0),
          indicatorWeight: 4.0,
          indicatorSize: TabBarIndicatorSize.tab,
          tabs: const [
            Tab(text: '거래대금'),
            Tab(text: '거래량'),
            Tab(text: '급상승'),
            Tab(text: '급하락')
          ],
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: const Divider(
              height: 0, thickness: 2, color: Color(0xFFE8EBF2)),
        ),
        Expanded(
          child: _isLoadingRankedStocks
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
            controller: _kospiTabController,
            children: [
              _buildRankedStockList(),
              _buildRankedStockList(),
              _buildRankedStockList(),
              _buildRankedStockList(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildKospiCard(String title, String value, String change, bool isUp) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(color: const Color(0xFFF7F9FF),
            borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 14,
                color: Colors.black,
                fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(value, style: const TextStyle(fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black)),
            const SizedBox(height: 4),
            Text(change, style: TextStyle(fontSize: 14,
                color: isUp ? positiveColor : negativeColor,
                fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildRankedStockList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      itemCount: _rankedStocks.length,
      itemBuilder: (context, index) {
        final stock = _rankedStocks[index];
        return GestureDetector(
          onTap: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => StockDetailScreen(stockId: stock.stockId),
              ),
            );
            _fetchRankedStocks();
            _fetchMyStocks();
          },
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 24.0),
            decoration: BoxDecoration(
              color: index % 2 == 0 ? const Color(0xFFF9FAFB) : Colors.white,
              borderRadius: BorderRadius.circular(7.0),
            ),
            child: Kospi50ListItem(
              stockId: stock.stockId,
              isOwned: stock.owned,
              isFavorite: stock.favorite,
              contentPadding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 10.0),
              rank: stock.rank.toString(),
              logoPath: stock.imageUrl ?? '',
              name: stock.name,
              price: stock.currentPrice,
              changeRate: stock.changeRate,
            ),
          ),
        );
      },
    );
  }

  Widget _buildMyStocksTab() {
    if (_isLoadingMyStocks) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_myStocks.isEmpty) {
      return const Center(
        child: Text(
          '보유하거나 관심있는 주식이 없습니다.\n종목을 추가해보세요!',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      itemCount: _myStocks.length,
      itemBuilder: (context, index) {
        final stock = _myStocks[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 10.0),
          child: MyStockListItem(
            rank: stock.rank.toString(),
            logoPath: stock.imageUrl ?? '',
            name: stock.name,
            // 🔄 [수정] 모델의 실시간 데이터를 직접 사용하도록 변경
            price: '${stock.currentPrice.toInt()}원',
            change: '${stock.changeRate.toStringAsFixed(2)}%',
            prediction: stock.prediction ?? '',
            newsCount: stock.newsCount ?? 0,
          ),
        );
      },
    );
  }
}