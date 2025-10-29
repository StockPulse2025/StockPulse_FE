import 'package:flutter/material.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import 'dart:convert';
import 'package:collection/collection.dart';
import 'dart:async';
import 'package:intl/intl.dart';

import 'stock_search_screen.dart';
import '../../widgets/stocks/kospi_50_list_item.dart';
import '../../widgets/stocks/my_stock_list_item.dart';
import 'stock_detail_screen.dart';
import '../../models/stock_model.dart';
import '../../services/api_service.dart';
import '../../models/market_index_model.dart';

class StockMainScreen extends StatefulWidget {
  const StockMainScreen({super.key});

  @override
  State<StockMainScreen> createState() => _StockMainScreenState();
}

class _StockMainScreenState extends State<StockMainScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  late TabController _kospiTabController;
  DateTime? _currentKoreanTime;
  Timer? _timer;

  MarketIndices? _marketIndices;
  bool _isLoadingIndices = true;

  List<Stock> _rankedStocks = [];
  List<Stock> _ownedStocks = [];
  List<Stock> _favoriteStocks = [];

  bool _isLoadingRankedStocks = true;
  bool _isLoadingMyStocks = true;

  final ApiService apiService = ApiService();
  String _currentRankingType = 'TRADING_VALUE';

  StompClient? stompClient;
  final Map<String, StompUnsubscribe?> _stompSubscriptions = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _kospiTabController = TabController(length: 4, vsync: this);

    _kospiTabController.addListener(_handleTabSelection);

    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      if (_tabController.index == 1) {
        _fetchMyStocks();
      }
    });

    _kospiTabController.addListener(_handleTabSelection);

    _initializeData();

    _initializeTime();
  }

  void _initializeTime() async {
    print('✨ 한국 시간 API 호출 시작...');
    _currentKoreanTime = await apiService.fetchCurrentKoreanTime();
    print('✨ 성공! 현재 한국 시간: $_currentKoreanTime');

    if (mounted) {
      setState(() {
        print('✨ UI 갱신을 위해 setState 호출됨');
      });
    }

    _timer = Timer.periodic(const Duration(minutes: 1), (timer) async {
      _currentKoreanTime = await apiService.fetchCurrentKoreanTime();
      if (mounted) {
        setState(() {});
      }
    });
  }

  Future<void> _initializeData() async {
    await Future.wait([
      _fetchMarketIndices(),
      _fetchRankedStocks(),
      _fetchMyStocks(),
    ]);
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
    _fetchRankedStocks();
  }

  Future<void> _fetchMarketIndices() async {
    setState(() => _isLoadingIndices = true);
    try {
      final indices = await apiService.fetchMarketIndices();
      if (mounted) {
        setState(() {
          _marketIndices = indices;
          _isLoadingIndices = false;
        });
      }
    } catch (e) {
      print('주가 지수 로드 실패: $e');
      if (mounted) {
        setState(() => _isLoadingIndices = false);
      }
    }
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
    print("--- 1. _fetchMyStocks 시작 ---");
    setState(() => _isLoadingMyStocks = true);
    try {
      final results = await Future.wait([
        apiService.fetchPredictionStocks(myStockType: 'OWN'),
        apiService.fetchPredictionStocks(myStockType: 'FAVORITE'),
      ]);

      print("--- 2. 서버로부터 받은 데이터 ---");
      print("   [보유 종목 응답 개수]: ${results[0].length}개");

      for (var stock in results[0]) {
        print("     - 보유: ${stock.name}");
      }
      print("   [관심 종목 응답 개수]: ${results[1].length}개");

      for (var stock in results[1]) {
        print("     - 관심: ${stock.name}");
      }

      if (mounted) {
        final owned = results[0];
        final favorite = results[1];

        setState(() {
          _ownedStocks = owned;
          _favoriteStocks = favorite;
          _isLoadingMyStocks = false;

          print("--- 3. setState에 적용될 데이터 ---");
          print("   [보유 종목 state 개수]: ${_ownedStocks.length}개");
          print("   [관심 종목 state 개수]: ${_favoriteStocks.length}개");
        });

        if (stompClient?.isActive == true && _tabController.index == 1) {
          _subscribeToStocks([...owned, ...favorite]);
        }
      }
      print("--- 4. _fetchMyStocks 종료 ---");
    } catch (e) {
      print('내 주식 로드 실패: $e');
      if (mounted) {
        setState(() => _isLoadingMyStocks = false);
      }
    }
  }


  @override
  void dispose() {
    _tabController.dispose();
    _kospiTabController.removeListener(_handleTabSelection);
    _kospiTabController.dispose();

    _unsubscribeFromAllStocks();
    stompClient?.deactivate();

    _timer?.cancel();

    super.dispose();
  }

  void _connectToWebSocket() {
    if (stompClient != null && stompClient!.isActive) return;

    stompClient = StompClient(
      config: StompConfig(
        url: 'ws://stockpulse.p-e.kr/ws-stock',
        onConnect: (StompFrame frame) {
          print('주식 홈 화면 웹소켓 연결 성공!');

          if (_tabController.index == 0) {
            _subscribeToStocks(_rankedStocks);
          } else {
            _subscribeToStocks([..._ownedStocks, ..._favoriteStocks]);
          }
        },
        onWebSocketError: (error) => print('웹소켓 연결 오류: $error'),
        onDisconnect: (frame) => print('웹소켓 연결 해제'),
      ),
    );
    stompClient!.activate();
    print('웹소켓 연결 시도 중...');
  }

  void _subscribeToStocks(List<Stock> stocks) {
    if (stompClient?.isActive != true) return;

    _unsubscribeFromAllStocks();

    print('${stocks.length}개의 종목 구독 시작...');
    for (final stock in stocks) {
      if (stock.symbol != null && stock.symbol!.isNotEmpty) {
        final destination = '/sub/${stock.symbol}';
        if (_stompSubscriptions.containsKey(destination)) continue;

        _stompSubscriptions[destination] = stompClient!.subscribe(
          destination: destination,
          callback: _handleRealtimeStockData,
        );
      }
    }
  }

  void _unsubscribeFromAllStocks() {
    for (final unsubscribe in _stompSubscriptions.values) {
      unsubscribe?.call();
    }
    _stompSubscriptions.clear();
    print('모든 구독을 해제했습니다.');
  }

  void _handleRealtimeStockData(StompFrame frame) {
    if (frame.body == null || !mounted) return;

    try {
      final data = jsonDecode(frame.body!) as Map<String, dynamic>;
      final symbol = data['symbol'] as String?;
      if (symbol == null) return;

      bool needsUpdate = false;

      final rankedStock = _rankedStocks.firstWhereOrNull((s) => s.symbol == symbol);
      if (rankedStock != null) {
        rankedStock.currentPrice = (data['currentPrice'] ?? rankedStock.currentPrice).toDouble();
        rankedStock.changeRate = (data['changeRate'] ?? rankedStock.changeRate).toDouble();
        needsUpdate = true;
      }

      final ownedStock = _ownedStocks.firstWhereOrNull((s) => s.symbol == symbol);
      if (ownedStock != null) {
        ownedStock.currentPrice = (data['currentPrice'] ?? ownedStock.currentPrice).toDouble();
        ownedStock.changeRate = (data['changeRate'] ?? ownedStock.changeRate).toDouble();
        needsUpdate = true;
      }

      final favoriteStock = _favoriteStocks.firstWhereOrNull((s) => s.symbol == symbol);
      if (favoriteStock != null) {
        favoriteStock.currentPrice = (data['currentPrice'] ?? favoriteStock.currentPrice).toDouble();
        favoriteStock.changeRate = (data['changeRate'] ?? favoriteStock.changeRate).toDouble();
        needsUpdate = true;
      }

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
    if (_currentKoreanTime == null) return false;

    final now = _currentKoreanTime!;
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

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0, left: 20.0, right: 20.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  List<Widget> _buildStockListWidgets(List<Stock> stocks) {
    final priceFormatter = NumberFormat('#,###');

    return stocks.map((stock) {
      final formattedPrice = priceFormatter.format(stock.currentPrice.toInt());
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 5.0),
        child: GestureDetector(
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => StockDetailScreen(stockId: stock.stockId),
              ),
            );
            _fetchMyStocks();
          },
          child: MyStockListItem(
            rank: stock.rank.toString(),
            logoPath: stock.imageUrl ?? '',
            name: stock.name,
            price: '$formattedPrice원',
            change: '${stock.changeRate.toStringAsFixed(2)}%',
            prediction: stock.prediction ?? '',
            newsCount: stock.newsCount ?? 0,
          ),
        ),
      );
    }).toList();
  }

  Widget _buildAllStocksTab() {
    final priceFormatter = NumberFormat('#,##0.00');
    final changeFormatter = NumberFormat('#,##0.00');

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
              // 이 부분이 핵심 수정 부분입니다.
              _isLoadingIndices
                  ? const Center(child: CircularProgressIndicator())
                  : Row(
                children: [
                  _buildKospiCard(
                    'KOSPI 🇰🇷',
                    priceFormatter.format(_marketIndices?.kospi.currentPrice ?? 0),
                    '${_marketIndices?.kospi.changeAmount.isNegative == false ? '+' : ''}${changeFormatter.format(_marketIndices?.kospi.changeAmount ?? 0)} (${_marketIndices?.kospi.changeRate.isNegative == false ? '+' : ''}${_marketIndices?.kospi.changeRate.toStringAsFixed(2)}%)',
                    (_marketIndices?.kospi.changeAmount ?? 0) >= 0,
                  ),
                  const SizedBox(width: 16),
                  _buildKospiCard(
                    'KOSDAQ 🇰🇷',
                    priceFormatter.format(_marketIndices?.kosdaq.currentPrice ?? 0),
                    '${_marketIndices?.kosdaq.changeAmount.isNegative == false ? '+' : ''}${changeFormatter.format(_marketIndices?.kosdaq.changeAmount ?? 0)} (${_marketIndices?.kosdaq.changeRate.isNegative == false ? '+' : ''}${_marketIndices?.kosdaq.changeRate.toStringAsFixed(2)}%)',
                    (_marketIndices?.kosdaq.changeAmount ?? 0) >= 0,
                  ),
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
              onToggle: () {
                _fetchMyStocks();
                _fetchRankedStocks();
              },
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

    if (_ownedStocks.isEmpty && _favoriteStocks.isEmpty) {
      return const Center(
        child: Text(
          '보유하거나 관심있는 주식이 없습니다.\n종목을 추가해보세요!',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchMyStocks,
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        children: [
          _buildSectionTitle('보유종목'),


          if (_ownedStocks.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24.0),
              child: Center(child: Text('보유 종목이 없습니다.', style: TextStyle(color: Colors.grey))),
            )
          else

            Column(
              children: _buildStockListWidgets(_ownedStocks),
            ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20.0),
            child: Divider(
              color: Color(0xFFE8EBF2),
              thickness: 8.0,
              height: 8.0,
            ),
          ),

          _buildSectionTitle('관심종목'),


          if (_favoriteStocks.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24.0),
              child: Center(child: Text('관심 종목이 없습니다.', style: TextStyle(color: Colors.grey))),
            )
          else

            Column(
              children: _buildStockListWidgets(_favoriteStocks),
            ),

          const SizedBox(height: 24.0),
        ],
      ),
    );
  }
}