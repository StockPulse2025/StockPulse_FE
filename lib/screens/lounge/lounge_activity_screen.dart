import 'package:flutter/material.dart';
import '../../widgets/lounge/lounge_post_card.dart';
import '../../services/api_service.dart';
import 'package:stockpulse2/models/post_model.dart';
import 'post_detail_screen.dart';

class LoungeActivityScreen extends StatefulWidget {
  const LoungeActivityScreen({super.key});

  @override
  State<LoungeActivityScreen> createState() => _LoungeActivityScreenState();
}

class _LoungeActivityScreenState extends State<LoungeActivityScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiService apiService = ApiService();

  final Color navyColor = const Color(0xFF2B3A66);
  final Set<int> _selectedItemIds = {};

  List<Post> myPosts = [];
  List<Post> myCommentedPosts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchActivityPosts();
    _tabController.addListener(() {
      if (mounted) {
        setState(() {
          _selectedItemIds.clear();
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchActivityPosts() async {
    if (mounted) setState(() { _isLoading = true; });
    try {
      final fetchedMyPosts = await apiService.fetchMyPosts();
      final fetchedMyCommentedPosts = await apiService.fetchMyCommentedPosts();
      if (mounted) {
        setState(() {
          myPosts = fetchedMyPosts;
          myCommentedPosts = fetchedMyCommentedPosts;
        });
      }
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('활동 내역을 불러오는 데 실패했습니다: $e')));
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  bool get _isAllSelected {
    final isMyPostTab = _tabController.index == 0;
    final currentList = isMyPostTab ? myPosts : myCommentedPosts;
    if (currentList.isEmpty) return false;

    final allIds = isMyPostTab
        ? currentList.map((p) => p.postId).toSet()
        : currentList.map((p) => p.myCommentId).where((id) => id != null).cast<int>().toSet();

    if (allIds.isEmpty) return false;
    return _selectedItemIds.containsAll(allIds) && _selectedItemIds.length == allIds.length;
  }

  void _deleteSelected() async {
    final isMyPostTab = _tabController.index == 0;
    final idsToDelete = _selectedItemIds.toList();
    if (idsToDelete.isEmpty) return;

    final String title = isMyPostTab ? '게시글 삭제' : '댓글 삭제';
    final String content = isMyPostTab
        ? '${idsToDelete.length}개의 게시글을 정말 삭제하시겠습니까?'
        : '선택한 ${idsToDelete.length}개의 댓글을 정말 삭제하시겠습니까?';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(content, style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('취소', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text('삭제', style: TextStyle(color: navyColor, fontWeight: FontWeight.bold))),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final bool success = isMyPostTab
          ? await apiService.deletePosts(idsToDelete)
          : await apiService.deleteComments(idsToDelete);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('선택한 항목이 삭제되었습니다.')));
        _fetchActivityPosts();
        setState(() { _selectedItemIds.clear(); });
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('삭제에 실패했습니다. 다시 시도해주세요.')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('삭제 중 오류가 발생했습니다: $e')));
    }
  }

  // ====================== [ _buildActivityList 함수를 여기로 이동] ======================
  // build 메서드보다 먼저 선언되어야 참조 오류가 발생하지 않습니다.
  Widget _buildActivityList(List<Post> posts) {
    final bool isMyPostTab = _tabController.index == 0;

    if (posts.isEmpty) {
      return const Center(child: Text("내역이 없습니다."));
    }
    return RefreshIndicator(
      onRefresh: _fetchActivityPosts,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        itemCount: posts.length,
        itemBuilder: (context, index) {
          final post = posts[index];
          final int? itemId = isMyPostTab ? post.postId : post.myCommentId;

          return Row(
            children: [
              Checkbox(
                value: itemId != null && _selectedItemIds.contains(itemId),
                activeColor: navyColor,
                onChanged: itemId == null ? null : (value) {
                  setState(() {
                    if (value!) {
                      _selectedItemIds.add(itemId);
                    } else {
                      _selectedItemIds.remove(itemId);
                    }
                  });
                },
              ),
              const SizedBox(width: 4),
              Expanded(
                  child: GestureDetector(
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => PostDetailScreen(postId: post.postId, isPollPost: post.voteExists))).then((_) => _fetchActivityPosts()),
                      child: LoungePostCard(post: post)
                  )
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMyPostTab = _tabController.index == 0;
    final currentList = isMyPostTab ? myPosts : myCommentedPosts;

    return Scaffold(
      backgroundColor: Colors.white,
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
                        final allIds = isMyPostTab
                            ? currentList.map((p) => p.postId)
                            : currentList.map((p) => p.myCommentId).where((id) => id != null).cast<int>();
                        _selectedItemIds.addAll(allIds);
                      } else {
                        _selectedItemIds.clear();
                      }
                    });
                  },
                ),
                const Text('전체 선택', style: TextStyle(fontWeight: FontWeight.bold)),
                const Spacer(),
                TextButton(
                  onPressed: _selectedItemIds.isEmpty ? null : _deleteSelected,
                  child: Text('선택 삭제', style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _selectedItemIds.isEmpty ? Colors.grey : navyColor,
                  )),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
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
}