class Comment {
  final int id;
  final String author;
  final String content;
  final String createdAt;
  // final bool isMine;

  Comment({
    required this.id,
    required this.author,
    required this.content,
    required this.createdAt,
    // required this.isMine,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['commentId'],
      author: json['author'],
      content: json['content'],
      createdAt: json['createdAt'],
      // isMine: json['isMine'] ?? false,
    );
  }
}