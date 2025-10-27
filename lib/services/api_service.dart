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
import 'package:intl/intl.dart';

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
      onResponse: (response, handler) {
        print("✅ SUCCESS [${response.statusCode}] => PATH: ${response.requestOptions.path}");
        return handler.next(response);
      },
      onError: (DioException e, handler) async {
        print("❌ DIO ERROR");
        print("    - Path: ${e.requestOptions.path}");
        print("    - Status Code: ${e.response?.statusCode}"); // response.data 뿐만 아니라, response 전체를 출력하여 숨겨진 정보를 확인
        print("    - Response: ${e.response.toString()}");

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

      // API 명세에 맞게 DELETE 메소드로 수정
      final response = await _dio.delete(
        '/api/auth/deactivate',
        data: {'password': password}, // 비밀번호를 요청 본문에 담아 전송
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

  // WorldTimeAPI를 이용해 현재 한국 시간을 가져오는 함수
  Future<DateTime> fetchCurrentKoreanTime() async {
    try {
      // WorldTimeAPI의 서울 시간 엔드포인트
      final response = await Dio().get('http://worldtimeapi.org/api/timezone/Asia/Seoul');
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        // 'datetime' 필드의 값을 DateTime 객체로 파싱하여 반환
        return DateTime.parse(data['datetime'] as String);
      }
      throw Exception('Failed to load Korean time');
    } catch (e) {
      print('한국 시간 로드 실패: $e');
      // API 실패 시, 임시로 기기 시간을 반환하여 앱이 멈추지 않도록 함
      return DateTime.now();
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


  // 1. home : 내 종목 최신 뉴스 리스트
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

  // 2. home : 내 종목 주가 변동률 예측 TOP 5
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

  //----------------------------------------------------
  //----------------------------------------------------
  //----------------------------------------------------


  // 1. 뉴스 : 뉴스룸 메인 뉴스 조회 API (GET /api/v1/news/main)
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

  // 2. 뉴스 : 뉴스룸 필터링 조회 API (POST /api/v1/news/filter)
  Future<List<News>> fetchNewsWithFilter({
    String sort = 'LATEST',
    bool allStock = true,
    bool ownedStock = false,
    bool favoriteStock = false,
    List<String> industries = const [],
    // --- 추가된 파라미터 ---
    Map<String, dynamic>? positiveFilter,
    Map<String, dynamic>? negativeFilter,
    bool? neutralFilter,
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
          // 전달받은 맵을 사용, null이면 기본값 사용
          "positive": positiveFilter ?? {"enabled": false, "minImpact": 0.0, "maxImpact": 5.0},
          "negative": negativeFilter ?? {"enabled": false, "minImpact": 0.0, "maxImpact": 5.0},
          "neutral": neutralFilter ?? false,
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

  // 3. 뉴스 : 뉴스 개별 상세 조회 API (GET /api/v1/news/{newsId})
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

  // 4. 뉴스 본문 요약 API (GET /api/v1/news/{newsId}/summary)
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

  // 5. 뉴스 : 뉴스 스크랩 토글 API (POST /api/v1/news/{newsId}/scrap)
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

  // 6. 뉴스 : 스크랩한 모든 뉴스를 가져오는 API (GET //api/v1/member/news/scrap)
  Future<List<News>> fetchScrappedNews() async {
    try {
      final response = await _dio.get('/api/v1/member/news/scrap');

      if (response.statusCode == 200 && response.data['isSuccess']) {
        final List<dynamic> data = response.data['result'];
        if (data.isEmpty) {
          // 스크랩한 뉴스가 없으면 빈 리스트를 반환
          return [];
        }
        return data.map((json) => News.fromJson(json)).toList();
      } else {
        throw Exception('스크랩 뉴스 로딩 실패: ${response.data['message']}');
      }
    } on DioException catch (e) {
     throw Exception('스크랩 뉴스 API 호출 실패: ${e.response?.data['message'] ?? e.message}');
    } catch (e) {
      throw Exception('스크랩 뉴스를 불러오는 중 알 수 없는 오류 발생: $e');
    }
  }


  // 7. 뉴스 : 특정 종목 최신 뉴스 조회 API (GET /api/v1/news/{stockId}/latest)
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


  //----------------------------------------------------
  //----------------------------------------------------
  //----------------------------------------------------


  // 1. 주식 : 주식 종목 검색 API (GET /api/v1/stocks/search)
   Future<List<Stock>> searchStocks(String keyword) async {
    try {
      final response = await _dio.get(
          '/api/v1/stocks/search', queryParameters: {'keyword': keyword});
      if (response.statusCode == 200 && response.data['isSuccess']) {
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

  // 2. 주식 : 내 종목 조회 API (GET /api/v1/stocks/prediction)
  Future<List<Stock>> fetchMyStocks() async {
    try {
      final res = await _dio.get(
        '/api/v1/stocks/prediction',
        queryParameters: {'myStockType': 'ALL'},
      );
      print('내 종목 예측 데이터 응답: ${res.data}');

      if (res.statusCode == 200 && res.data['isSuccess']) {
        final resultList = res.data['result'] as List;

        // 각 결과 항목에 'owned'와 'favorite' 필드가 있는지 체크
        for (var item in resultList) {
          print('보유: ${item['owned']}, 관심: ${item['favorite']}');
        }

        return resultList.map((json) => Stock.fromJson(json)).toList();
      }

      throw Exception('내 주식 데이터 조회 실패: ${res.data['message']}');
    } on DioException catch (e) {
      throw Exception('내 주식 데이터 API 호출 실패: ${e.response?.data ?? e.message}');
    }
  }

  // 3. 주식 : 종목 항목 별 순위 차트 조회 API (GET /api/v1/stocks/chart)
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

  // 4. 주식 : 종목 상세 정보 조회 API (GET /api/v1/stocks/{stockId}/detail)
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

  // 5. 주식 : 기간별 종목 캔들차트 데이터 조회 API (GET /api/v1/stocks/{stockId}/candle)
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

  // 6. 주식 : 보유 종목 토글 API (POST /api/v1/stocks/{stockId}/owned)
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

  // 7. 주식 : 관심 종목 토글 API (POST /api/v1/stocks/{stockId}/favorites)
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

  // 8. 주식 : 내 종목 주가 변동률 예측 조회 API (GET /api/v1/stocks/prediction)
  // 기존 fetchPredictionTop5Stocks 함수와 동일한 기능
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

  // 9. 주식 : 사용자 보유/관심 종목 조회 API (GET /api/v1/member/stock)
  Future<List<Stock>> fetchMemberStocks({required String type}) async {
    // type: 'OWN' 또는 'FAVORITE'
    try {
      final response = await _dio.get(
        '/api/v1/member/stock',
        queryParameters: {'type': type},
      );
      if (response.statusCode == 200 && response.data['isSuccess']) {
        return (response.data['result'] as List)
            .map((json) => Stock.fromJson(json))
            .toList();
      }
      throw Exception('내 종목($type) 조회 실패: ${response.data['message']}');
    } on DioException catch (e) {
      throw Exception('내 종목($type) API 호출 실패: ${e.response?.data ?? e.message}');
    }
  }

  // 10. 주식 : 특정 시점 별 뉴스 리스트 조회 API (GET /api/v1/stocks/{stockId}/timepoint)
  Future<List<News>> fetchNewsForTimepoint({
    required int stockId,
    required String period, // DAY, WEEK, MONTH
    required DateTime date,
  }) async {
    // API는 'yyyy-MM-dd' 형식을 요구하므로 DateTime을 String으로 변환합니다.
    final String formattedDate = DateFormat('yyyy-MM-dd').format(date);

    try {
      final response = await _dio.get(
        '/api/v1/stocks/$stockId/timepoint',
        queryParameters: {
          'period': period,
          'date': formattedDate,
        },
      );

      if (response.statusCode == 200 && response.data['isSuccess']) {
       return (response.data['result'] as List)
            .map((json) => News.fromJson(json))
            .toList();
      } else {
        throw Exception('특정 시점 뉴스 조회 실패: ${response.data['message']}');
      }
    } on DioException catch (e) {
      throw Exception('특정 시점 뉴스 API 호출 실패: ${e.response?.data ?? e.message}');
    }
  }


  //----------------------------------------------------
  //----------------------------------------------------
  //----------------------------------------------------


  // 1. 라운지 : 게시글 리스트 조회 (라운지 최신, 핫, 보유 등)
  Future<List<Post>> fetchPosts({int page = 0, int size = 10, String sort = 'latest'}) async {
    try {
      final response = await _dio.get('/api/v1/post/list', queryParameters: {
        'page': page,
        'size': size,
        'sort': sort,
      });

      if (response.statusCode == 200 && response.data['isSuccess']) {
        final List<dynamic> data = response.data['result'];
        return data.map((json) => Post.fromJson(json)).toList();
      } else {
        throw Exception('게시글 목록 조회 실패: ${response.data['message']}');
      }
    } on DioException catch (e) {
      throw Exception('fetchPosts API 호출 실패: ${e.response?.data ?? e.message}');
    }
  }

  // 2. 라운지 : 내가 작성한 게시글 조회
  Future<List<Post>> fetchMyPosts() async {
    try {
      final response = await _dio.get('/api/v1/member/post/publish');

      if (response.statusCode == 200 && response.data['isSuccess']) {
        final List<dynamic> data = response.data['result'];
        return data.map((json) => Post.fromJson(json)).toList();
      } else {
        throw Exception('내가 작성한 게시글 조회 실패: ${response.data['message']}');
      }
    } on DioException catch (e) {
      throw Exception('fetchMyPosts API 호출 실패: ${e.response?.data ?? e.message}');
    }
  }

  // 3. 라운지 : 내가 댓글 단 게시글 조회
  Future<List<Post>> fetchMyCommentedPosts() async {
    try {
      final response = await _dio.get('/api/v1/member/post/comment');

      if (response.statusCode == 200 && response.data['isSuccess']) {
        final List<dynamic> data = response.data['result'];
        return data.map((json) => Post.fromJson(json)).toList();
      } else {
        throw Exception('댓글 단 게시글 조회 실패: ${response.data['message']}');
      }
    } on DioException catch (e) {
      throw Exception('fetchMyCommentedPosts API 호출 실패: ${e.response?.data ?? e.message}');
    }
  }

  // 4. 라운지 : 복수 게시글 삭제
  Future<bool> deletePosts(List<int> postIds) async {
   const String url = '/api/v1/post/post/delete';
    try {
      final response = await _dio.delete(
        url,
        data: {'postIds': postIds},
      );
      return response.statusCode == 200 && (response.data['isSuccess'] ?? false);
    } on DioException catch (e) {
      print('deletePosts API 호출 실패: $e');
      return false;
    }
  }
  // 5. 라운지 : 단일 게시글 삭제
  Future<bool> deletePost(int postId) async {
    const String url = '/api/v1/post/post/delete';
    try {
      final response = await _dio.delete(
        url,
        data: {'postIds': [postId]},
      );
      return response.statusCode == 200 && (response.data['isSuccess'] ?? false);
    } on DioException catch (e) {
      print('deletePost API 호출 실패: $e');
      return false;
    }
  }

  // 6. 라운지 : 게시글 작성
  Future<int?> createPost({
    required int newsId,
    required String title,
    required String content,
    required int stockId,
    required bool requireVote,
  }) async {
    try {
      final response = await _dio.post('/api/v1/post/write', data: {
        'newsId': newsId,
        'title': title,
        'content': content,
        'stockId': stockId.toString(),
        'requireVote': requireVote,
      });

      if (response.statusCode == 201 && response.data['isSuccess']) {
        return response.data['result']['postId'];
      } else {
        return null;
      }
    } on DioException catch (e) {
      throw Exception('createPost API 호출 실패: ${e.response?.data ?? e.message}');
    }
  }

  // 7. 라운지 : 게시글 상세 조회
  Future<Post> fetchPostDetail(int postId) async {
    try {
      final response = await _dio.get('/api/v1/post/$postId');
      if (response.statusCode == 200 && response.data['isSuccess']) {
        return Post.fromJson(response.data['result']);
      }
      throw Exception('게시글 상세 정보 조회 실패: ${response.data['message']}');
    } on DioException catch (e) {
      throw Exception('fetchPostDetail API 호출 실패: ${e.response?.data ?? e.message}');
    }
  }

  // 8. 라운지 : 댓글 작성
  Future<bool> submitComment(int postId, String content) async {
    final url = '/api/v1/post/comment/$postId';
    try {
      final response = await _dio.post(
        url,
        data: {'content': content},
      );
      return (response.statusCode == 200 || response.statusCode == 201) && (response.data['isSuccess'] ?? false);
    } on DioException catch (e) {
      print('submitComment 호출 실패: ${e.response?.data ?? e.message}');
      return false;
    }
  }

  // 9. 라운지 : 단일 댓글 삭제
  Future<bool> deleteComment(int commentId) async {
    return deleteComments([commentId]);
  }

  // 10. 라운지 : 복수 댓글 삭제
  Future<bool> deleteComments(List<int> commentIds) async {
    const String url = '/api/v1/post/comment/delete';
    if (commentIds.isEmpty) return true; // 삭제할 댓글이 없으면 성공으로 간주
    try {
      final response = await _dio.delete(
        url,
        data: {'commentIds': commentIds},
      );
      return response.statusCode == 200 && (response.data['isSuccess'] ?? false);
    } on DioException catch (e) {
      print('deleteComments API 호출 실패: ${e.response?.data ?? e.message}');
      return false;
    }
  }

  // 11. 라운지 : 투표 참여 API
  Future<bool> voteOnPoll(int postId, int voteType) async {
    try {
      final response = await _dio.post(
        '/api/v1/post/vote/$postId',
        data: {'voteType': voteType},
      );
     return (response.statusCode == 200 || response.statusCode == 201) && (response.data['isSuccess'] ?? false);
    } on DioException catch (e) {
      print('투표 참여 API 호출 실패: ${e.response?.data ?? e.message}');
      return false;
    }
  }

  // 12. 라운지 : 주식 종목 선택
  Future<Stock> fetchStockDetailsForPost(int stockId) async {
    try {
      final responseMap = await fetchStockDetail(stockId);
      return Stock.fromJson(responseMap);
    } catch (e) {
      print('fetchStockDetailsForPost 에러: $e');
      rethrow;
    }
  }


  //----------------------------------------------------
  //----------------------------------------------------
  //----------------------------------------------------


  // 1. 알림 : 알림 설정 조회 (GET /notification/setting)
  Future<Map<String, dynamic>> fetchNotificationSettings() async {
    try {
      final response = await _dio.get('/notification/setting');
      if (response.statusCode == 200 && response.data['isSuccess']) {
        return response.data['result'];
      }
      throw Exception('알림 설정 조회 실패: ${response.data['message']}');
    } on DioException catch (e) {
      throw Exception('알림 설정 API 호출 실패: ${e.response?.data ?? e.message}');
    }
  }

  // 2. 알림 : 알림 설정 수정 (PATCH /notification/setting)
  Future<bool> updateNotificationSettings({
    required bool ownStock,
    required bool interestStock,
    required bool goodNews,
    required bool badNews,
    required bool neutralNews,
    required double goodSensitivity1,
    required double goodSensitivity2,
    required double badSensitivity1,
    required double badSensitivity2,
  }) async {
    try {
      final response = await _dio.patch(
        '/notification/setting',
        data: {
          "ownStock": ownStock,
          "interestStock": interestStock,
          "goodNews": goodNews,
          "badNews": badNews,
          "neutralNews": neutralNews,
          "goodSensitivity1": goodSensitivity1,
          "goodSensitivity2": goodSensitivity2,
          "badSensitivity1": badSensitivity1,
          "badSensitivity2": badSensitivity2,
        },
      );
      return response.statusCode == 200 && (response.data['isSuccess'] ?? false);
    } on DioException catch (e) {
      print('알림 설정 수정 API 실패: ${e.response?.data ?? e.message}');
      return false;
    }
  }

  // 3. 알림 : 알림 설정 초기화 (POST /notification/setting/reset)
  Future<bool> resetNotificationSettings() async {
    try {
      final response = await _dio.post('/notification/setting/reset');
      return response.statusCode == 200 && (response.data['isSuccess'] ?? false);
    } on DioException catch (e) {
      print('알림 설정 초기화 API 실패: ${e.response?.data ?? e.message}');
      return false;
    }
  }

  // 4. 알림 : 알림 이력 조회 (GET /api/v1/notification/history)
  // type: "owned" 또는 "interest"
  Future<List<NotificationModel>> fetchNotificationHistory(String type) async {
    try {
      final response = await _dio.get(
        '/api/v1/notification/history',
        queryParameters: {'type': type},
      );
      if (response.statusCode == 200 && response.data['isSuccess']) {
        final List<dynamic> items = response.data['result']['notificationItems'];
        return items.map((json) => NotificationModel.fromJson(json)).toList();
      }
      throw Exception('알림 이력 조회 실패: ${response.data['message']}');
    } on DioException catch (e) {
      throw Exception('알림 이력 API 호출 실패: ${e.response?.data ?? e.message}');
    }
  }

  // 5. 알림 : FCM 토큰 전송 (POST /api/v1/fcm/token)
  Future<void> sendFcmToken(String fcmToken) async {
    try {
      await _dio.post(
        '/api/v1/fcm/token',
        data: {'fcmToken': fcmToken},
      );
      print('FCM 토큰 전송 성공: $fcmToken');
    } on DioException catch (e) {
      print('FCM 토큰 전송 API 실패: ${e.response?.data ?? e.message}');
    }
  }
}