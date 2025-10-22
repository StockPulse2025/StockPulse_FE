import 'package:flutter/material.dart';
import 'settings_screen.dart'; // 설정 화면
import '../widgets/home/home_news_section.dart'; // 홈 뉴스 섹션 위젯
import '../widgets/home/home_top5_section.dart'; // 홈 TOP5 섹션 위젯
import 'news/news_scrap_screen.dart'; // 스크랩 뉴스 화면
import 'stocks/holdings_screen.dart'; // 보유 종목 화면
import 'stocks/watchlist_screen.dart'; // 관심 종목 화면
import 'lounge/lounge_activity_screen.dart'; // 라운지 활동 화면

// 네비게이션바 탭
import 'news/news_room_screen.dart'; // 뉴스룸 화면
import 'stocks/stock_main_screen.dart'; // 주식 종목 메인 화면
import 'lounge/lounge_screen.dart'; // 라운지 화면
import 'notifications/notification_center_screen.dart'; // 알림센터 화면

import '../services/api_service.dart'; // API 서비스
import '../models/news_model.dart'; // 뉴스 모델
import '../models/stock_model.dart'; // 주식 모델
import '../models/user_model.dart'; // 사용자 모델

import 'package:provider/provider.dart';
import '../providers/user_provider.dart';

class HomeScreen extends StatefulWidget {
  final int initialIndex;
  const HomeScreen({super.key, this.initialIndex = 0});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late int _selectedIndex;
  String userName = '사용자'; // 사용자 닉네임 (기본값)
  late List<Widget> _widgetOptions;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex; // 초기 탭 인덱스 설정
    _widgetOptions = <Widget>[
      _HomeContentWidget(
       userName: userName, // 초기 '사용자' 값 전달
      ),
      const NewsRoomScreen(),
      const StockMainScreen(),
      const LoungeScreen(),
      const NotificationCenterScreen(),
    ];

     _loadUserName();
  }

  // 사용자 닉네임을 비동기로 로드
  Future<void> _loadUserName() async {
    try {
      final nickname = await ApiService().fetchUserNickname();
      if (mounted && nickname != null) { // 위젯이 마운트된 상태인지 확인
        setState(() {
          userName = nickname; // 닉네임 업데이트
           _widgetOptions[0] = _HomeContentWidget(
            userName: userName,
          );
        });
      }
    } catch (e) {
      print('사용자 닉네임 로드 실패: $e');
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index; // 선택된 탭 인덱스 업데이트
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex), // 현재 선택된 탭의 위젯 표시
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: '홈'),
          BottomNavigationBarItem(icon: Icon(Icons.description), label: '뉴스룸'),
          BottomNavigationBarItem(icon: Icon(Icons.candlestick_chart), label: '주식종목'),
          BottomNavigationBarItem(icon: Icon(Icons.forum), label: '라운지'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications), label: '알림센터'),
        ],
        currentIndex: _selectedIndex, // 현재 선택된 탭
        selectedItemColor: const Color(0xFF2B3A66),
        unselectedItemColor: const Color(0xFFACB0BF),
        onTap: _onItemTapped,
        iconSize: 27.0,
        selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.bold, fontSize: 12.0
        ),
        unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.bold, fontSize: 12.0
        ),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        elevation: 1.0,
      ),
    );
  }
}

class _HomeContentWidget extends StatefulWidget {
 final String userName; // 사용자 닉네임

  const _HomeContentWidget({
    super.key,
    required this.userName,
  });

  @override
  State<_HomeContentWidget> createState() => _HomeContentWidgetState();
}

class _HomeContentWidgetState extends State<_HomeContentWidget> {
  late Future<List<News>> newsFuture; // 최신 뉴스 데이터를 가져올 Future
  late Future<List<Stock>> topStocksFuture; // 예측 TOP5 주식 데이터를 가져올 Future
  late String _currentUserName;

  @override
  void initState() {
    super.initState();
    _currentUserName = widget.userName; // 초기 userName 설정
    _loadHomeData(); // 홈 콘텐츠 데이터 로드 시작
  }

