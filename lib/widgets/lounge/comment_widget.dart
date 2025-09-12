import 'package:flutter/material.dart';

class CommentWidget extends StatelessWidget {
  final String author;
  final String content;
  final bool isMyComment;

  const CommentWidget({
    super.key,
    required this.author,
    required this.content,
    required this.isMyComment,
  });

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
              onPressed: () { /* TODO: 삭제/수정 메뉴 표시 */ },
            )
        ],
      ),
    );
  }
}