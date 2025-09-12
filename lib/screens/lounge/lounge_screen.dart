import 'package:flutter/material.dart';
import '../../widgets/lounge/lounge_post_card.dart';
import 'post_detail_screen.dart';
import 'package:stockpulse2/data/dummy_post_data.dart';

class LoungeScreen extends StatefulWidget {
  const LoungeScreen({super.key});

  @override
  State<LoungeScreen> createState() => _LoungeScreenState();
}

class _LoungeScreenState extends State<LoungeScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  final Color navyColor = const Color(0xFF2B3A66);

  // --- [추가됨] 각 탭에 표시될 데이터 리스트 ---
  List<PostData> latestPosts = [];
  List<PostData> hotPosts = [];
  List<PostData> holdingsPosts = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // --- [추가됨] 더미 데이터를 각 탭의 순서에 맞게 재정렬 ---
    // 최신순 (id 역순)
    latestPosts = List.from(dummyPosts)..sort((a, b) => a['id'].compareTo(b['id']));
    // 논의 활발 순 (댓글 + 투표 합산 역순)
    hotPosts = List.from(dummyPosts)..sort((a, b) => (b['commentCount'] + b['pollCount']).compareTo(a['commentCount'] + a['pollCount']));
    // 보유 종목 (임의로 섞기)
    holdingsPosts = List.from(dummyPosts)..shuffle();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        title: const Text('라운지', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ),
      // --- [수정됨] body 구조를 Stack을 사용하는 방식으로 전면 수정 ---
      body: Column(
        children: [
          // 1. 탭바와 구분선을 겹치기 위한 Stack
          Stack(
            alignment: Alignment.bottomCenter,
            children: [
              // 1-1. 배경: 좌우 여백이 있는 회색 구분선
              Padding(
                // 다른 콘텐츠의 좌우 여백(24.0)과 동일하게 설정
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: const Divider(
                  height: 1, // 높이를 1로 하여 TabBar와 거의 겹치게 함
                  thickness: 2,
                  color: Color(0xFFE8EBF2),
                ),
              ),
              // 1-2. 전경: TabBar
              TabBar(
                controller: _tabController,
                labelColor: navyColor,
                unselectedLabelColor: Colors.grey,
                indicatorColor: navyColor,
                indicatorWeight: 3.0,
                indicatorSize: TabBarIndicatorSize.label,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                // TabBar 자체의 구분선은 투명하게 만들어 Stack의 Divider만 보이게 함
                dividerColor: Colors.transparent,
                tabs: [
                  const Tab(text: '      최신      '),
                  Tab(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text('논의가 활발해요🔥', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const Tab(text: '    보유종목    '),
                ],
              ),
            ],
          ),

          // 2. 나머지 공간을 모두 차지하는 TabBarView
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildPostList(latestPosts),
                _buildPostList(hotPosts),
                _buildPostList(holdingsPosts),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostList(List<PostData> posts) {
    return ListView.builder(
      // --- [수정됨] 전체 좌우 여백 추가 ---
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
      itemCount: posts.length,
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () {
            Navigator.of(context).push(MaterialPageRoute(builder: (context) => PostDetailScreen(isPollPost: index.isEven)));
          },
          child: LoungePostCard(post: posts[index]),
        );
      },
    );
  }
}