import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:stockpulse2/models/stock_model.dart';
import 'package:stockpulse2/models/news_model.dart';
import 'package:stockpulse2/models/post_model.dart';
import '../../models/notification_model.dart';
import 'package:stockpulse2/models/comment_model.dart';
import 'package:stockpulse2/models/topstock_model.dart';

class ApiService {
  final Dio _dio = Dio(BaseOptions(
      baseUrl: 'https://stockpulse.p-e.kr'
  ));

  // 홈 뉴스 리스트
  Future<List<News>> fetchHomeNews() async {
    final res = await _dio.get('/apiv1/news/main');
    if (res.statusCode == 200 && res.data['isSuccess']) {
      return (res.data['result'] as List)
          .map((json) => News.fromJson(json))
          .toList();
    }
    throw Exception('뉴스 로딩 실패');
  }

  // Top 5 종목
  Future<List<Stock>> fetchTop5Stocks() async {
    final res = await _dio.get('/apiv1/stocks/top5');
    if (res.statusCode == 200 && res.data['isSuccess']) {
      return (res.data['result'] as List)
          .map((json) => Stock.fromJson(json))
          .toList();
    }
    throw Exception('Top5 주식 로딩 실패');
  }

  // 뉴스탭 리스트
  Future<List<News>> fetchNewsList() async {
    final response = await _dio.get('/apiv1/news/main');
    if (response.statusCode == 200 && response.data['isSuccess']) {
      final List<dynamic> data = response.data['result'];
      return data.map((json) => News.fromJson(json)).toList();
    } else {
      throw Exception('뉴스 리스트 로드 실패');
    }
  }

  Future<List<News>> fetchNewsByPage(int page) async {
    final response = await _dio.get('/apiv1/news/main', queryParameters: {'page': page});
    if (response.statusCode == 200 && response.data['isSuccess']) {
      return (response.data['result'] as List).map((json) => News.fromJson(json)).toList();
    } else {
      throw Exception('뉴스 로드 실패');
    }
  }

  // 북마크 상태 변경
  Future<void> updateBookmarkStatus(int newsId, bool isBookmarked) async {
    final response = await _dio.post('/apiv1/news/bookmark', data: {
      'newsId': newsId,
      'isBookmarked': isBookmarked,
    });
    if (response.statusCode != 200 || !(response.data['isSuccess'] ?? false)) {
      throw Exception('북마크 상태 변경 실패');
    }
  }

  Future<List<News>> fetchBookmarkedNewsList() async {
    final response = await _dio.get('/apiv1/news/bookmarked');
    if (response.statusCode == 200 && response.data['isSuccess']) {
      return (response.data['result'] as List)
          .map((json) => News.fromJson(json))
          .toList();
    } else {
      throw Exception('북마크된 뉴스 불러오기 실패');
    }
  }

  // TOP 종목 불러오기
  Future<List<TopStock>> fetchTopStocks(int newsId) async {
    final response = await _dio.get('/apiv1/news/$newsId/top-stocks');
    if (response.statusCode == 200 && response.data['isSuccess']) {
      return (response.data['result'] as List)
          .map((json) => TopStock.fromJson(json))
          .toList();
    } else {
      throw Exception('TOP 종목 정보 불러오기 실패');
    }
  }

  Future<void> saveFilterSettings({
    required String sortOrder,
    required String stockFilter,
    required List<String> selectedIndustries,
    required bool neutral,
    required bool good,
    required RangeValues goodRange,
    required bool bad,
    required RangeValues badRange,
  }) async {
    final response = await _dio.post('/apiv1/news/filter', data: {
      'sortOrder': sortOrder,
      'stockFilter': stockFilter,
      'industries': selectedIndustries,
      'neutral': neutral,
      'good': good,
      'goodRange': [goodRange.start, goodRange.end],
      'bad': bad,
      'badRange': [badRange.start, badRange.end]
    });
    if (response.statusCode != 200 || !(response.data['isSuccess'] ?? false)) {
      throw Exception('필터 설정 저장 실패');
    }
  }

  // 게시글 리스트 조회 (라운지 최신, 핫, 보유 등 공통으로 사용 가능)
  Future<List<Post>> fetchPosts({int page = 1, int size = 20, String? sort}) async {
    try {
      final response = await _dio.get('/apiv1/postlist', queryParameters: {
        'page': page,
        'size': size,
        if (sort != null) 'sort': sort,
      });

      if (response.statusCode == 200 && response.data['isSuccess']) {
        final List<dynamic> data = response.data['result'];
        return data.map((json) => Post.fromJson(json)).toList();
      } else {
        throw Exception('게시글 리스트 로드 실패');
      }
    } catch (e) {
      throw Exception('fetchPosts API 호출 실패: $e');
    }
  }

  // 내 게시글 조회
  Future<List<Post>> fetchMyPosts({int page = 1, int size = 20}) async {
    try {
      final response = await _dio.get('/apiv1/post/myposts', queryParameters: {
        'page': page,
        'size': size,
      });

      if (response.statusCode == 200 && response.data['isSuccess']) {
        final List<dynamic> data = response.data['result'];
        return data.map((json) => Post.fromJson(json)).toList();
      } else {
        throw Exception('내 게시글 로드 실패');
      }
    } catch (e) {
      throw Exception('fetchMyPosts API 호출 실패: $e');
    }
  }

