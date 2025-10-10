import 'package:flutter/material.dart';
import '../../widgets/lounge/lounge_post_card.dart';
import '../../services/api_service.dart';
import 'package:stockpulse2/models/post_model.dart';

class LoungeActivityScreen extends StatefulWidget {
  const LoungeActivityScreen({super.key});

  @override
  State<LoungeActivityScreen> createState() => _LoungeActivityScreenState();
}

class _LoungeActivityScreenState extends State<LoungeActivityScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiService apiService = ApiService();

  final Color navyColor = const Color(0xFF2B3A66);
  final Set<int> _selectedPostIds = {};

  List<Post> myPosts = [];
  List<Post> myCommentedPosts = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchActivityPosts();
  }

  Future<void> _fetchActivityPosts() async {
    try {
      final fetchedMyPosts = await apiService.fetchMyPosts();
      final fetchedMyCommentedPosts = await apiService.fetchMyCommentedPosts();

      setState(() {
        myPosts = fetchedMyPosts;
        myCommentedPosts = fetchedMyCommentedPosts;
      });
    } catch (e) {
      print('Error loading activity posts: $e');
    }
  }

  bool get _isAllSelected {
    final currentList = _tabController.index == 0 ? myPosts : myCommentedPosts;
    if (currentList.isEmpty) return false;
    return _selectedPostIds.length == currentList.length;
  }

  void _deleteSelected() async {
    try {
      final success = await apiService.deletePosts(_selectedPostIds.toList());
      if (success) {
        setState(() {
          final currentList = _tabController.index == 0 ? myPosts : myCommentedPosts;
          currentList.removeWhere((post) => _selectedPostIds.contains(post.postId));
          _selectedPostIds.clear();
        });
      }
    } catch (e) {
      print('Error deleting posts: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentList = _tabController.index == 0 ? myPosts : myCommentedPosts;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.black), onPressed: () => Navigator.pop(context)),
        titleSpacing: 0,
        centerTitle: false,
        title: const Text('라운지 활동 관리', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
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
                indicatorColor: navyColor,
                indicatorWeight: 3.0,
                indicatorSize: TabBarIndicatorSize.label,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                dividerColor: Colors.transparent,
                tabs: const [
                  Tab(text: '작성한 게시글'),
                  Tab(text: '댓글 단 게시글'),
                ],
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                Checkbox(
                  value: _isAllSelected,
                  activeColor: navyColor,
                  onChanged: (value) {
                    setState(() {
                      if (value!) {
                        _selectedPostIds.addAll(currentList.map((post) => post.postId));
                      } else {
                        _selectedPostIds.clear();
                      }
                    });
                  },
                ),
                const Text('전체 선택', style: TextStyle(fontWeight: FontWeight.bold)),
                const Spacer(),
                TextButton(
                  onPressed: _selectedPostIds.isEmpty ? null : _deleteSelected,
                  child: Text('선택 삭제', style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _selectedPostIds.isEmpty ? Colors.grey : navyColor,
                  )),
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildActivityList(myPosts),
                _buildActivityList(myCommentedPosts),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityList(List<Post> posts) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      itemCount: posts.length,
      itemBuilder: (context, index) {
        final post = posts[index];
        final int postId = post.postId;
        return Row(
          children: [
            Checkbox(
              value: _selectedPostIds.contains(postId),
              activeColor: navyColor,
              onChanged: (value) {
                setState(() {
                  if (value!) {
                    _selectedPostIds.add(postId);
                  } else {
                    _selectedPostIds.remove(postId);
                  }
                });
              },
            ),
            const SizedBox(width: 4),
            Expanded(child: LoungePostCard(post: post)),
          ],
        );
      },
    );
  }
}