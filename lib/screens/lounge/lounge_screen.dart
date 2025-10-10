import 'package:flutter/material.dart';
import '../../widgets/lounge/lounge_post_card.dart';
import 'post_detail_screen.dart';
import '../../services/api_service.dart';
import 'package:stockpulse2/models/post_model.dart';

class LoungeScreen extends StatefulWidget {
  const LoungeScreen({super.key});

  @override
  State<LoungeScreen> createState() => _LoungeScreenState();
}

class _LoungeScreenState extends State<LoungeScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  final Color navyColor = const Color(0xFF2B3A66);
  final ApiService apiService = ApiService();

  List<Post> latestPosts = [];
  List<Post> hotPosts = [];
  List<Post> holdingsPosts = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchPosts();
  }

  Future<void> _fetchPosts() async {
    try {
     final posts = await apiService.fetchPosts(page: 1, size: 50);

      setState(() {
        latestPosts = posts; // 최신순
        hotPosts = posts;    // 구현 필요?
        holdingsPosts = posts; // 구현 필요?
      });
    } catch (e) {
      print('Failed to load posts: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('라운지', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ),
      body: Column(
        children: [
          Stack(
            alignment: Alignment.bottomCenter,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: const Divider(
                  height: 1,
                  thickness: 2,
                  color: Color(0xFFE8EBF2),
                ),
              ),
              TabBar(
                controller: _tabController,
                labelColor: navyColor,
                unselectedLabelColor: Colors.grey,
                indicatorColor: navyColor,
                indicatorWeight: 3.0,
                indicatorSize: TabBarIndicatorSize.label,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                dividerColor: Colors.transparent,
                tabs: const [
                  Tab(text: '      최신      '),
                  Tab(text: '논의가 활발해요🔥'),
                  Tab(text: '    보유종목    '),
                ],
              ),
            ],
          ),
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

  Widget _buildPostList(List<Post> posts) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
      itemCount: posts.length,
      itemBuilder: (context, index) {
        final post = posts[index];
        return GestureDetector(
          onTap: () {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => PostDetailScreen(
                postId: posts[index].postId,
                isPollPost: posts[index].pollCount > 0,
              ),
            ));
          },
          child: LoungePostCard(post: post),
        );
      },
    );
  }
}