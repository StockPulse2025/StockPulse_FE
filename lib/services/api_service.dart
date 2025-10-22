import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:stockpulse2/models/stock_model.dart';
import 'package:stockpulse2/models/news_model.dart';
import 'package:stockpulse2/models/post_model.dart';
import '../../models/notification_model.dart';
import 'package:stockpulse2/models/comment_model.dart';
import 'package:stockpulse2/models/topstock_model.dart';
import 'package:stockpulse2/models/user_model.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/news_detail_model.dart';
import 'package:http/http.dart' as https;

typedef OnAuthFailure = void Function();
class ApiService {
  final Dio _dio = Dio(BaseOptions(
      baseUrl: 'https://stockpulse.p-e.kr'
  ));

  // Singleton 패턴을 위한 static 인스턴스
  static final ApiService _instance = ApiService._internal();
  factory ApiService() {
    return _instance;
  }
  ApiService._internal() {
    _initInterceptors();
    _loadJwtTokenOnStart(); // 앱 시작 시 기존 토큰 로드
  }
  OnAuthFailure? onAuthFailure;
  void setOnAuthFailure(OnAuthFailure callback) {
    this.onAuthFailure = callback;
  }
  void _initInterceptors() {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {

        // 모든 요청 전에 최신 토큰을 헤더에 추가 (이미 있으면 유지)
        final token = await getJwtToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        } else {
          options.headers.remove('Authorization');
        }
        return handler.next(options);
      },
      onError: (DioException e, handler) async {
        if (e.response?.statusCode == 401 &&
            e.requestOptions.path != '/token/reissue') {
          print('401 Unauthorized, 토큰 재발급 시도...');
          final refreshToken = await getRefreshToken();
          if (refreshToken != null && refreshToken.isNotEmpty) {
            if (await reissueToken()) {
              e.requestOptions.headers['Authorization'] =
              'Bearer ${await getJwtToken()}';
              try {
                return handler.resolve(await _dio.fetch(e.requestOptions));
              } on DioException catch (retryError) {
                print('재시도 요청 실패: $retryError');
                await clearTokens();
                if (onAuthFailure != null) onAuthFailure!();
                return handler.next(retryError);
              }
            } else {
              print('토큰 재발급 실패: 로그인 필요');
              await clearTokens();
              if (onAuthFailure != null) onAuthFailure!();
            }
          } else {
            print('Refresh Token 없음, 재발급 시도 불가. 로그인 필요');
            await clearTokens();
            if (onAuthFailure != null) onAuthFailure!();
          }
        }
        print('API Error: ${e.response?.statusCode} - ${e.message}');
        return handler.next(e);
      },
    ));
  }
  Future<void> _loadJwtTokenOnStart() async {
    final token = await getJwtToken();
    if (token != null) {
      _dio.options.headers['Authorization'] = 'Bearer $token';
      print('ApiService initialized with existing JWT Token.');
    } else {
      _dio.options.headers.remove('Authorization');
      print('ApiService initialized without JWT Token.');
    }
  }

  // JWT 토큰 저장 (로그인 성공 시 호출)
  Future<void> saveJwtToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('jwtToken', token);
    // 로그인 성공 시 _dio 인스턴스의 헤더를 즉시 업데이트
    _dio.options.headers['Authorization'] = 'Bearer $token';
    print('JWT Token saved and Dio headers updated.');
  }

  // Refresh Token 저장
  Future<void> saveRefreshToken(String refreshToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('refreshToken', refreshToken);
    print('Refresh Token saved.');
  }

  // Refresh Token 가져오기
  Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('refreshToken');
  }

  // JWT 토큰 가져오기
  Future<String?> getJwtToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwtToken');
  }

  // 모든 토큰 삭제 (로그아웃 시 사용)
  Future<void> clearTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwtToken');
    await prefs.remove('refreshToken');
    _dio.options.headers.remove('Authorization'); // Dio 헤더에서도 제거
    print('All tokens cleared.');
  }

  // 카카오 로그인: 카카오 액세스 토큰 받아서 JWT 발급 요청
  Future<bool> kakaoLogin(String kakaoAccessToken) async {
    try {
      final response = await _dio.post(
        '/api/auth/login/kakao',
        data: {'accessToken': kakaoAccessToken},
      );
      if (response.statusCode == 200 && response.data['isSuccess']) {
        final jwtToken = response.data['result']['jwtToken'];
        final refreshToken = response.data['result']['refreshToken'];
        if (jwtToken != null) {
          await saveJwtToken(jwtToken);
          if (refreshToken != null) {
            await saveRefreshToken(refreshToken);
          }
          return true;
        }
      }
      return false;
    } on DioException catch (e) {
      print('카카오 로그인 API 예외: ${e.response?.data ?? e.message}');
      return false;
    } catch (e) {
      print('카카오 로그인 일반 예외: $e');
      return false;
    }
  }

  // 토큰 재발급
  Future<bool> reissueToken() async {
    try {
      final refreshToken = await getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        print('Refresh Token 유효하지 않음');
        return false;
      }

      final response = await _dio.post(
          '/api/token/reissue', data: {'refreshToken': refreshToken});
      if (response.statusCode == 200 && response.data['isSuccess']) {
        final accessToken = response.data['result']['accessToken'];
        final newRefreshToken = response.data['result']['refreshToken'];
        if (accessToken != null) {
          await saveJwtToken(accessToken);
          if (newRefreshToken != null) {
            await saveRefreshToken(newRefreshToken);
          }
          print('토큰 재발급 성공');
          return true;
        }
      }
      print('토큰 재발급 실패');
      return false;
    } catch (e) {
      print('토큰 재발급 에러: $e');
      return false;
    }
  }

  // 로그아웃
  Future<bool> logout() async {
    try {
      final response = await _dio.get(
          '/api/token/logout'); // Swagger 문서에 명시된 로그아웃 API
      if (response.statusCode == 200) {
        await clearTokens();
        print('로그아웃 성공');
        return true;
      }
      return false;
    } on DioException catch (e) {
      print('로그아웃 API 에러: ${e.response?.statusCode} - ${e.message}');
      await clearTokens(); // 에러 발생 시에도 토큰 정리 시도
      return false;
    } catch (e) {
      print('로그아웃 일반 에러: $e');
      await clearTokens(); // 에러 발생 시에도 토큰 정리 시도
      return false;
    }
  }

  // 회원 탈퇴
  Future<bool> deactivateAccount(String password) async {
    try {
      final token = await getJwtToken();
      if (token == null) {
        print('회원 탈퇴 시도 시 JWT 토큰 없음.');
        throw Exception('No JWT token found for deactivation');
      }

      final response = await _dio.post(
        '/api/auth/deactivate', data: {'password': password},
      );
      if (response.statusCode == 200 && response.data['isSuccess']) {
        await clearTokens(); // 회원 탈퇴 성공 시 토큰 정리
      }
      return response.statusCode == 200 && response.data['isSuccess'];
    } on DioException catch (e) {
      print('회원 탈퇴 API 오류: ${e.response?.data ?? e.message}');
      return false;
    } catch (e) {
      print('회원 탈퇴 일반 오류: $e');
      return false;
    }
  }

  // 사용자 프로필 정보 가져오기 (닉네임 포함)
  Future<String?> fetchUserNickname() async {
    try {
      final response = await _dio.get('/api/v1/member/nickname');
      if (response.statusCode == 200 && (response.data['isSuccess'] ?? false)) {
        return response.data['result'] as String?;
      }
      print('사용자 닉네임 로드 실패: ${response.data['message']}');
      return null;
    } on DioException catch (e) {
      print('사용자 닉네임 API 호출 실패: ${e.response?.data ?? e.message}');
      // 401 Unauthorized 에러는 Interceptor에서 처리하므로 여기서 특별히 다시 throw하지 않아도 됨
      return null;
    } catch (e) {
      print('사용자 닉네임 일반 예외: $e');
      return null;
    }
  }

  // 사용자 닉네임 변경
  Future<bool> updateNickname(String newNickname) async {
    try {
      final response = await _dio.patch(
        '/api/v1/member/nickname',
        data: {'nickname': newNickname},
      );
      if (response.statusCode == 200 && (response.data['isSuccess'] ?? false)) {
        print('닉네임 변경 성공: $newNickname');
        return true;
      }
      print('닉네임 변경 실패: ${response.data['message']}');
      return false;
    } on DioException catch (e) {
      print('닉네임 변경 API 호출 실패: ${e.response?.data ?? e.message}');
      return false;
    } catch (e) {
      print('닉네임 변경 일반 예외: $e');
      return false;
    }
  }


  // home : 내 종목 최신 뉴스 리스트
  Future<List<News>> fetchMyLatestNews() async {
    try {
      final res = await _dio.get('/api/v1/news/my-latest');

      print('내 종목 최신 뉴스 API 응답 데이터: ${res.data}');

      if (res.statusCode == 200 && res.data['isSuccess']) {
        return (res.data['result'] as List)
            .map((json) => News.fromJson(json))
            .toList();
      }
      throw Exception('내 종목 최신 뉴스 로딩 실패: ${res.data['message']}');
    } on DioException catch (e) {
      print('내 종목 최신 뉴스 API 호출 실패: ${e.response?.data ?? e.message}');
      if (e.response?.statusCode == 401) {
        throw Exception('Unauthorized');
      }
      throw Exception(
          '내 종목 최신 뉴스 로딩 실패: ${e.response?.data['message'] ?? e.message}');
    }
  }

  // home : 내 종목 주가 변동률 예측 TOP 5
  Future<List<Stock>> fetchPredictionTop5Stocks() async {
    try {
      final res = await _dio.get(
          '/api/v1/stocks/prediction', queryParameters: {'myStockType': 'ALL'});

      print('내 종목 주가 변동률 예측 TOP5 API 응답: ${res.data}');
      print('API 등락률 원본 데이터: ${res.data}');

      if (res.statusCode == 200 && res.data['isSuccess']) {
        return (res.data['result'] as List)
            .map((json) => Stock.fromJson(json))
            .toList();
      }
      throw Exception('내 종목 주가 변동률 예측 TOP 5 로딩 실패: ${res.data['message']}');
    } on DioException catch (e) {
      print('내 종목 주가 변동률 예측 TOP 5 API 호출 실패: ${e.response?.data ?? e.message}');
      if (e.response?.statusCode == 401) {
        throw Exception('Unauthorized');
      }
      throw Exception(
          '내 종목 주가 변동률 예측 TOP 5 로딩 실패: ${e.response?.data['message'] ??
              e.message}');
    }
  }

  // 뉴스 : 뉴스룸 필터링 조회 API (POST /api/v1/news/filter)
  Future<List<News>> fetchNewsWithFilter({
    String sort = 'LATEST',
    bool allStock = true,
    bool ownedStock = false,
    bool favoriteStock = false,
    List<String> industries = const [],
    // 참고: 민감도 필터는 FilterBottomSheet에서 값을 받아와야 합니다.
  }) async {
    try {
      final response = await _dio.post(
        '/api/v1/news/filter',
        data: {
          'sort': sort,
          'allStock': allStock,
          'ownedStock': ownedStock,
          'favoriteStock': favoriteStock,
          'industries': industries,
          // 민감도 필터 기본값 (필요 시 UI에서 받은 값으로 교체)
          "positive": {"enabled": false, "minImpact": 0, "maxImpact": 0},
          "negative": {"enabled": false, "minImpact": 0, "maxImpact": 0},
          "neutral": false
        },
      );

      if (response.statusCode == 200 && response.data['isSuccess']) {
        if (response.data['result'] is List) {
          return (response.data['result'] as List).map((json) =>
              News.fromJson(json)).toList();
        } else {
          throw Exception('API 응답 결과가 리스트 형식이 아닙니다.');
        }
      } else {
        throw Exception('뉴스 필터링 조회 실패: ${response.data['message']}');
      }
    } on DioException catch (e) {
      throw Exception('뉴스 필터링 API 호출 실패: ${e.response?.data ?? e.message}');
    }
  }

  // 뉴스 : 뉴스 스크랩 토글 API (POST /api/v1/news/{newsId}/scrap)
  Future<bool> updateBookmarkStatus(int newsId) async {
    try {
      final response = await _dio.post('/api/v1/news/$newsId/scrap');
      if (response.statusCode == 200 && (response.data['isSuccess'] ?? false)) {
        return response.data['result']['saved'] ?? false;
      }
      throw Exception('북마크 상태 변경 실패: ${response.data['message']}');
    } on DioException catch (e) {
      throw Exception('북마크 상태 변경 API 호출 실패: ${e.response?.data ?? e.message}');
    }
  }

  // 뉴스 : 뉴스룸 메인 뉴스 조회 API (GET /api/v1/news/main)
  Future<News> fetchMainNews() async {
    try {
      final response = await _dio.get('/api/v1/news/main');
      if (response.statusCode == 200 && response.data['isSuccess']) {
        return News.fromJson(response.data['result']);
      }
      throw Exception('메인 뉴스 로드 실패: ${response.data['message']}');
    } on DioException catch (e) {
      throw Exception('메인 뉴스 API 호출 실패: ${e.response?.data ?? e.message}');
    }
  }

  // 뉴스 : 뉴스 개별 상세 조회 API (GET /api/v1/news/{newsId})
  Future<NewsDetail> fetchNewsDetail(int newsId) async {
    try {
      final response = await _dio.get('/api/v1/news/$newsId');
      if (response.statusCode == 200 && response.data['isSuccess']) {
        return NewsDetail.fromJson(response.data['result']);
      }
      throw Exception('뉴스 상세 정보 로드 실패: ${response.data['message']}');
    } on DioException catch (e) {
      throw Exception('뉴스 상세 정보 API 호출 실패: ${e.response?.data ?? e.message}');
    }
  }

  // 뉴스 : 특정 종목 최신 뉴스 조회 API (GET /api/v1/news/{stockId}/latest)
  Future<List<News>> fetchLatestNewsForStock(int stockId,
      {int page = 1, int size = 10}) async {
    try {
      final response = await _dio.get(
        '/api/v1/news/$stockId/latest',
        queryParameters: {'page': page, 'size': size},
      );
      if (response.statusCode == 200 && response.data['isSuccess']) {
        if (response.data['result'] is List) {
          return (response.data['result'] as List).map((json) =>
              News.fromJson(json)).toList();
        } else {
          throw Exception('API 응답 결과가 리스트 형식이 아닙니다.');
        }
      }
      throw Exception('특정 종목 뉴스 로드 실패: ${response.data['message']}');
    } on DioException catch (e) {
      throw Exception('특정 종목 뉴스 API 호출 실패: ${e.response?.data ?? e.message}');
    }
  }

  // 7. 뉴스 본문 요약 API (GET /api/v1/news/{newsId}/summary)
  // 뉴스 상세 화면에서 '뉴스 요약' 버튼 클릭 시 호출됩니다.
  Future<String> fetchNewsSummary(int newsId) async {
    try {
      final response = await _dio.get('/api/v1/news/$newsId/summary');
      if (response.statusCode == 200 && response.data['isSuccess']) {
        return response.data['result']['content'] ?? '요약 정보가 없습니다.';
      }
      throw Exception('뉴스 요약 로드 실패: ${response.data['message']}');
    } on DioException catch (e) {
      throw Exception('뉴스 요약 API 호출 실패: ${e.response?.data ?? e.message}');
    }
  }


  // 게시글 리스트 조회 (라운지 최신, 핫, 보유 등 공통으로 사용 가능)
  Future<List<Post>> fetchPosts(
      {int page = 1, int size = 20, String? sort}) async {
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
        throw Exception('게시글 리스트 로드 실패: ${response.data['message']}');
      }
    } on DioException catch (e) {
      throw Exception('fetchPosts API 호출 실패: ${e.response?.data ?? e.message}');
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
        throw Exception('내 게시글 로드 실패: ${response.data['message']}');
      }
    } on DioException catch (e) {
      throw Exception(
          'fetchMyPosts API 호출 실패: ${e.response?.data ?? e.message}');
    }
  }

  // 댓글 단 게시글 조회
  Future<List<Post>> fetchMyCommentedPosts(
      {int page = 1, int size = 20}) async {
    try {
      final response = await _dio.get(
          '/apiv1/post/mycommentedposts', queryParameters: {
        'page': page,
        'size': size,
      });

      if (response.statusCode == 200 && response.data['isSuccess']) {
        final List<dynamic> data = response.data['result'];
        return data.map((json) => Post.fromJson(json)).toList();
      } else {
        throw Exception('댓글 단 게시글 로드 실패: ${response.data['message']}');
      }
    } on DioException catch (e) {
      throw Exception(
          'fetchMyCommentedPosts API 호출 실패: ${e.response?.data ?? e.message}');
    }
  }

  // 게시글 삭제
  Future<bool> deletePosts(List<int> postIds) async {
    try {
      final response = await _dio.post('/apiv1/post/delete', data: {
        'postIds': postIds,
      });

      return response.statusCode == 200 && response.data['isSuccess'] == true;
    } on DioException catch (e) {
      throw Exception(
          'deletePosts API 호출 실패: ${e.response?.data ?? e.message}');
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
    try {
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
    } on DioException catch (e) {
      throw Exception('createPost API 호출 실패: ${e.response?.data ?? e.message}');
    }
  }

  Future<Post> fetchPostDetail(int postId) async {
    try {
      final response = await _dio.get('/apiv1/post/$postId');
      if (response.statusCode == 200 && response.data['isSuccess']) {
        return Post.fromJson(response.data['result']);
      }
      throw Exception('게시글 상세 로드 실패: ${response.data['message']}');
    } on DioException catch (e) {
      throw Exception(
          'fetchPostDetail API 호출 실패: ${e.response?.data ?? e.message}');
    }
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
        throw Exception('댓글 리스트 조회 실패: ${response.data['message']}');
      }
    } on DioException catch (e) {
      throw Exception('fetchComments 호출 실패: ${e.response?.data ?? e.message}');
    }
  }

  // 댓글 작성
  Future<bool> submitComment(int postId, String content) async {
    try {
      final response = await _dio.post('/apiv1/post/$postId/comment', data: {
        'content': content,
      });
      return response.statusCode == 200 && response.data['isSuccess'] == true;
    } on DioException catch (e) {
      throw Exception('submitComment 호출 실패: ${e.response?.data ?? e.message}');
    }
  }

  // 댓글 삭제
  Future<bool> deleteComment(int commentId) async {
    try {
      final response = await _dio.post(
          '/apiv1/comment/delete', data: {'commentId': commentId});
      return response.statusCode == 200 && response.data['isSuccess'] == true;
    } on DioException catch (e) {
      throw Exception('댓글 삭제 실패: ${e.response?.data ?? e.message}');
    }
  }

