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

  int _currentPage = 1;
  final int _totalPages = 8;

  List<Stock> _allStocks = [];
  List<Stock> _myStocks = [];
  bool _isLoadingAllStocks = true;
  bool _isLoadingMyStocks = true;

  final ApiService apiService = ApiService();

  void _goToPage(int page) {
    setState(() {
      _currentPage = page.clamp(1, _totalPages);
      _isLoadingAllStocks = true;
    });
    _fetchStocks();
  }

  void _jumpPages(int amount) {
    _goToPage(_currentPage + amount);
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _kospiTabController = TabController(length: 4, vsync: this);
    _fetchStocks();
  }

  Future<void> _fetchStocks() async {
    try {
      final all = await apiService.fetchAllStocks(_currentPage);
      final mine = await apiService.fetchMyStocks();
      setState(() {
        _allStocks = all;
        _myStocks = mine;
        _isLoadingAllStocks = false;
        _isLoadingMyStocks = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingAllStocks = false;
        _isLoadingMyStocks = false;
      });
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
    return _isLoadingAllStocks
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
          child: TabBarView(
            controller: _kospiTabController,
            children: [
              _buildPaginatedKospi50List(),
              _buildPaginatedKospi50List(),
              _buildPaginatedKospi50List(),
              _buildPaginatedKospi50List(),
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

  Widget _buildPaginatedKospi50List() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      itemCount: _allStocks.length + 1,
      itemBuilder: (context, index) {
        if (index == _allStocks.length) return _buildPagination();

        final stock = _allStocks[index];
        return GestureDetector(
          onTap: () =>
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) =>
                    StockDetailScreen(stockId: stock.stockId)),
              ),
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 24.0),
            decoration: BoxDecoration(
              color: index % 2 == 0 ? const Color(0xFFF9FAFB) : Colors.white,
              borderRadius: BorderRadius.circular(7.0),
            ),
            child: Kospi50ListItem(
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10.0, vertical: 10.0),
              rank: stock.rank.toString(),
              logoPath: stock.imageUrl ?? '',
              name: stock.name,
              price: '${stock.currentPrice}원',
              change: '${stock.changeRate.toStringAsFixed(1)}%',
            ),
          ),
        );
      },
    );
  }

  Widget _buildPagination() {
    const Color selectedColor = Color(0xFF2B3A66);
    const Color unselectedColor = Color(0xFFACB0BF);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(icon: const Icon(Icons.keyboard_double_arrow_left), color: unselectedColor, onPressed: () => _jumpPages(-10), visualDensity: VisualDensity.compact),
          IconButton(icon: const Icon(Icons.keyboard_arrow_left), color: unselectedColor, onPressed: () => _jumpPages(-1), visualDensity: VisualDensity.compact),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text.rich(
              TextSpan(
                style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Pretendard'),
                children: [
                  TextSpan(text: '$_currentPage', style: const TextStyle(color: selectedColor, fontSize: 16)),
                  TextSpan(text: ' / $_totalPages', style: const TextStyle(color: unselectedColor, fontSize: 14)),
                ],
              ),
            ),
          ),
          IconButton(icon: const Icon(Icons.keyboard_arrow_right), color: unselectedColor, onPressed: () => _jumpPages(1), visualDensity: VisualDensity.compact),
          IconButton(icon: const Icon(Icons.keyboard_double_arrow_right), color: unselectedColor, onPressed: () => _jumpPages(10), visualDensity: VisualDensity.compact),
        ],
      ),
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