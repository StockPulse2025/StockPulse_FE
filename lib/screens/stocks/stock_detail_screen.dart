import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/news_model.dart';
import '../../widgets/news/news_card.dart';
import '../../widgets/stocks/stock_detail_chart.dart';
import '../../data/dummy_chart_data.dart';
import '../../data/dummy_news_data.dart';

class StockDetailScreen extends StatefulWidget {
  const StockDetailScreen({super.key});

  @override
  State<StockDetailScreen> createState() => _StockDetailScreenState();
}

class _StockDetailScreenState extends State<StockDetailScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  bool _isHolding = true;
  bool _isWatching = true;

  String _selectedPeriod = '1일';
  List<Map<String, dynamic>> _allCandleData = [];
  List<Map<String, dynamic>> _displayCandleData = [];
  double _candleWidth = 8.0;
  double _xAxisInterval = 5.0; // x축 레이블 간격
  double _chartViewportWidth = 0.0; // 차트 뷰포트 너비

  List<News> _selectedNews = [];
  DateTime? _selectedDate;

  late List<News> _realtimeNews;

  final ScrollController _chartScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadInitialData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToEnd();
    });
  }

  void _scrollToEnd() {
    if (_chartScrollController.hasClients) {
      _chartScrollController.jumpTo(_chartScrollController.position.maxScrollExtent);
    }
  }

  void _loadInitialData() {
    _allCandleData = generateSamsungCandleData();
    _realtimeNews = dummyNews.where((news) => news.companyName == '삼성전자').toList();
    _filterChartData('1일');
  }

  void _filterChartData(String period) {
    setState(() {
      _selectedPeriod = period;

      if (period == '1일') {
        _displayCandleData = _allCandleData;
        _candleWidth = 30.0;
        _xAxisInterval = 3.0;
      } else if (period == '1주') {
        _displayCandleData = _aggregateData(_allCandleData, 7);
        _candleWidth = 40.0;
        _xAxisInterval = 2.0;
      } else {
        _displayCandleData = _aggregateData(_allCandleData, 30);
        _candleWidth = 50.0;
        _xAxisInterval = 1.0;
      }

      _chartViewportWidth = (_candleWidth + (_candleWidth * 0.5)) * _displayCandleData.length + 20.0;

      _selectedDate = null;
      _selectedNews = [];
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToEnd();
    });
  }

  List<Map<String, dynamic>> _aggregateData(List<Map<String, dynamic>> dailyData, int interval) {
    List<Map<String, dynamic>> aggregatedData = [];
    for (int i = 0; i < dailyData.length; i += interval) {
      int end = (i + interval > dailyData.length) ? dailyData.length : i + interval;
      List<Map<String, dynamic>> chunk = dailyData.sublist(i, end);
      if (chunk.isEmpty) continue;

      double open = chunk.first['open'];
      double close = chunk.last['close'];
      double high = chunk.map((d) => d['high'] as double).reduce((a, b) => a > b ? a : b);
      double low = chunk.map((d) => d['low'] as double).reduce((a, b) => a < b ? a : b);
      DateTime date = chunk.last['date'];

      aggregatedData.add({'date': date, 'high': high, 'low': low, 'open': open, 'close': close});
    }
    return aggregatedData;
  }

  void _handleCandleTap(DateTime date) {
    setState(() {
      _selectedDate = date;
      if (_selectedPeriod != '1일') {
        int days = (_selectedPeriod == '1주') ? 7 : 30;
        DateTime startDate = date.subtract(Duration(days: days - 1));
        _selectedNews = getNewsForPeriod(startDate, date);
      } else {
        _selectedNews = getNewsForDate(date);
      }
    });
  }

  final Color navyColor = const Color(0xFF2B3A66);
  final Color positiveColor = const Color(0xFFFF0000);
  final Color negativeColor = const Color(0xFF0042FF);

  @override
  void dispose() {
    _tabController.dispose();
    _chartScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                tabs: const [Tab(text: '      차트      '), Tab(text: '    실시간 뉴스    ')],
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
            const CircleAvatar(radius: 20, backgroundImage: AssetImage('assets/images/stock_logo/stock_logo_7.png')),
            const SizedBox(width: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: const [
                Text('삼성전자', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                SizedBox(width: 4),
                Text(' KOSPI 005930', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
              ],
            ),
            const Spacer(),
            IconButton(
              iconSize: 30,
              icon: Icon(Icons.credit_card, color: _isHolding ? navyColor : Colors.grey[300]),
              onPressed: () => setState(() => _isHolding = !_isHolding),
            ),
            IconButton(
              iconSize: 30,
              icon: Icon(Icons.favorite, color: _isWatching ? navyColor : Colors.grey[300]),
              onPressed: () => setState(() => _isWatching = !_isWatching),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Text('70,500원', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
        Row(
          children: [
            const Text('어제보다 ', style: TextStyle(fontSize: 16, color: Color(0xFF7C7C7C), fontWeight: FontWeight.bold)),
            Text('+200원 (0.2%)', style: TextStyle(fontSize: 16, color: positiveColor, fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }

  Widget _buildChartTab() {
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

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            controller: _chartScrollController,
            child: SizedBox(
              width: _chartViewportWidth,
              child: StockDetailChart(
                candleData: _displayCandleData,
                onCandleTap: _handleCandleTap,
                candleWidth: _candleWidth,
                xAxisInterval: _xAxisInterval,
                selectedPeriod: _selectedPeriod,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                if (_selectedNews.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          '${DateFormat('M월 d일').format(_selectedDate!)}  AI 영향도 예측 기반 등락 원인 뉴스',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
                      ),
                      const SizedBox(height: 8),
                      ListView.builder(
                        itemCount: _selectedNews.length,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemBuilder: (context, index) {
                          return NewsCard(
                            news: _selectedNews[index],
                            margin: const EdgeInsets.symmetric(vertical: 8.0),
                          );
                        },
                      )
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodFilter() {
    return Row(
      children: [
        _buildPeriodButton('1일', _selectedPeriod == '1일'),
        const SizedBox(width: 8),
        _buildPeriodButton('1주', _selectedPeriod == '1주'),
        const SizedBox(width: 8),
        _buildPeriodButton('1개월', _selectedPeriod == '1개월'),
      ],
    );
  }

  Widget _buildPeriodButton(String period, bool isSelected) {
    return GestureDetector(
      onTap: () => _filterChartData(period),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFD1D8EB) : const Color(0xFFEEF0F6),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(period, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildRealtimeNewsTab() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      itemCount: _realtimeNews.length,
      itemBuilder: (context, index) {
        final News newsItem = _realtimeNews[index];
        // 재귀 호출 대신 print문으로 임시 처리
        return GestureDetector(
            onTap: () => print("뉴스 상세 보기: ${newsItem.title}"),
            child: NewsCard(news: newsItem)
        );
      },
    );
  }
}