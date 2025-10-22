import 'package:flutter/material.dart';
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


  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _kospiTabController = TabController(length: 4, vsync: this);

    // 코스피 탭 컨트롤러 리스너
    _kospiTabController.addListener(_handleTabSelection);

    // 초기 데이터 로드
    _fetchRankedStocks();
    _fetchMyStocks();
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
      setState(() {
        _rankedStocks = stocks;
        _isLoadingRankedStocks = false;
      });
    } catch (e) {
      print('종목 순위 로드 실패: $e');
      setState(() => _isLoadingRankedStocks = false);
    }
  }

  Future<void> _fetchMyStocks() async {
    setState(() => _isLoadingMyStocks = true);
    try {
      final stocks = await apiService.fetchMyStocks();
      setState(() {
        _myStocks = stocks;
        _isLoadingMyStocks = false;
      });
    } catch (e) {
      print('내 주식 로드 실패: $e');
      setState(() => _isLoadingMyStocks = false);
    }
  }


  @override
  void dispose() {
    _tabController.dispose();
    _kospiTabController.removeListener(_handleTabSelection);
    _kospiTabController.dispose();
    super.dispose();
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
                      'KOSPI 80 🇰🇷', '2605.17', '0.24(0.07%)', true),
                  const SizedBox(width: 16),
                  _buildKospiCard('코스피 🇰🇷', '2464.17', '-35.93(1.44%)', false),
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
            // 각 뷰는 동일한 리스트 위젯을 사용하지만, 데이터(_rankedStocks)가 탭 선택에 따라 변경됨
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
            // [수정] price와 changeRate를 String이 아닌 숫자 타입(int, double) 그대로 전달합니다.
            child: Kospi50ListItem(
              stockId: stock.stockId,
              isOwned: stock.owned,
              isFavorite: stock.favorite,
              contentPadding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 10.0),
              rank: stock.rank.toString(),
              logoPath: stock.imageUrl ?? '',
              name: stock.name,
              price: stock.currentPrice,       // <-- String 대신 int 타입으로 전달
              changeRate: stock.changeRate,
            ),
          ),
        );
      },
    );
  }

  Widget _buildMyStocksTab() {
    return _isLoadingMyStocks
        ? const Center(child: CircularProgressIndicator())
        : ListView.builder(
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
            price: '${stock.currentPrice}원',
            change: '${stock.changeRate.toStringAsFixed(1)}%',
            prediction: stock.prediction ?? '',
            newsCount: stock.newsCount ?? 0,
          ),
        );
      },
    );
  }
}