import 'package:flutter/material.dart';
import 'stock_search_screen.dart';
import '../../widgets/stocks/kospi_50_list_item.dart';
import '../../widgets/stocks/my_stock_list_item.dart';
import 'stock_detail_screen.dart';

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

  void _goToPage(int page) {
    setState(() {
      _currentPage = page.clamp(1, _totalPages);
      // TODO: 페이지가 변경되었으므로, 해당 페이지에 맞는 새로운 주식 목록 데이터를 백엔드에서 불러와야 합니다.
    });
  }

  void _jumpPages(int amount) {
    _goToPage(_currentPage + amount);
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _kospiTabController = TabController(length: 4, vsync: this);
  }

  final Color navyColor = const Color(0xFF2B3A66);
  final Color positiveColor = const Color(0xFFFF0000);
  final Color negativeColor = const Color(0xFF0042FF);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: const Text('주식종목', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.black, size: 28),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => const StockSearchScreen())),
          ),
        ],
      ),

      body: Column(
        children: [

          Stack(
            alignment: Alignment.bottomCenter,
            children: [

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: const Divider(
                  height: 0,
                  thickness: 3,
                  color: Color(0xFFE8EBF2),
                ),
              ),
              TabBar(
                controller: _tabController,
                labelColor: navyColor,
                labelStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                unselectedLabelColor: Colors.grey,

                dividerColor: Colors.transparent,
                indicatorColor: navyColor,
                indicatorWeight: 4.0,
                labelPadding: const EdgeInsets.symmetric(horizontal: 16.0),
                indicatorSize: TabBarIndicatorSize.label,
                tabs: const [Tab(text: '      전체 주식      '), Tab(text: '       내 주식       ')],
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
    bool isMarketOpen() {
      final now = DateTime.now();
      // 조건: 평일(월요일=1 ~ 금요일=5) AND (오전 9시 ~ 오후 3시 사이)
      // now.hour >= 9 : 9시 0분 0초부터
      // now.hour < 15  : 14시 59분 59초까지
      return now.weekday >= 1 && now.weekday <= 5 && now.hour >= 9 && now.hour < 15;
    }


    return Column( // SingleChildScrollView 대신 Column 사용
      children: [
        // 상단 고정 부분 (KOSPI 지수, KOSPI 50 차트 제목, 탭바)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text('KOSPI 주가지수', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  Text(
                    '●',
                    style: TextStyle(color: isMarketOpen() ? positiveColor : Colors.grey, fontSize: 8),
                  ),
                  const SizedBox(width: 4),
                  Text(
                      isMarketOpen() ? '장 열림' : '장 닫힘',
                      style: TextStyle(
                          color: isMarketOpen() ? positiveColor : Colors.grey,
                          fontSize: 12,
                          fontWeight: FontWeight.bold
                      )
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildKospiCard('KOSPI 80 🇰🇷', '2605.17', '0.24(0.07%)', true),
                  const SizedBox(width: 16),
                  _buildKospiCard('코스피 🇰🇷', '2464.17', '-35.93(1.44%)', false),
                ],
              ),
              const SizedBox(height: 32),
              const Text('KOSPI 80 실시간 차트', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
            ],
          ),
        ),
        TabBar(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          controller: _kospiTabController,
          labelColor: navyColor,
          unselectedLabelColor: const Color(0xFF585858),
          labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          indicatorColor: navyColor,
          indicatorPadding: const EdgeInsets.symmetric(horizontal: 8.0),
          indicatorWeight: 4.0,
          indicatorSize: TabBarIndicatorSize.tab,
          tabs: const [Tab(text: '거래대금'), Tab(text: '거래량'), Tab(text: '급상승'), Tab(text: '급하락')],
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: const Divider(height: 0, thickness: 2, color: Color(0xFFE8EBF2)),
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
        decoration: BoxDecoration(
          color: const Color(0xFFF7F9FF),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 14, color: Colors.black, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black)),
            const SizedBox(height: 4),
            Text(change, style: TextStyle(fontSize: 14, color: isUp ? positiveColor : negativeColor, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildPaginatedKospi50List() {
    const int stockCountPerPage = 10; // 페이지 당 10개 종목

    final List<Map<String, dynamic>> stockList = [
      {'rank': '1', 'name': '한화오션', 'price': '11,200원', 'change': '+2.2%', 'logoPath': 'assets/images/stock_logo/stock_logo_5.png'},
      {'rank': '2', 'name': '두산에너빌리티', 'price': '64,000원', 'change': '+1.1%', 'logoPath': 'assets/images/stock_logo/stock_logo_4.png'},
      {'rank': '3', 'name': 'HD현대미포', 'price': '217,500원', 'change': '+15.3%', 'logoPath': 'assets/images/stock_logo/stock_logo_3.png'},
      {'rank': '4', 'name': '삼성중공업', 'price': '21,600원', 'change': '+4.8%', 'logoPath': 'assets/images/stock_logo/stock_logo_7.png'},
      {'rank': '5', 'name': '에스엔시스', 'price': '49,500원', 'change': '+11.1%', 'logoPath': 'assets/images/stock_logo/stock_logo_11.png'},
      {'rank': '6', 'name': 'HD현대중공업', 'price': '500,000원', 'change': '+6.8%', 'logoPath': 'assets/images/stock_logo/stock_logo_3.png'},
      {'rank': '7', 'name': 'HD한국조선해양', 'price': '364,500원', 'change': '+5.0%', 'logoPath': 'assets/images/stock_logo/stock_logo_3.png'},
      {'rank': '8', 'name': '삼성전자', 'price': '70,500원', 'change': '+0.2%', 'logoPath': 'assets/images/stock_logo/stock_logo_7.png'},
      {'rank': '9', 'name': '대한조선', 'price': '92,300원', 'change': '+2.2%', 'logoPath': 'assets/images/stock_logo/stock_logo_9.png'},
      {'rank': '10', 'name': '지투지바이오', 'price': '142,100원', 'change': '+2.7%', 'logoPath': 'assets/images/stock_logo/stock_logo_10.png'},
    ];

    // TODO: 실제로는 _currentPage에 따라 다른 데이터를 가져와야 함
    // final List<Map<String, dynamic>> stockList = List.generate(stockCountPerPage, (index) {
    // int rank = ((_currentPage - 1) * stockCountPerPage) + index + 1;
    // return {'rank': '$rank', 'name': '종목 $rank', 'price': '10,000원', 'change': index % 2 == 0 ? '+1.0%' : '-1.0%', 'logoPath': 'assets/images/stock_logo/stock_logo_$rank.png'};
    // });

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      // 아이템 개수 = 종목 개수 + 페이지네이션 위젯 1개
      itemCount: stockCountPerPage + 1,
      itemBuilder: (context, index) {
        if (index == stockCountPerPage) {
          return _buildPagination();
        }

        final stock = stockList[index];
        return GestureDetector(
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => const StockDetailScreen())),
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 24.0),
            decoration: BoxDecoration(
              color: index % 2 == 0 ? const Color(0xFFF9FAFB) : Colors.white,
              borderRadius: BorderRadius.circular(7.0),
            ),
            child: Kospi50ListItem(
              contentPadding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 10.0),
              rank: stock['rank']!,
              logoPath: stock['logoPath']!,
              name: stock['name']!,
              price: stock['price']!,
              change: stock['change']!,
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
                    ]
                )
            ),
          ),
          IconButton(icon: const Icon(Icons.keyboard_arrow_right), color: unselectedColor, onPressed: () => _jumpPages(1), visualDensity: VisualDensity.compact),
          IconButton(icon: const Icon(Icons.keyboard_double_arrow_right), color: unselectedColor, onPressed: () => _jumpPages(10), visualDensity: VisualDensity.compact),
        ],
      ),
    );
  }

  Widget _buildMyStocksTab() {
    final List<Map<String, dynamic>> holdingsList = [
      {'rank': '1', 'name': '네이버', 'price': '217,500원', 'change': '-1.5%', 'prediction': '-2%', 'newsCount': 2, 'logoPath': 'assets/images/stock_logo/stock_logo_18.png'},
      {'rank': '2', 'name':'삼성전자', 'price': '70,500원', 'change': '+0.2%', 'prediction': '+0.3%', 'newsCount': 1, 'logoPath': 'assets/images/stock_logo/stock_logo_7.png'},
      {'rank': '3', 'name':'삼양식품', 'price': '1,491,000원', 'change': '-0.6%', 'prediction': '-0.9%', 'newsCount': 2, 'logoPath': 'assets/images/stock_logo/stock_logo_15.png'},
      {'rank': '4', 'name':'카카오', 'price': '63,800원', 'change': '-1.8%', 'prediction': '-1.0%', 'newsCount': 4, 'logoPath': 'assets/images/stock_logo/stock_logo_16.png',},
      {'rank': '5', 'name':'한화오션', 'price': '110,400원', 'change': '+2.4%', 'prediction': '+3%', 'newsCount': 1, 'logoPath': 'assets/images/stock_logo/stock_logo_5.png'},
      {'rank': '6', 'name':'SK하이닉스', 'price': '257,500원', 'change': '-1.5%', 'prediction': '+0.2%', 'newsCount': 1, 'logoPath': 'assets/images/stock_logo/stock_logo_17.png'},
    ];
    final List<Map<String, dynamic>> watchlist = [
      {'rank': '1', 'name': '네이버', 'price': '217,500원', 'change': '-1.5%', 'prediction': '-2%', 'newsCount': 2, 'logoPath': 'assets/images/stock_logo/stock_logo_18.png'},
      {'rank': '2', 'name':'삼성전자', 'price': '70,500원', 'change': '+0.2%', 'prediction': '+0.3%', 'newsCount': 1, 'logoPath': 'assets/images/stock_logo/stock_logo_7.png'},
      {'rank': '3', 'name':'삼양식품', 'price': '1,491,000원', 'change': '-0.6%', 'prediction': '-0.9%', 'newsCount': 2, 'logoPath': 'assets/images/stock_logo/stock_logo_15.png'},
      {'rank': '4', 'name':'카카오', 'price': '63,800원', 'change': '-1.8%', 'prediction': '-1.0%', 'newsCount': 4, 'logoPath': 'assets/images/stock_logo/stock_logo_16.png',},
      {'rank': '5', 'name':'카카오페이', 'price': '60,900원', 'change': '+0.4%', 'prediction': '-0.8%', 'newsCount': 1, 'logoPath': 'assets/images/stock_logo/stock_logo_12.png',},
      {'rank': '6', 'name':'한국전력', 'price': '63,800원', 'change': '+0.8%', 'prediction': '+0.2%', 'newsCount': 2, 'logoPath': 'assets/images/stock_logo/stock_logo_13.png',},
      {'rank': '7', 'name':'한국항공우주', 'price': '63,800원', 'change': '-1.0%', 'prediction': '-0.1%', 'newsCount': 3, 'logoPath': 'assets/images/stock_logo/stock_logo_14.png',},
      {'rank': '8', 'name':'한화오션', 'price': '110,400원', 'change': '+2.4%', 'prediction': '+3%', 'newsCount': 1, 'logoPath': 'assets/images/stock_logo/stock_logo_5.png'},
      {'rank': '9', 'name':'SK하이닉스', 'price': '257,500원', 'change': '-1.5%', 'prediction': '+0.2%', 'newsCount': 1, 'logoPath': 'assets/images/stock_logo/stock_logo_17.png'},
    ];

    return SingleChildScrollView(

      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('보유 종목', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ListView.builder(
                  itemCount: holdingsList.length,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemBuilder: (context, index) {
                    final stock = holdingsList[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10.0),
                      child: MyStockListItem(
                        rank: stock['rank']!,
                        logoPath: stock['logoPath']!,
                        name: stock['name']!,
                        price: stock['price']!,
                        change: stock['change']!,
                        prediction: stock['prediction']!,
                        newsCount: stock['newsCount']!,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 0),
            child: Container(
              height: 8,
              margin: const EdgeInsets.symmetric(vertical: 24.0),
              color: const Color(0xFFF9FAFB),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('관심 종목', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ListView.builder(
                  itemCount: watchlist.length,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemBuilder: (context, index) {
                    final stock = watchlist[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10.0),
                      child: MyStockListItem(
                        rank: stock['rank']!,
                        logoPath: stock['logoPath']!,
                        name: stock['name']!,
                        price: stock['price']!,
                        change: stock['change']!,
                        prediction: stock['prediction']!,
                        newsCount: stock['newsCount']!,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}