class Post {
  final int postId;
  final String postTitle;
  final String postContent;
  final String author;
  final DateTime createdAt;
  final int commentCount;
  final int pollCount;

  final String? postImageUrl;
  final String? stockLogoUrl;
  final String? stockName;
  final int? stockPrice;
  final String? stockChange;

  final String? newsTitle;
  final String? newsSource;

  Post({
    required this.postId,
    required this.postTitle,
    required this.postContent,
    required this.author,
    required this.createdAt,
    required this.commentCount,
    required this.pollCount,
    this.postImageUrl,
    this.stockLogoUrl,
    this.stockName,
    this.stockPrice,
    this.stockChange,
    this.newsTitle,
    this.newsSource,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      postId: json['postId'],
      postTitle: json['postTitle'],
      postContent: json['postContent'],
      author: json['author'],
      createdAt: DateTime.parse(json['createdAt']),
      commentCount: json['commentCount'],
      pollCount: json['pollCount'],
      postImageUrl: json['postImageUrl'],
      stockLogoUrl: json['stockLogoUrl'],
      stockName: json['stockName'],
      stockPrice: json['stockPrice'],
      stockChange: json['stockChange'],
      newsTitle: json['newsTitle'],
      newsSource: json['newsSource'],
    );
  }
}
