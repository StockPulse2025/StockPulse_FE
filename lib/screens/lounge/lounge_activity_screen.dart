import 'package:flutter/material.dart';
import '../../widgets/lounge/lounge_post_card.dart';
import '../../data/dummy_post_data.dart';

class LoungeActivityScreen extends StatefulWidget {
  const LoungeActivityScreen({super.key});

  @override
  State<LoungeActivityScreen> createState() => _LoungeActivityScreenState();
}

class _LoungeActivityScreenState extends State<LoungeActivityScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // --- [수정됨] 선택된 아이템을 index가 아닌 고유 id로 관리 ---
  final Set<int> _selectedPostIds = {};

  // --- [수정됨] 각 탭에 표시될 데이터 리스트 ---
  List<PostData> myPosts = [];
  List<PostData> myCommentedPosts = [];

  final Color navyColor = const Color(0xFF2B3A66);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // --- [수정됨] 더미 데이터를 랜덤하게 섞어서 각 리스트에 할당 ---
    myPosts = List.from(dummyPosts)..shuffle();
    myCommentedPosts = List.from(dummyPosts)..shuffle();
  }

  // --- [추가됨] 전체 선택 상태를 동적으로 계산하는 getter ---
  bool get _isAllSelected {
    final currentList = _tabController.index == 0 ? myPosts : myCommentedPosts;
    if (currentList.isEmpty) return false;
    return _selectedPostIds.length == currentList.length;
  }

  // --- [추가됨] 선택 삭제 기능 함수 ---
  void _deleteSelected() {
    setState(() {
      final currentList = _tabController.index == 0 ? myPosts : myCommentedPosts;
      currentList.removeWhere((post) => _selectedPostIds.contains(post['id']));
      _selectedPostIds.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    // 현재 활성화된 탭에 따라 리스트를 결정
    final currentList = _tabController.index == 0 ? myPosts : myCommentedPosts;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        // --- [수정됨] AppBar 제목 스타일 ---
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.black), onPressed: () => Navigator.pop(context)),
        titleSpacing: 0,
        centerTitle: false,
        title: const Text('라운지 활동 관리', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          // --- [수정됨] 탭바와 구분선 UI 변경 ---
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
                tabs: const [Tab(text: '작성한 게시글'), Tab(text: '댓글 단 게시글')],
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                // --- [수정됨] 체크박스 스타일 및 기능 ---
                Checkbox(
                  value: _isAllSelected,
                  activeColor: navyColor, // 선택 시 색상
                  onChanged: (value) {
                    setState(() {
                      if (value!) {
                        _selectedPostIds.addAll(currentList.map((post) => post['id'] as int));
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
                    child: Text(
                        '선택 삭제',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _selectedPostIds.isEmpty ? Colors.grey : navyColor
                        )
                    )
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildActivityList(myPosts),
                _buildActivityList(myCommentedPosts)
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityList(List<PostData> posts) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      itemCount: posts.length,
      itemBuilder: (context, index) {
        final post = posts[index];
        final int postId = post['id'];
        return Row(
          children: [
            // --- [수정됨] 체크박스 스타일 및 기능 ---
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
            // --- [수정됨] 체크박스와 카드 사이 간격 축소 ---
            const SizedBox(width: 4),
            Expanded(child: LoungePostCard(post: post)),
          ],
        );
      },
    );
  }
}