import 'package:flutter/material.dart';

// 댓글 수정 다이얼로그 함수
Future<String?> showEditCommentDialog(BuildContext context, String initialContent) {
  final TextEditingController _controller = TextEditingController(text: initialContent);

  return showDialog<String>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('댓글 수정'),
        content: TextField(
          controller: _controller,
          maxLines: 5,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: '댓글 내용을 입력하세요',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context, _controller.text.trim());
            },
            child: const Text('저장'),
          ),
        ],
      );
    },
  );
}

class CommentWidget extends StatelessWidget {
  final String author;
  final String content;
  final bool isMyComment;
  final int commentId;
  final Future<bool> Function(int commentId, String newContent) onEditApi;
  final Future<bool> Function(int commentId) onDeleteApi;

  const CommentWidget({
    super.key,
    required this.author,
    required this.content,
    required this.isMyComment,
    required this.commentId,
    required this.onEditApi,
    required this.onDeleteApi,
  });

  void _showOptionsMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('댓글 수정'),
                onTap: () async {
                  Navigator.pop(context);
                  final editedContent = await showEditCommentDialog(context, content);
                  if (editedContent != null && editedContent.isNotEmpty) {
                    bool success = await onEditApi(commentId, editedContent);
                    if (success) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('댓글이 수정되었습니다.')));
                      // 필요시 상태 갱신 콜백 실행 추가 가능
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('댓글 수정에 실패했습니다.')));
                    }
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete),
                title: const Text('댓글 삭제'),
                onTap: () async {
                  Navigator.pop(context);
                  bool success = await onDeleteApi(commentId);
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('댓글이 삭제되었습니다.')));
                    // 필요시 상태 갱신 콜백 실행 추가 가능
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('댓글 삭제에 실패했습니다.')));
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.close),
                title: const Text('취소'),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CircleAvatar(radius: 18, child: Icon(Icons.person)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(author, style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(content),
              ],
            ),
          ),
          if (isMyComment)
            IconButton(
              icon: const Icon(Icons.more_horiz),
              onPressed: () => _showOptionsMenu(context),
            )
        ],
      ),
    );
  }
}
