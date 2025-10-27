import 'package:flutter/material.dart';

class CommentWidget extends StatelessWidget {
  final String author;
  final String content;
  final bool isMyComment;
  final int commentId;
  final Future<bool> Function(int commentId) onDeleteApi;

  const CommentWidget({
    super.key,
    required this.author,
    required this.content,
    required this.isMyComment,
    required this.commentId,
    required this.onDeleteApi,
  });

  void _showDeleteMenu(BuildContext iconContext) async {
    final RenderBox renderBox = iconContext.findRenderObject() as RenderBox;
    final position = renderBox.localToGlobal(Offset.zero);
    final iconSize = renderBox.size;

    final menuPosition = RelativeRect.fromLTRB(
      position.dx - 120,
      position.dy + iconSize.height / 2 - 24,
      position.dx,
      position.dy + iconSize.height / 2 + 24,
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
                  onPressed: () {
                    Navigator.pop(iconContext, true);
                  },
                  child: const Text(
                    '댓글 삭제',
                    style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              Positioned(
                top: 0,
                right: 0,
                child: IconButton(
                  icon: const Icon(Icons.close, size: 16, color: Colors.grey),
                  onPressed: () {
                    Navigator.pop(iconContext, false);
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );

    if (result == true) {
      _showDeleteConfirmationDialog(iconContext);
    }
  }

  void _showDeleteConfirmationDialog(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text(
          '댓글 삭제',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          '정말 이 댓글을 삭제하시겠습니까?',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(
              '취소',
              style: TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              '삭제',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      bool success = await onDeleteApi(commentId);
      if (!success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('댓글 삭제에 실패했습니다.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFE8EBF2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person, color: Colors.white),
          ),
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
            Builder(
              builder: (iconContext) {
                return IconButton(
                  icon: const Icon(Icons.more_horiz),
                  onPressed: () {
                    _showDeleteMenu(iconContext);
                  },
                );
              },
            ),
        ],
      ),
    );
  }
}