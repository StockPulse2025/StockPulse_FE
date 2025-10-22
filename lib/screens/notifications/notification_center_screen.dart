import 'package:flutter/material.dart';
import 'notification_settings_screen.dart';
// API가 없으므로 아래 import들은 잠시 주석 처리합니다.
// import '../../widgets/notifications/notification_card.dart';
// import '../../models/notification_model.dart';
// import '../../services/api_service.dart';

class NotificationCenterScreen extends StatefulWidget {
  const NotificationCenterScreen({super.key});

  @override
  State<NotificationCenterScreen> createState() =>
      _NotificationCenterScreenState();
}

class _NotificationCenterScreenState extends State<NotificationCenterScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final Color navyColor = const Color(0xFF2B3A66);

  // API가 없으므로 관련 변수들을 모두 주석 처리합니다.
  // List<NotificationModel> holdingsNotifications = [];
  // List<NotificationModel> watchlistNotifications = [];
  // final ApiService apiService = ApiService();
  // bool isLoadingHoldings = true;
  // bool isLoadingWatchlist = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // _fetchNotifications(); // API 호출 함수를 주석 처리하여 오류를 막습니다.
  }

  /* // API가 없으므로 API 호출 함수 전체를 주석 처리합니다.
  Future<void> _fetchNotifications() async {
    try {
      final holdings = await apiService.fetchHoldingsNotifications();
      final watchlist = await apiService.fetchWatchlistNotifications();
      setState(() {
        holdingsNotifications = holdings;
        watchlistNotifications = watchlist;
        isLoadingHoldings = false;
        isLoadingWatchlist = false;
      });
    } catch (_) {
      setState(() {
        isLoadingHoldings = false;
        isLoadingWatchlist = false;
      });
    }
  }
  */

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: const Text('알림센터',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        elevation: 0,
        actions: [
          IconButton(
            iconSize: 28,
            icon: const Icon(Icons.settings_outlined, color: Colors.black),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (context) => const NotificationSettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Stack(
            alignment: Alignment.bottomCenter,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.0),
                child:
                Divider(height: 1, thickness: 2, color: Color(0xFFE8EBF2)),
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
                tabs: const [
                  Tab(text: '    보유 종목    '),
                  Tab(text: '    관심 종목    ')
                ],
              ),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // [수정] 로딩이나 리스트 대신 "준비 중" 화면을 보여줍니다.
                _buildComingSoonWidget(),
                _buildComingSoonWidget(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // [추가] "서비스 준비 중" 안내를 표시하는 위젯입니다.
  Widget _buildComingSoonWidget() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.construction, size: 50, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            '서비스 준비 중입니다.',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          SizedBox(height: 8),
          Text(
            '알림 목록 API가 준비되면 이 기능이 활성화됩니다.',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }
/*
  Widget _buildNotificationList(List<NotificationModel> notifications) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
      itemCount: notifications.length,
      itemBuilder: (context, index) {
        final notif = notifications[index];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: NotificationCard(
            stockName: notif.stockName,
            impact: notif.impact,
            newsTitle: notif.newsTitle,
            newsImagePath: notif.newsImagePath,
            stockLogoPath: notif.stockLogoPath,
            relatedStockName: notif.relatedStockName,
          ),
        );
      },
    );
  }*/
}
