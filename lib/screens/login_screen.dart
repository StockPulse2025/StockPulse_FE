import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'home_screen.dart';
import '../services/api_service.dart';


const String KAKAO_REST_API_KEY = 'eb7d102a8853d1697ad5723dd0803d8b';
const String KAKAO_REDIRECT_URI = 'http://10.0.2.2:3000/auth/kakao/callback';
const String BASE_API_URL = 'https://stockpulse.p-e.kr';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2B3A66),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(height: 20),
              Transform.translate(
                offset: const Offset(0, -70),
                child: Image.asset(
                  'assets/images/stockpulse_logo.png',
                  width: 300,
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  final bool? loginSuccess = await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => KakaoLoginWebView(key: UniqueKey()),
                    ),
                  );

                  if (loginSuccess == true) {
                    print('카카오 로그인 및 토큰 저장 성공. HomeScreen으로 이동.');
                    if (mounted) {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const HomeScreen()),
                      );
                    }
                  } else if (loginSuccess == false) {
                    print('카카오 로그인 실패 또는 취소됨.');
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('카카오 로그인 실패 또는 취소')),
                      );
                    }
                  } else {
                    print('카카오 로그인 중 알 수 없는 오류 발생: $loginSuccess');
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('카카오 로그인 중 오류 발생: $loginSuccess')),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFE500),
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  '카카오로 로그인하기',
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class KakaoLoginWebView extends StatefulWidget {
  const KakaoLoginWebView({super.key});

  @override
  State<KakaoLoginWebView> createState() => _KakaoLoginWebViewState();
}

class _KakaoLoginWebViewState extends State<KakaoLoginWebView> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();

    final String kakaoAuthUrl =
        'https://kauth.kakao.com/oauth/authorize?response_type=code&client_id=$KAKAO_REST_API_KEY&redirect_uri=$KAKAO_REDIRECT_URI&state=secure_state_key';

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            print('WebView progress: $progress%');
          },
          onPageStarted: (String url) {
            print('Page started loading: $url');
          },
          onNavigationRequest: (NavigationRequest request) async {
            print('onNavigationRequest: ${request.url}');
            if (request.url.startsWith(KAKAO_REDIRECT_URI)) {
              final uri = Uri.parse(request.url);
              final code = uri.queryParameters['code'];
              print('Redirect URL 감지됨: ${request.url}');
              print('추출된 인가 코드: $code');

              if (code != null) {
                final bool success = await _requestJwtTokenAndSave(code);
                if (mounted) {
                  Navigator.of(context).pop(success);
                }
              } else {
                print('인가 코드 없음');
                if (mounted) Navigator.of(context).pop(false);
              }
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
          onWebResourceError: (WebResourceError error) {
            print('WebView Error: ${error.description}');
            if (mounted) Navigator.of(context).pop('WebView Error: ${error.description}');
          },
        ),
      )
      ..loadRequest(Uri.parse(kakaoAuthUrl));
  }

  Future<bool> _requestJwtTokenAndSave(String code) async {
    try {
      final uri = Uri.parse('$BASE_API_URL/api/auth/kakao')
          .replace(queryParameters: {'code': code});
      print('서버에 JWT 토큰 요청: $uri');

      final response = await http.post(uri,
          headers: {'Content-Type': 'application/json'});

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['isSuccess'] == true && data['code'] == 'AUTH2001') {
          final accessToken = data['result']['accessToken'];
          final refreshToken = data['result']['refreshToken'];

          if (accessToken != null && refreshToken != null) {
            // 키를 'jwtToken'으로 통일
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('jwtToken', accessToken);
            await prefs.setString('refreshToken', refreshToken);
            print('JWT Token 저장됨 (WebView 내부): $accessToken');
            print('Refresh Token 저장됨 (WebView 내부): $refreshToken');

            // ApiService 메서드 호출로 헤더 즉시 반영
            final apiService = ApiService();
            await apiService.saveJwtToken(accessToken);
            await apiService.saveRefreshToken(refreshToken);

            return true;
          }
        }
      }
      print('JWT 토큰 요청 실패: ${response.body}');
      return false;
    } catch (e) {
      print('JWT 토큰 저장 오류: $e');
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("카카오 로그인"),
        backgroundColor: const Color(0xFF2B3A66),
        foregroundColor: Colors.white,
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}