  @override
  void didUpdateWidget(covariant _HomeContentWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.userName != oldWidget.userName) {
      setState(() {
        _currentUserName = widget.userName;
      });
    }
  }

  // _HomeContentWidget에 필요한 데이터를 비동기로 로드
  Future<void> _loadHomeData() async {
    final apiService = ApiService();
    newsFuture = apiService.fetchMyLatestNews();
    topStocksFuture = apiService.fetchPredictionTop5Stocks();

    try {
      final nickname = await ApiService().fetchUserNickname();
      if (mounted && nickname != null) {
        setState(() {
          _currentUserName = nickname;
        });
      }
    } catch (e) {
      print('HomeContentWidget에서 사용자 닉네임 로드 실패: $e');
    }

    setState(() {}); // FutureBuilder가 다시 빌드될 수 있도록 트리거
  }

  // 퀵메뉴 아이템을 생성하는 헬퍼 위젯
  Widget _buildQuickMenu(BuildContext context, String title, String imageName, Widget screen) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(MaterialPageRoute(builder: (context) => screen));
      },
      child: AspectRatio(
        aspectRatio: 1.0,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/$imageName',
                width: 60,
                height: 60,
              ),
              Transform.translate(
                offset: const Offset(0, -10),
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    height: 1.0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final nickname = userProvider.nickname ?? '게스트';
    const Color navyColor = Color(0xFF2B3A66);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: navyColor,
        surfaceTintColor: navyColor,
        elevation: 0,
        leading:
        Padding(
          padding: const EdgeInsets.only(top: 20.0),
          child: IconButton(
            iconSize: 30.0,
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () {
              // 설정 화면으로 이동
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => SettingsScreen()),
              );
            },
          ),
        ),
        actions: const [],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              color: navyColor,
              padding: const EdgeInsets.only(bottom: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Transform.translate(
                    offset: const Offset(-50.0, 0),
                    child: Image.asset(
                      'assets/images/stockpulse_logo_white.png',
                      height: 60,
                      width: 350,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Pretendard'
                        ),
                        children: [
                          TextSpan(
                            text: _currentUserName,
                            style: const TextStyle(color: Color(0xFFFFB31A)),
                          ),
                          const TextSpan(text: '님, 반가워요!'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 35.0),
                    child: Row(
                      children: [
                        Expanded(child: _buildQuickMenu(
                            context, '보유종목', 'home_icon_card.png',
                            const HoldingsScreen())),
                        const SizedBox(width: 15),
                        Expanded(child: _buildQuickMenu(
                            context, '관심종목', 'home_icon_heart.png',
                            const WatchlistScreen())),
                        const SizedBox(width: 15),
                        Expanded(child: _buildQuickMenu(
                            context, '스크랩', 'home_icon_news.png',
                            const NewsScrapScreen())),
                        const SizedBox(width: 15),
                        Expanded(child: _buildQuickMenu(
                            context, '프로필', 'home_icon_person.png',
                            const LoungeActivityScreen())),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(10.0),
                  topRight: Radius.circular(10.0),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),

                  // 최신 뉴스 섹션
                  FutureBuilder<List<News>>(
                    future: newsFuture, // _HomeContentWidget의 newsFuture 사용
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 50.0),
                          child: CircularProgressIndicator(),
                        ));
                      }
                      if (snapshot.hasError) {
                        return Center(child: Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 50.0, horizontal: 20.0),
                          child: Text(
                            '내 종목 최신 뉴스 로드 실패: ${snapshot.error}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ));
                      }
                      final newsList = snapshot.data ?? [];
                      if (newsList.isEmpty) {
                        return const Center(child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 50.0),
                          child: Text('표시할 뉴스가 없습니다.'),
                        ));
                      }
                      return HomeNewsSection(newsList: newsList);
                    },
                  ),
                  const SizedBox(height: 30),
                  Container(
                    height: 8,
                    color: const Color(0xFFF9FAFB),
                  ),
                  const SizedBox(height: 20),

                  // 주가 변동률 예측 TOP 5 섹션
                  FutureBuilder<List<Stock>>(
                    future: topStocksFuture, // _HomeContentWidget의 topStocksFuture 사용
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 50.0),
                          child: CircularProgressIndicator(),
                        ));
                      }
                      if (snapshot.hasError) {
                        return Center(child: Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 50.0, horizontal: 20.0),
                          child: Text(
                            '내 종목 주가 변동률 예측 TOP 5 로드 실패: ${snapshot.error}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ));
                      }
                      final stockList = snapshot.data ?? [];
                      if (stockList.isEmpty) {
                        return const Center(child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 50.0),
                          child: Text('표시할 TOP 5 주식이 없습니다.'),
                        ));
                      }
                      return HomeTop5Section(stockList: stockList);
                    },
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}