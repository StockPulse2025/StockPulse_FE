import 'comment_model.dart';

class VoteSummary {
  final bool voteExists;
  final int total;
  final int buy;
  final int sell;
  final int hold;
  final bool? hasVoted; // 내가 투표했는지 (voted)
  final String? myVoteOption; // 내가 어떤 항목에 투표했는지 (BUY, SELL, HOLD)

  VoteSummary({
    required this.voteExists,
    required this.total,
    required this.buy,
    required this.sell,
    required this.hold,
    this.hasVoted,
    this.myVoteOption,
  });

  factory VoteSummary.fromJson(Map<String, dynamic> json) {
    return VoteSummary(
      voteExists: json['voteExists'] ?? false,
      total: json['total'] ?? 0,
      buy: json['buy'] ?? 0,
      sell: json['sell'] ?? 0,
      hold: json['hold'] ?? 0,
      hasVoted: json['voted'],
      myVoteOption: json['myVoteOption'],
    );
  }
}


class Post {
  final int postId;
  final String postTitle;
  final String postContent;
  final String author;
  final DateTime createdAt;
  final int commentCount;
  final bool voteExists;
  final int pollCount;

  final String? newsImageUrl;
  final int? newsId;
  final String? newsTitle;
  final DateTime? newsPublishedDate;
  final String? newsSource;

  final int? stockId;
  final String? stockLogoUrl;
  final String? stockName;
  final int? stockPrice;
  final double? stockChangeRate;

  final int? myCommentId;
  final VoteSummary? voteSummary;
  final List<Comment>? comments;
  final bool? userVoted;
  final int? userVoteType;

  Post({
    required this.postId,
    required this.postTitle,
    required this.postContent,
    required this.author,
    required this.createdAt,
    required this.commentCount,
    required this.voteExists,
    required this.pollCount,
    this.newsImageUrl,
    this.newsId,
    this.newsTitle,
    this.newsPublishedDate,
    this.newsSource,
    this.stockId,
    this.stockLogoUrl,
    this.stockName,
    this.stockPrice,
    this.stockChangeRate,
    this.voteSummary,
    this.comments,
    this.myCommentId,
    this.userVoted,
    this.userVoteType,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    final stockDetail = json['stockDetail'] as Map<String, dynamic>?;
    print('[Post.fromJson] 서버로부터 받은 원본 데이터: $json');
    return Post(
      postId: json['postId'],
      postTitle: json['title'],
      postContent: json['content'] ?? json['contentSummary'] ?? '',
      author: json['author'],
      createdAt: DateTime.parse(json['createdAt'] ?? json['updatedAt']),
      commentCount: json['commentCount'] ?? 0,
      voteExists: json['voteExists'] as bool? ?? (json['voteSummary']?['voteExists'] as bool? ?? false),
      pollCount: json['voteCount'] ?? (json['voteSummary'] != null ? json['voteSummary']['total'] : 0),
      myCommentId: json['commentId'],

      newsImageUrl: json['newsImageUrl'],
      newsId: json['newsId'],
      newsTitle: json['newsTitle'],
      newsPublishedDate: json['newsPublishedDate'] != null
          ? DateTime.parse(json['newsPublishedDate'])
          : null,
      newsSource: json['press'] ?? json['newsPublisher'],

      stockId: stockDetail?['stockId'],
      stockLogoUrl: stockDetail?['imageUrl'],
      stockName: stockDetail?['name'],
      stockPrice: stockDetail?['currentPrice'],
      stockChangeRate: (stockDetail?['changeRate'] as num?)?.toDouble(),

      voteSummary: json['voteSummary'] != null ? VoteSummary.fromJson(json['voteSummary']) : null,

      comments: json['comments'] != null
          ? (json['comments'] as List).map((c) => Comment.fromJson(c)).toList()
          : null,
    );
  }
}