// 댓글 수정
  Future<bool> editComment(int commentId, String newContent) async {
    try {
      final response = await _dio.post('/apiv1/comment/edit',
          data: {'commentId': commentId, 'content': newContent});
      return response.statusCode == 200 && response.data['isSuccess'] == true;
    } on DioException catch (e) {
      throw Exception('댓글 수정 실패: ${e.response?.data ?? e.message}');
    }
  }

  // 1. [수정] 주식 종목 검색 API (GET /api/v1/stocks/search)
  // - 파라미터 이름을 'q'에서 'keyword'로 수정했습니다.
  Future<List<Stock>> searchStocks(String keyword) async {
    try {
      // API 명세에 따라 엔드포인트와 파라미터 수정
      final response = await _dio.get(
          '/api/v1/stocks/search', queryParameters: {'keyword': keyword});
      if (response.statusCode == 200 && response.data['isSuccess']) {
        // 검색 결과 DTO는 필드가 적으므로, Stock.fromJson으로 처리하되 없는 필드는 기본값으로 채워집니다.
        return (response.data['result'] as List)
            .map((json) => Stock.fromJson(json))
            .toList();
      } else {
        throw Exception('종목 검색 실패: ${response.data['message']}');
      }
    } on DioException catch (e) {
      throw Exception('종목 검색 API 호출 실패: ${e.response?.data ?? e.message}');
    }
  }

  // 2. [수정] 내 종목 조회 API (GET /api/v1/stocks/mine)
  // - 기존 fetchMyStocks 함수를 유지하되, Swagger에 명시된 prediction API와 구분합니다.
  // - Swagger에는 '내 주식' 목록을 직접 가져오는 API가 명시되지 않아, 기존 코드를 유지합니다.
  //   만약 이 기능이 prediction API로 대체되어야 한다면 fetchPredictionStocks(myStockType: 'ALL')을 사용해야 합니다.
  Future<List<Stock>> fetchMyStocks() async {
    try {
      final response = await _dio.get('/api/v1/stocks/mine');
      if (response.statusCode == 200 && response.data['isSuccess']) {
        return (response.data['result'] as List).map((json) =>
            Stock.fromJson(json)).toList();
      }
      throw Exception('내 주식 데이터 조회 실패: ${response.data['message']}');
    } on DioException catch (e) {
      throw Exception('내 주식 데이터 API 호출 실패: ${e.response?.data ?? e.message}');
    }
  }

  // 3. [수정] 종목 항목 별 순위 차트 조회 API (GET /api/v1/stocks/chart)
  // - 기존 fetchAllStocks를 대체합니다. 탭 별 정렬 기능을 지원합니다.
  Future<List<Stock>> fetchStockRanking({
    required String type,
  }) async {
    try {
      final response = await _dio.get('/api/v1/stocks/chart', queryParameters: {'type': type});

      print('✅ [fetchStockRanking] API 응답 데이터 확인: ${response.data}');

      if (response.statusCode == 200 && response.data['isSuccess']) {
        return (response.data['result'] as List).map((json) => Stock.fromJson(json)).toList();
      }
      throw Exception('종목 순위 차트 조회 실패: ${response.data['message']}');
    } on DioException catch (e) {
      throw Exception('종목 순위 차트 API 호출 실패: ${e.response?.data ?? e.message}');
    }
  }

  // 4. [추가] 종목 상세 정보 조회 API (GET /api/v1/stocks/{stockId}/detail)
  // - stock_detail_screen에서 사용합니다.
  Future<Map<String, dynamic>> fetchStockDetail(int stockId) async {
    try {
      final response = await _dio.get('/api/v1/stocks/$stockId/detail');
      if (response.statusCode == 200 && response.data['isSuccess']) {
        return response.data['result'];
      }
      throw Exception('주식 상세 정보 로드 실패: ${response.data['message']}');
    } on DioException catch (e) {
      throw Exception('주식 상세 정보 API 호출 실패: ${e.response?.data ?? e.message}');
    }
  }

  // 5. [추가] 기간별 종목 캔들차트 데이터 조회 API (GET /api/v1/stocks/{stockId}/candle)
  Future<List<Map<String, dynamic>>> fetchCandleData({
    required int stockId,
    required String period, // DAY, WEEK, MONTH
  }) async {
    try {
      final response = await _dio.get('/api/v1/stocks/$stockId/candle',
          queryParameters: {'period': period});
      if (response.statusCode == 200 && response.data['isSuccess']) {
        // API 응답 구조에 맞게 stockCandleDataList를 반환
        return List<Map<String, dynamic>>.from(
            response.data['result']['stockCandleDataList']);
      }
      throw Exception('캔들차트 데이터 로드 실패: ${response.data['message']}');
    } on DioException catch (e) {
      throw Exception('캔들차트 데이터 API 호출 실패: ${e.response?.data ?? e.message}');
    }
  }

  // 6. [추가] 보유 종목 토글 API (POST /api/v1/stocks/{stockId}/owned)
  Future<bool> toggleOwnedStock(int stockId) async {
    try {
      final response = await _dio.post('/api/v1/stocks/$stockId/owned');
      if (response.statusCode == 200 && response.data['isSuccess']) {
        return response.data['result']['owned']; // 토글 후 상태 (true/false) 반환
      }
      throw Exception('보유 종목 토글 실패: ${response.data['message']}');
    } on DioException catch (e) {
      throw Exception('보유 종목 토글 API 호출 실패: ${e.response?.data ?? e.message}');
    }
  }

  // 7. [추가] 관심 종목 토글 API (POST /api/v1/stocks/{stockId}/favorites)
  Future<bool> toggleFavoriteStock(int stockId) async {
    try {
      final response = await _dio.post('/api/v1/stocks/$stockId/favorites');
      if (response.statusCode == 200 && response.data['isSuccess']) {
        return response.data['result']['favorite']; // 토글 후 상태 (true/false) 반환
      }
      throw Exception('관심 종목 토글 실패: ${response.data['message']}');
    } on DioException catch (e) {
      throw Exception('관심 종목 토글 API 호출 실패: ${e.response?.data ?? e.message}');
    }
  }

  // 8. [유지/확인] 내 종목 주가 변동률 예측 조회 API (GET /api/v1/stocks/prediction)
  // 기존 fetchPredictionTop5Stocks 함수와 동일한 기능을 하므로 이름을 명확하게 변경하거나 유지할 수 있습니다.
  Future<List<Stock>> fetchPredictionStocks(
      {required String myStockType}) async {
    // ALL, OWN, FAVORITE
    try {
      final res = await _dio.get('/api/v1/stocks/prediction',
          queryParameters: {'myStockType': myStockType});
      if (res.statusCode == 200 && res.data['isSuccess']) {
        return (res.data['result'] as List)
            .map((json) => Stock.fromJson(json))
            .toList();
      }
      throw Exception('내 종목 주가 변동률 예측 로딩 실패: ${res.data['message']}');
    } on DioException catch (e) {
      throw Exception(
          '내 종목 주가 변동률 예측 API 호출 실패: ${e.response?.data ?? e.message}');
    }
  }
}