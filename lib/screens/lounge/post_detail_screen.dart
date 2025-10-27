import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/post_model.dart';
import '../../services/api_service.dart';
import '../../widgets/lounge/comment_widget.dart';
import '../../widgets/lounge/poll_widget.dart';
import '../../providers/user_provider.dart';
import 'package:intl/intl.dart';

class PostDetailScreen extends StatefulWidget {
  final int postId;
  final bool isPollPost;

  const PostDetailScreen({super.key, required this.postId, this.isPollPost = false});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  Post? post;
  bool isLoading = true;
  bool isSubmittingComment = false;
  final ApiService apiService = ApiService();
  final TextEditingController _commentController = TextEditingController();

  final Color navyColor = const Color(0xFF2B3A66);
  final Color dividerColor = const Color(0xFFE8EBF2);

  @override
  void initState() {
    super.initState();
    _loadPostDetail();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }


  void _showPostDeleteMenu(BuildContext iconContext) async {
    final RenderBox renderBox = iconContext.findRenderObject() as RenderBox;
    final position = renderBox.localToGlobal(Offset.zero);
    final iconSize = renderBox.size;

    final menuPosition = RelativeRect.fromLTRB(
      position.dx - 140, // 너비를 조금 더 넓게
      position.dy + iconSize.height, // 아이콘 바로 아래에 표시
      position.dx,
      position.dy + iconSize.height + 48,
    );

    final result = await showMenu<bool>(
      context: iconContext,
      position: menuPosition,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      elevation: 4,
      color: Colors.white,
      items: [
        PopupMenuItem(
          padding: EdgeInsets.zero,
          enabled: false,
          value: false,
          child: Stack(
            children: [
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pop(iconContext, true),
                  child: const Text('게시글 삭제', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                ),
              ),
              Positioned(
                top: 0,
                right: 0,
                child: IconButton(
                  icon: const Icon(Icons.close, size: 16, color: Colors.grey),
                  onPressed: () => Navigator.pop(iconContext, false),
                ),
              ),
            ],
          ),
        ),
      ],
    );

