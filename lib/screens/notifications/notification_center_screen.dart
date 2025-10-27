import 'package:flutter/material.dart';
import 'notification_settings_screen.dart';
import '../../widgets/notifications/notification_card.dart';
import '../../models/notification_model.dart';
import '../../services/api_service.dart';

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

  // [수정] API 연동을 위한 변수들
  final ApiService _apiService = ApiService();
  List<NotificationModel> _holdingsNotifications = [];
  List<NotificationModel> _watchlistNotifications = [];
  bool _isLoadingHoldings = true;
  bool _isLoadingWatchlist = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchHoldingsNotifications(); // 첫 화면인 보유 종목 알림 먼저 불러오기
    _fetchWatchlistNotifications(); // 관심 종목도 미리 불러오기
  }

  // [추가] 보유 종목 알림 API 호출
  Future<void> _fetchHoldingsNotifications() async {
    setState(() => _isLoadingHoldings = true);
    try {
      final notifications = await _apiService.fetchNotificationHistory('owned');
      if (mounted) setState(() => _holdingsNotifications = notifications);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('보유 종목 알림 로딩 실패: $e')));
    } finally {
      if (mounted) setState(() => _isLoadingHoldings = false);
    }
  }

  // [추가] 관심 종목 알림 API 호출
  Future<void> _fetchWatchlistNotifications() async {
    setState(() => _isLoadingWatchlist = true);
    try {
      final notifications = await _apiService.fetchNotificationHistory('interest');
      if (mounted) setState(() => _watchlistNotifications = notifications);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('관심 종목 알림 로딩 실패: $e')));
    } finally {
      if (mounted) setState(() => _isLoadingWatchlist = false);
    }
  }

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
                // [수정] "준비 중" 화면 대신 실제 리스트 위젯 호출
                _buildNotificationList(_holdingsNotifications, _isLoadingHoldings, _fetchHoldingsNotifications),
                _buildNotificationList(_watchlistNotifications, _isLoadingWatchlist, _fetchWatchlistNotifications),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationList(List<NotificationModel> notifications, bool isLoading, Future<void> Function() onRefresh) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.notifications_off_outlined, size: 50, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('받은 알림이 없습니다.', style: TextStyle(fontSize: 18, color: Colors.grey)),
            const SizedBox(height: 12),
            // --- [수정] 새로고침 버튼 스타일 변경 ---
            ElevatedButton(
              onPressed: onRefresh,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE8EBF2), // 배경색 변경
                foregroundColor: navyColor, // 탭 효과(ripple) 색상
                elevation: 0, // 그림자 제거
                shadowColor: Colors.transparent, // 그림자 색상 제거
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: Text(
                '새로고침',
                style: TextStyle(
                  color: navyColor, // 글자색을 남색으로 변경
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          final notification = notifications[index];
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: NotificationCard(notification: notification),
          );
        },
      ),
    );
  }
}