import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'news/news_room_screen.dart';
import 'stocks/stock_main_screen.dart';
import 'lounge/lounge_screen.dart';
import 'notifications/notification_center_screen.dart';

class MainScreen extends StatefulWidget {
  final int initialIndex;
  const MainScreen({super.key, this.initialIndex = 0});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  static const List<Widget> _widgetOptions = <Widget>[
    HomeScreen(),
    NewsRoomScreen(),
    StockMainScreen(),
    LoungeScreen(),
    NotificationCenterScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: '홈'),
          BottomNavigationBarItem(icon: Icon(Icons.description), label: '뉴스룸'),
          BottomNavigationBarItem(icon: Icon(Icons.candlestick_chart), label: '주식종목'),
          BottomNavigationBarItem(icon: Icon(Icons.forum), label: '라운지'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications), label: '알림센터'),
        ],
        currentIndex: _selectedIndex,
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