  // 댓글 단 게시글 조회
  Future<List<Post>> fetchMyCommentedPosts({int page = 1, int size = 20}) async {
    try {
      final response = await _dio.get('/apiv1/post/mycommentedposts', queryParameters: {
        'page': page,
        'size': size,
      });

      if (response.statusCode == 200 && response.data['isSuccess']) {
        final List<dynamic> data = response.data['result'];
        return data.map((json) => Post.fromJson(json)).toList();
      } else {
        throw Exception('댓글 단 게시글 로드 실패');
      }
    } catch (e) {
      throw Exception('fetchMyCommentedPosts API 호출 실패: $e');
    }
  }

  // 게시글 삭제
  Future<bool> deletePosts(List<int> postIds) async {
    try {
      final response = await _dio.post('/apiv1/post/delete', data: {
        'postIds': postIds,
      });

      return response.statusCode == 200 && response.data['isSuccess'] == true;
    } catch (e) {
      throw Exception('deletePosts API 호출 실패: $e');
    }
  }

  // 게시글 작성
  Future<int?> createPost({
    required int newsId,
    required String title,
    required String content,
    required int stockId,
    required bool requireVote,
  }) async {
    final response = await _dio.post('/apiv1/postwrite', data: {
      'newsId': newsId,
      'title': title,
      'content': content,
      'stockId': stockId,
      'requireVote': requireVote,
    });

    if (response.statusCode == 200 && response.data['isSuccess']) {
      return response.data['result']['postId'];
    } else {
      return null;
    }
  }

  Future<Post> fetchPostDetail(int postId) async {
    final response = await _dio.get('/apiv1/post/$postId');
    if (response.statusCode == 200 && response.data['isSuccess']) {
      return Post.fromJson(response.data['result']);
    }
    throw Exception('게시글 상세 로드 실패');
  }

  // 댓글 리스트 조회
  Future<List<Comment>> fetchComments(int postId) async {
    try {
      final response = await _dio.get('/apiv1/post/$postId/comments');
      if (response.statusCode == 200 && response.data['isSuccess']) {
        return (response.data['result'] as List)
            .map((json) => Comment.fromJson(json))
            .toList();
      } else {
        throw Exception('댓글 리스트 조회 실패');
      }
    } catch (e) {
      throw Exception('fetchComments 호출 실패: $e');
    }
  }

  // 댓글 작성
  Future<bool> submitComment(int postId, String content) async {
    try {
      final response = await _dio.post('/apiv1/post/$postId/comment', data: {
        'content': content,
      });
      return response.statusCode == 200 && response.data['isSuccess'] == true;
    } catch (e) {
      throw Exception('submitComment 호출 실패: $e');
    }
  }
  // 댓글 삭제
  Future<bool> deleteComment(int commentId) async {
    try {
      final response = await _dio.post('/apiv1/comment/delete', data: {'commentId': commentId});
      return response.statusCode == 200 && response.data['isSuccess'] == true;
    } catch (e) {
      throw Exception('댓글 삭제 실패: $e');
    }
  }

// 댓글 수정
  Future<bool> editComment(int commentId, String newContent) async {
    try {
      final response = await _dio.post('/apiv1/comment/edit', data: {'commentId': commentId, 'content': newContent});
      return response.statusCode == 200 && response.data['isSuccess'] == true;
    } catch (e) {
      throw Exception('댓글 수정 실패: $e');
    }
  }

  Future<List<NotificationModel>> fetchHoldingsNotifications() async {
    final res = await _dio.get('/apiv1/notifications/holdings');
    if (res.statusCode == 200 && res.data['isSuccess']) {
      return (res.data['result'] as List).map((json) => NotificationModel.fromJson(json)).toList();
    }
    throw Exception('보유종목 알림 불러오기 실패');
  }

  Future<List<NotificationModel>> fetchWatchlistNotifications() async {
    final res = await _dio.get('/apiv1/notifications/watchlist');
    if (res.statusCode == 200 && res.data['isSuccess']) {
      return (res.data['result'] as List).map((json) => NotificationModel.fromJson(json)).toList();
    }
    throw Exception('관심종목 알림 불러오기 실패');
  }

  Future<List<Stock>> searchStocks(String keyword) async {
    final response = await _dio.get('/api/stocks/search', queryParameters: {'q': keyword});
    if (response.statusCode == 200 && response.data['isSuccess']) {
      return (response.data['result'] as List)
          .map((json) => Stock.fromJson(json))
          .toList();
    } else {
      throw Exception('종목 검색 실패');
    }
  }

  Future<List<Stock>> fetchAllStocks(int page) async {
    final response = await _dio.get('/api/v1/stocks', queryParameters: {'page': page});
    if (response.statusCode == 200 && response.data['isSuccess']) {
      return (response.data['result'] as List).map((json) => Stock.fromJson(json)).toList();
    }
    throw Exception('전체 주식 데이터 조회 실패');
  }

  Future<List<Stock>> fetchMyStocks() async {
    final response = await _dio.get('/api/v1/stocks/mine');
    if (response.statusCode == 200 && response.data['isSuccess']) {
      return (response.data['result'] as List).map((json) => Stock.fromJson(json)).toList();
    }
    throw Exception('내 주식 데이터 조회 실패');
  }

  Future<List<Stock>> fetchHoldings() async {
    final response = await _dio.get('/api/holdings');
    if (response.statusCode == 200 && response.data['isSuccess']) {
      return (response.data['result'] as List)
          .map((e) => Stock.fromJson(e))
          .toList();
    }
    throw Exception('보유 종목 조회 실패');
  }

  Future<List<Stock>> fetchWatchlist() async {
    final response = await _dio.get('/api/watchlist');
    if (response.statusCode == 200 && response.data['isSuccess']) {
      return (response.data['result'] as List)
          .map((e) => Stock.fromJson(e))
          .toList();
    }
    throw Exception('관심 종목 조회 실패');
  }

}