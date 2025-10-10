import 'package:flutter/material.dart';
import '../../models/post_model.dart';
import '../../models/comment_model.dart';
import '../../services/api_service.dart';
import '../../widgets/lounge/comment_widget.dart';
import '../../widgets/lounge/poll_widget.dart';

class PostDetailScreen extends StatefulWidget {
  final int postId;
  final bool isPollPost;

  const PostDetailScreen({super.key, required this.postId, required this.isPollPost});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  Post? post;
  List<Comment> comments = [];
  bool isLoadingPost = true;
  bool isLoadingComments = true;
  bool isSubmittingComment = false;
  final ApiService apiService = ApiService();

  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPost();
    _loadComments();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadPost() async {
    try {
      final fetchedPost = await apiService.fetchPostDetail(widget.postId);
      setState(() {
        post = fetchedPost;
        isLoadingPost = false;
      });
    } catch (e) {
      setState(() {
        isLoadingPost = false;
      });
    }
  }

  Future<void> _loadComments() async {
    try {
      final fetchedComments = await apiService.fetchComments(widget.postId);
      setState(() {
        comments = fetchedComments;
        isLoadingComments = false;
      });
    } catch (e) {
      setState(() {
        isLoadingComments = false;
      });
    }
  }

  void _refreshComments() {
    _loadComments();
  }

  Future<void> _submitComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;

    setState(() {
      isSubmittingComment = true;
    });

    try {
      final success = await apiService.submitComment(widget.postId, content);
      if (success) {
        _commentController.clear();
        _refreshComments();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('댓글 작성에 실패했습니다.')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('오류: $e')));
    } finally {
      setState(() {
        isSubmittingComment = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoadingPost) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (post == null) {
      return const Scaffold(body: Center(child: Text('게시글을 불러오지 못했습니다.')));
    }
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.black), onPressed: () => Navigator.of(context).pop()),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
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
                        const SizedBox(height: 16),
                        Text(post!.postContent, style: const TextStyle(color: Color(0xFF7C7C7C), fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (widget.isPollPost) const PollWidget(),
                  if (widget.isPollPost) const SizedBox(height: 24),
                  _buildDiscussionTopic(post!),
                  const Divider(height: 32),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
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
                  const SizedBox(height: 8),
                  isLoadingComments
                      ? const Center(child: CircularProgressIndicator())
                      : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: comments.length,
                    itemBuilder: (context, index) {
                      final comment = comments[index];
                      return CommentWidget(
                        author: comment.author,
                        content: comment.content,
                        isMyComment: comment.isMine,
                        commentId: comment.id,
                        onEditApi: (id, newContent) async {
                          bool success = await apiService.editComment(id, newContent);
                          if (success) _refreshComments();
                          return success;
                        },
                        onDeleteApi: (id) async {
                          bool success = await apiService.deleteComment(id);
                          if (success) _refreshComments();
                          return success;
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          _buildCommentInput(),
        ],
      ),
    );
  }

  Widget _buildPostHeader() {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(color: const Color(0xFFE8EBF2), borderRadius: BorderRadius.circular(4)),
          child: const Icon(Icons.person, color: Colors.white),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(post!.author, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(post!.createdAt.toString(), style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        )
      ],
    );
  }

  Widget _buildDiscussionTopic(Post post) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('토론 TOPIC💬', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(width: 4, color: const Color(0xFF2B3A66)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        color: const Color(0xFFF9FAFB),
                        child: Row(
                          children: [
                            Image.asset('assets/images/news_logo/news_logo_9.jpg', width: 50, height: 50, fit: BoxFit.cover),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(post.newsTitle ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  Text(post.newsSource ?? '', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        color: const Color(0xFFF9FAFB),
                        child: Row(
                          children: [
                            const CircleAvatar(backgroundImage: AssetImage('assets/images/stock_logo/stock_logo_5.png')),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(post.stockName ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  Row(
                                    children: [Text(post.stockPrice?.toString() ?? ''), const SizedBox(width: 8), const Text('+2.2%', style: TextStyle(color: Colors.red))],
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
                hintStyle: const TextStyle(fontWeight: FontWeight.bold),
                filled: true,
                fillColor: Colors.grey[200],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: isSubmittingComment ? null : _submitComment,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2B3A66),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            child: isSubmittingComment
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text(
              '등록',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
