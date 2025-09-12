import 'package:flutter/material.dart';
import 'notification_settings_screen.dart';
import '../../widgets/notifications/notification_card.dart';

class NotificationCenterScreen extends StatefulWidget {
  const NotificationCenterScreen({super.key});

  @override
  State<NotificationCenterScreen> createState() => _NotificationCenterScreenState();
}

class _NotificationCenterScreenState extends State<NotificationCenterScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  final Color navyColor = const Color(0xFF2B3A66);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: const Text('알림센터', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        elevation: 0,
        actions: [
          IconButton(
            iconSize: 28,
            icon: const Icon(Icons.settings_outlined, color: Colors.black),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const NotificationSettingsScreen()),
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
                tabs: const [Tab(text: '    보유 종목    '), Tab(text: '    관심 종목    ')],
              ),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildNotificationList(isHoldings: true),
                _buildNotificationList(isHoldings: false),
              ],
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildNotificationList({required bool isHoldings}) {
    final List<Map<String, String>> holdingsNotifications = [
      {'stockName': '한화오션',
        'impact': '+2.2%',
        'newsTitle': "한화 필리조선소 찾은 李대통령… 조선주 '들썩'",
        'newsImagePath': 'assets/images/news_logo/news_logo_1.jpg',
        'stockLogoPath': 'assets/images/stock_logo/stock_logo_5.png',
        'relatedStockName': '한화오션'},

      {'stockName': '삼성전자',
        'impact': '-0.3%',
        'newsTitle': "앤비디아 실적 경계감, 코스피 -0.15% 약보합 전환",
        'newsImagePath': 'assets/images/news_logo/news_logo_2.jpg',
        'stockLogoPath': 'assets/images/stock_logo/stock_logo_7.png',
        'relatedStockName': '삼성전자'},

      {'stockName': '삼성전자',
        'impact': '+0.1%',
        'newsTitle': "'200달러 코앞인데' 엔비디아 목표가 155달러?",
        'newsImagePath': 'assets/images/news_logo/news_logo_6.jpg',
        'stockLogoPath': 'assets/images/stock_logo/stock_logo_7.png',
        'relatedStockName': '삼성전자'},

      {'stockName': '한화오션',
        'impact': '+0.2%',
        'newsTitle': "韓조선 원팀 '최대 60조' 캐나다 사업 결선 진출…",
        'newsImagePath': 'assets/images/news_logo/news_logo_7.png',
        'stockLogoPath': 'assets/images/stock_logo/stock_logo_5.png',
        'relatedStockName': '한화오션'},

      {'stockName': '한화오션',
        'impact': '+0.9%',
        'newsTitle': "차익매물 털고 조선주 반등?… 한화오션, 프리…",
        'newsImagePath': 'assets/images/news_logo/news_logo_9.jpg',
        'stockLogoPath': 'assets/images/stock_logo/stock_logo_5.png',
        'relatedStockName': '한화오션'},

      {'stockName': '한화오션',
        'impact': '-2.1%',
        'newsTitle': "한미 회담 분위기 좋길래 주식 샀더니… 노란봉…",
        'newsImagePath': 'assets/images/news_logo/news_logo_3.jpg',
        'stockLogoPath': 'assets/images/stock_logo/stock_logo_5.png',
        'relatedStockName': '한화오션'},
    ];

    final List<Map<String, String>> watchlistNotifications = [
      {'stockName': '한화오션',
        'impact': '+2.2%',
        'newsTitle': "한화 필리조선소 찾은 李대통령… 조선주 '들썩'",
        'newsImagePath': 'assets/images/news_logo/news_logo_1.jpg',
        'stockLogoPath': 'assets/images/stock_logo/stock_logo_5.png',
        'relatedStockName': '한화오션'},

      {'stockName': '삼성전자',
        'impact': '-0.3%',
        'newsTitle': "앤비디아 실적 경계감, 코스피 -0.15% 약보합 전환",
        'newsImagePath': 'assets/images/news_logo/news_logo_2.jpg',
        'stockLogoPath': 'assets/images/stock_logo/stock_logo_7.png',
        'relatedStockName': '삼성전자'},

      {'stockName': '삼성전자',
        'impact': '+0.1%',
        'newsTitle': "'200달러 코앞인데' 엔비디아 목표가 155달러?",
        'newsImagePath': 'assets/images/news_logo/news_logo_6.jpg',
        'stockLogoPath': 'assets/images/stock_logo/stock_logo_7.png',
        'relatedStockName': '삼성전자'},

      {'stockName': '한화오션',
        'impact': '+0.2%',
        'newsTitle': "韓조선 원팀 '최대 60조' 캐나다 사업 결선 진출…",
        'newsImagePath': 'assets/images/news_logo/news_logo_7.png',
        'stockLogoPath': 'assets/images/stock_logo/stock_logo_5.png',
        'relatedStockName': '한화오션'},

      {'stockName': '한화오션',
        'impact': '+0.9%',
        'newsTitle': "차익매물 털고 조선주 반등?… 한화오션, 프리…",
        'newsImagePath': 'assets/images/news_logo/news_logo_9.jpg',
        'stockLogoPath': 'assets/images/stock_logo/stock_logo_5.png',
        'relatedStockName': '한화오션'},

      {'stockName': '한화오션',
        'impact': '-2.1%',
        'newsTitle': "한미 회담 분위기 좋길래 주식 샀더니… 노란봉…",
        'newsImagePath': 'assets/images/news_logo/news_logo_3.jpg',
        'stockLogoPath': 'assets/images/stock_logo/stock_logo_5.png',
        'relatedStockName': '한화오션'},
    ];

    final notifications = isHoldings ? holdingsNotifications : watchlistNotifications;

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
      itemCount: notifications.length,
      itemBuilder: (context, index) {
        final notif = notifications[index];
        return Padding(

          padding: const EdgeInsets.only(top: 10.0, bottom: 10.0),
          child: NotificationCard(
            stockName: notif['stockName']!,
            impact: notif['impact']!,
            newsTitle: notif['newsTitle']!,
            newsImagePath: notif['newsImagePath']!,
            stockLogoPath: notif['stockLogoPath']!,
            relatedStockName: notif['relatedStockName']!,
          ),
        );
      },
    );
  }
}