    if (result == true) {
      _showPostDeleteConfirmationDialog(iconContext);
    }
  }

  void _showPostDeleteConfirmationDialog(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('게시글 삭제', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('정말 이 게시글을 삭제하시겠습니까?', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('취소', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('삭제', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))),
        ],
      ),
    );

    if (confirm == true) {
      // 단일 게시글 삭제 API 호출
      bool success = await apiService.deletePost(post!.postId);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('게시글이 삭제되었습니다.')));
        Navigator.of(context).pop();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('게시글 삭제에 실패했습니다.')));
      }
    }
  }

  Future<void> _loadPostDetail() async {
    if (!mounted) return;
    setState(() { isLoading = true; });
    try {
      final fetchedPost = await apiService.fetchPostDetail(widget.postId);
      if (!mounted) return;
      setState(() { post = fetchedPost; });
    } catch (e) {
      if (!mounted) return;
      print('게시글 상세 정보 로드 실패: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('게시글을 불러오지 못했습니다: $e')),
      );
    } finally {
      if(mounted) { setState(() { isLoading = false; }); }
    }
  }

  Future<void> _submitComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;
    setState(() { isSubmittingComment = true; });
    try {
      final success = await apiService.submitComment(widget.postId, content);
      if (success) {
        _commentController.clear();
        FocusScope.of(context).unfocus();
        _loadPostDetail();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('댓글 작성에 실패했습니다.')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('오류: $e')));
    } finally {
      setState(() { isSubmittingComment = false; });
    }
  }

  Future<void> _handleVote(int voteType) async {
    final success = await apiService.voteOnPoll(widget.postId, voteType);
    if(success) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('투표가 완료되었습니다.')));
      _loadPostDetail();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('투표에 실패했습니다.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final currentUserNickname = userProvider.nickname;
    final bool isMyPost = currentUserNickname != null && post?.author == currentUserNickname;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.black), onPressed: () => Navigator.of(context).pop()),
        // --- AppBar에 삭제 메뉴 아이콘 추가 ---
        actions: [
          if (post != null && isMyPost)
            Builder(
              builder: (iconContext) {
                return IconButton(
                  icon: const Icon(Icons.more_horiz, color: Colors.black),
                  onPressed: () => _showPostDeleteMenu(iconContext),
                );
              },
            ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : post == null
          ? const Center(child: Text('게시글을 불러오지 못했습니다.'))
          : Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadPostDetail,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(padding: const EdgeInsets.symmetric(horizontal: 24), child: _buildPostHeader()),
                          const SizedBox(height: 16),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(post!.postTitle, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                                // 1. 제목과 본문 사이 간격 줄이기 (16 -> 8)
                                const SizedBox(height: 8),
                                Text(post!.postContent, style: const TextStyle(color: Color(0xFF7C7C7C), fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                          // 2. 본문과 토론 TOPIC 사이 간격 늘리기 (24 -> 40)
                          const SizedBox(height: 40),
                          if (post!.voteExists) // voteExists 필드로 투표 존재 여부 판단
                            PollWidget(
                              voteSummary: post!.voteSummary ?? VoteSummary(voteExists: true, total: 0, buy: 0, sell: 0, hold: 0),
                              hasVoted: post!.voteSummary?.hasVoted ?? false,
                              myVoteOption: post!.voteSummary?.myVoteOption, // 내가 투표한 옵션 전달
                              onVote: (voteType) => _handleVote(voteType),
                            ),
                          if (post!.voteExists) const SizedBox(height: 24),
                          _buildDiscussionTopic(post!),
                        ],
                      ),
                    ),
                    Container(
                      height: 8,
                      color: dividerColor,
                    ),

                    // --- 댓글 영역 ---
                    Padding(
                      // 3 & 4. 댓글 영역 여백 및 헤더
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                      child: Row(
                        children: [
                          const Icon(Icons.chat_bubble_outline, size: 16, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(post!.commentCount.toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
                          if (widget.isPollPost) ...[
                            const SizedBox(width: 12),
                            const Icon(Icons.poll_outlined, size: 16, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(post!.pollCount.toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ],
                      ),
                    ),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: post!.comments?.length ?? 0,
                      separatorBuilder: (context, index) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Divider(color: dividerColor, height: 1),
                      ),
                      itemBuilder: (context, index) {
                        final comment = post!.comments![index];
                        final bool isMyComment = currentUserNickname != null && comment.author == currentUserNickname;

                        return CommentWidget(
                          author: comment.author,
                          content: comment.content,
                          isMyComment: isMyComment,
                          commentId: comment.id,
                          onDeleteApi: (id) async {
                           bool success = await apiService.deleteComment(id);
                            if (success) _loadPostDetail();
                            return success;
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          _buildCommentInput(),
        ],
      ),
    );
  }

  Widget _buildPostHeader() {
    final DateFormat dateFormat = DateFormat('yyyy.MM.dd');
    final DateFormat timeFormat = DateFormat('HH:mm');
    final postDateTimeInfo = '${dateFormat.format(post!.createdAt)}｜${timeFormat.format(post!.createdAt)}';

    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(color: dividerColor, borderRadius: BorderRadius.circular(4)),
          child: const Icon(Icons.person, color: Colors.white),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(post!.author, style: const TextStyle(fontWeight: FontWeight.bold)),
            // --- 2. 포맷팅된 날짜/시간 표시 ---
            Text(postDateTimeInfo, style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        )
      ],
    );
  }

  Widget _buildDiscussionTopic(Post post) {
    // --- 1. 데이터 포맷팅 로직 ---
    final NumberFormat priceFormat = NumberFormat('###,###,###,###');
    final DateFormat newsDateFormat = DateFormat('yyyy.MM.dd');

    // 가격 및 등락률
    final priceString = post.stockPrice != null ? '${priceFormat.format(post.stockPrice)}원' : ' - ';
    final changeRate = post.stockChangeRate ?? 0.0;
    final isUp = changeRate >= 0;
    final changeRateString = '${isUp ? '+' : ''}${changeRate.toStringAsFixed(2)}%';

    // 뉴스 정보
    final newsDate = post.newsPublishedDate != null ? newsDateFormat.format(post.newsPublishedDate!) : '';
    final newsInfo = '${post.newsSource ?? ''} ${newsDate.isNotEmpty ? '｜ $newsDate' : ''}';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('토론 TOPIC 💬', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          // --- 2. 사라졌던 IntrinsicHeight와 Row 구조 복원 ---
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // --- 3. 사라졌던 남색 막대 복원 ---
                Container(width: 4, color: const Color(0xFF2B3A66)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    children: [
                      // --- 뉴스 카드 ---
                      Container(
                        padding: const EdgeInsets.all(12),
                        color: const Color(0xFFF9FAFB),
                        child: Row(
                          children: [
                            // --- 4. 사라졌던 뉴스 이미지 복원 ---
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: post.newsImageUrl != null && post.newsImageUrl!.isNotEmpty
                                  ? Image.network(post.newsImageUrl!, width: 50, height: 50, fit: BoxFit.cover)
                                  : Container(width: 50, height: 50, color: Colors.grey.shade200, child: const Icon(Icons.article)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(post.newsTitle ?? '', style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 2, overflow: TextOverflow.ellipsis),
                                  const SizedBox(height: 4),
                                  Text(newsInfo, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      // --- 주식 카드 ---
                      if (post.stockName != null)
                        Container(
                          padding: const EdgeInsets.all(12),
                          color: const Color(0xFFF9FAFB),
                          child: Row(
                            children: [
                              // --- 5. 사라졌던 주식 로고 복원 ---
                              CircleAvatar(
                                backgroundImage: post.stockLogoUrl != null && post.stockLogoUrl!.isNotEmpty
                                    ? NetworkImage(post.stockLogoUrl!)
                                    : null,
                                child: post.stockLogoUrl == null || post.stockLogoUrl!.isEmpty ? const Icon(Icons.business) : null,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(post.stockName ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                                    Row(
                                      children: [
                                        // --- 6. 포맷팅된 가격 및 등락률 표시 ---
                                        Text(priceString,
                                            style: TextStyle(color: Color(0xFF585858))
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                            changeRateString,
                                            style: TextStyle(color: isUp ? Colors.red : Colors.blue)
                                        )
                                      ],
                                    )
                                  ],
                                ),
                              ),
                            ],
                          ),
                        )
                    ],
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildCommentInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 5, offset: const Offset(0, -2))]),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _commentController,
              decoration: InputDecoration(
                hintText: '의견을 남겨주세요.',
                hintStyle: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFC2C2C2)),
                filled: true,
                // 5. 입력 필드 배경색 변경
                fillColor: dividerColor,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // 5. 등록 버튼 스타일 변경
          TextButton(
            onPressed: isSubmittingComment ? null : _submitComment,
            style: TextButton.styleFrom(
              backgroundColor: Colors.white, // 배경 흰색
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            child: isSubmittingComment
                ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: navyColor, strokeWidth: 2.0))
                : Text(
              '등록',
              style: TextStyle(fontWeight: FontWeight.bold, color: navyColor), // 글자색 남색
            ),
          ),
        ],
      ),
    );
  }
}
