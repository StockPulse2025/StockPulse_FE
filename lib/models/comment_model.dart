class Comment {
  final int id;
  final String author;
  final String content;
  final bool isMine; // 본인이 쓴 댓글인지 여부
  final DateTime createdAt;

  Comment({
    required this.id,
    required this.author,
    required this.content,
    required this.isMine,
    required this.createdAt,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['commentId'],
      author: json['author'],
      content: json['content'],
      isMine: json['isMine'] ?? false, // 서버에서 여부 제공 시 사용
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'commentId': id,
      'author': author,
      'content': content,
      'isMine': isMine,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
