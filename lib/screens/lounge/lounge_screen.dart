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
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchPostsForCurrentTab(); // 초기 데이터 로드
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
      } else {
        _fetchPostsForCurrentTab();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchPostsForCurrentTab() async {
    setState(() {
      _isLoading = true;
    });

    String sort;
    switch (_tabController.index) {
      case 1:
        sort = 'latest'; // 최신순
        break;
      case 2:
        sort = 'comment'; // 댓글 많은 순
        break;
      case 0:
      default:
        sort = 'popular'; // (인기순)투표 많은 순
        break;
    }

    try {
      final posts = await apiService.fetchPosts(page: 0, size: 20, sort: sort);
      if (mounted) {
        setState(() {
          switch (sort) {
            case 'comment':
              hotPosts = posts;
              break;
            case 'popular':
              holdingsPosts = posts;
              break;
            case 'latest':
              latestPosts = posts;
              break;
          }
        });
      }
    } catch (e) {
      print('Failed to load posts for sort $sort: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('게시글을 불러오는 데 실패했습니다: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: const Text('라운지', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          Stack(
            alignment: Alignment.bottomCenter,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.0),
                child: Divider(
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
                  Tab(text: '    인기글    '),
                ],
              ),
            ],
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
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
    if (posts.isEmpty) {
      return const Center(child: Text("게시글이 없습니다."));
    }
    return RefreshIndicator(
      onRefresh: () => _fetchPostsForCurrentTab(),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
        itemCount: posts.length,
        itemBuilder: (context, index) {
          final post = posts[index];
          return GestureDetector(
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => PostDetailScreen(
                  postId: post.postId,
                  isPollPost: post.pollCount > 0,
                ),
              )).then((_) => _fetchPostsForCurrentTab()); // 상세 화면에서 돌아왔을 때 목록 새로고침
            },
            child: LoungePostCard(post: post),
          );
        },
      ),
    );
  }
}