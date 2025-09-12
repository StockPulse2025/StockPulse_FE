import 'package:flutter/material.dart';
import 'settings_screen.dart';
import '../widgets/home/home_news_section.dart';
import '../widgets/home/home_top5_section.dart';
import 'news/news_scrap_screen.dart';
import 'stocks/holdings_screen.dart';
import 'stocks/watchlist_screen.dart';
import 'lounge/lounge_activity_screen.dart';
import 'main_screen.dart';
import 'notifications/notification_center_screen.dart';


class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void showTopToast(BuildContext context) {
    final overlay = Overlay.of(context);
    OverlayEntry? entry;

    entry = OverlayEntry(
      builder: (context) => Positioned(
        top: 48,
        left: MediaQuery.of(context).size.width * 0.1,
        width: MediaQuery.of(context).size.width * 0.8,
        child: Material(
          color: Colors.transparent,
          child: GestureDetector(
            onTap: () {
              entry?.remove();
              Navigator.push(
                context,
                MaterialPageRoute(
                  // 4번째 탭이 선택된 MainScreen으로 이동
                  builder: (context) => const MainScreen(initialIndex: 4),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 8,
                  )
                ],
              ),
              child: RichText(
                text: TextSpan(
                  style: const TextStyle(
                      fontSize: 14, color: Colors.white, fontWeight: FontWeight.bold),
                  children: [
                    const TextSpan(text: "[한화오션] 주가변동 예측 영향도 "),
                    TextSpan(
                        text: "+2.2%",
                        style: const TextStyle(color: Colors.red)),
                    const TextSpan(text: " 포착 📸"),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(entry);

    Future.delayed(const Duration(seconds: 5), () {
      entry?.remove();
    });
  }

  @override
  Widget build(BuildContext context) {
    // --- [추가됨] 남색을 변수로 정의 ---
    const Color navyColor = Color(0xFF2B3A66); // 예시 남색, 원하시는 색상으로 변경 가능

    return Scaffold(
      // --- [수정됨] Scaffold의 배경색을 남색으로 변경합니다. ---
      backgroundColor: navyColor,
      appBar: AppBar(
        // --- [수정됨] AppBar의 배경색도 남색으로 통일합니다. ---
        backgroundColor: navyColor,
        surfaceTintColor: navyColor,
        elevation: 0,
        leading:
        Padding(
          padding: const EdgeInsets.only(top: 20.0),
          child: IconButton(
            iconSize: 30.0,
            // --- [수정됨] 아이콘 색상을 흰색으로 변경 ---
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ),
        actions: [
          IconButton(
            iconSize: 10.0,
            icon: const Icon(Icons.circle, color: Colors.white), // <-- 이제 아이콘이 보입니다.
            onPressed: () {
              Future.delayed(const Duration(seconds: 15), () {
                showTopToast(context);
              });
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- [수정됨] 1. 상단 남색 배경 섹션 ---
            Container(
              color: navyColor, // 이 컨테이너의 배경색을 남색으로 설정
              padding: const EdgeInsets.only(bottom: 24.0), // 하단 여백
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Transform.translate(
                    offset: const Offset(-50.0, 0),
                    child: Image.asset(
                      'assets/images/stockpulse_logo_white.png',
                      // TODO: 남색 배경에 잘 보이는 로고로 변경 필요
                      height: 60,
                      width: 350,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: RichText(
                      text: const TextSpan(
                        style: TextStyle(
                          // --- [수정됨] 기본 텍스트 색상을 흰색으로 변경 ---
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Pretendard'
                        ),
                        children: [
                          TextSpan(
                            text: '플러스',
                            style: TextStyle(color: Color(0xFFFFB31A)),
                          ),
                          TextSpan(text: '님, 반가워요!'),
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

            // --- [수정됨] 2. 하단 흰색 배경 섹션 ---
            Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                // --- [추가됨] 위쪽 모서리만 둥글게 설정 ---
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(10.0),  // 왼쪽 위
                  topRight: Radius.circular(10.0), // 오른쪽 위
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  const HomeNewsSection(),
                  const SizedBox(height: 30),
                  Container(
                    height: 8,
                    color: const Color(0xFFF9FAFB),
                  ),
                  const SizedBox(height: 20),
                  const HomeTop5Section(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickMenu(BuildContext context, String title, String imageName,
      Widget screen) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => screen));
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
                    )
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}