import 'package:flutter/material.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class StockPriceScreen extends StatefulWidget {
  final int stockId;

  const StockPriceScreen({Key? key, required this.stockId}) : super(key: key);

  @override
  _StockPriceScreenState createState() => _StockPriceScreenState();
}

class _StockPriceScreenState extends State<StockPriceScreen> {
  StompClient? stompClient;

  // 화면에 표시할 주식 데이터들
  bool isLoading = true;
  String stockSymbol = "";
  String stockName = "";
  String imageUrl = "";
  double currentPrice = 0;
  double changeRate = 0;
  double changeAmount = 0;
  bool owned = false;
  bool favorite = false;
  Color priceColor = Colors.black;

  @override
  void initState() {
    super.initState();
    loadInitialStockData(); // REST API로 초기 데이터 로딩
  }

  // 1단계: REST API로 초기 주식 정보 가져오기
  Future<void> loadInitialStockData() async {
    try {
      final response = await http.get(
        Uri.parse('http://stockpulse.p-e.kr/api/v1/stocks/${widget.stockId}/detail'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        if (responseData['isSuccess'] == true) {
          final result = responseData['result'];

          // 초기 데이터로 화면 업데이트
          setState(() {
            stockSymbol = result['symbol'] ?? '';
            stockName = result['name'] ?? '';
            imageUrl = result['imageUrl'] ?? '';
            currentPrice = (result['currentPrice'] ?? 0).toDouble();
            changeRate = (result['changeRate'] ?? 0).toDouble();
            changeAmount = (result['changeAmount'] ?? 0).toDouble();
            owned = result['owned'] ?? false;
            favorite = result['favorite'] ?? false;
            isLoading = false;

            // 등락률에 따라 색깔 설정
            updatePriceColor();
          });

          print('📊 초기 데이터 로딩 완료: $stockName ($stockSymbol)');

          // 2️⃣ 초기 데이터 로딩 완료 후 웹소켓 연결
          connectToWebSocket();
        }
      } else {
        throw Exception('API 호출 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ 초기 데이터 로딩 오류: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  // 2단계: 웹소켓 서버에 연결 (초기 데이터 로딩 후)
  void connectToWebSocket() {
    stompClient = StompClient(
      config: StompConfig(
        url: 'ws://stockpulse.p-e.kr/ws-stock',
        onConnect: onWebSocketConnected,
        onWebSocketError: (error) => print('웹소켓 연결 오류: $error'),
        onDisconnect: (frame) => print('웹소켓 연결 해제'),
      ),
    );

    stompClient!.activate();
    print('🔄 웹소켓 연결 시도 중...');
  }

  // 3단계: 웹소켓 연결 성공 후 실시간 체결가 구독
  void onWebSocketConnected(StompFrame frame) {
    print('✅ 웹소켓 연결 성공! 실시간 체결가 구독 시작');

    // 현재 주식의 실시간 체결가 구독
    stompClient!.subscribe(
      destination: '/sub/$stockSymbol', // 예: /sub/005930
      callback: (StompFrame frame) {
        // 📨 체결가 발생 시 실행
        handleRealtimeStockData(frame.body!);
      },
    );
  }

  // 4단계: 실시간 체결가로 화면 업데이트
  void handleRealtimeStockData(String jsonData) {
    try {
      Map<String, dynamic> data = jsonDecode(jsonData);

      setState(() {
        // 실시간으로 변경되는 값들만 업데이트
        currentPrice = (data['currentPrice'] ?? currentPrice).toDouble();
        changeRate = (data['changeRate'] ?? changeRate).toDouble();
        changeAmount = (data['changeAmount'] ?? changeAmount).toDouble();

        // 색깔 업데이트
        updatePriceColor();
      });

      print('📈 실시간 체결가 업데이트: $currentPrice원 (${changeRate}%)');
    } catch (e) {
      print('❌ 실시간 데이터 처리 오류: $e');
    }
  }

  // 등락률에 따른 색깔 설정
  void updatePriceColor() {
    if (changeRate > 0) {
      priceColor = Colors.red;    // 상승: 빨간색
    } else if (changeRate < 0) {
      priceColor = Colors.blue;   // 하락: 파란색
    } else {
      priceColor = Colors.black;  // 보합: 검은색
    }
  }

  // 가격을 천 단위 콤마로 포맷팅
  String formatPrice(double price) {
    return price.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('실시간 주식 가격'),
        actions: [
          // 즐겨찾기 아이콘
          IconButton(
            icon: Icon(
              favorite ? Icons.favorite : Icons.favorite_border,
              color: favorite ? Colors.red : null,
            ),
            onPressed: () {
              // to.do 즐겨찾기 토글 API 호출
            },
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator()) // 로딩 중
          : Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 주식 이미지 (있는 경우)
            if (imageUrl.isNotEmpty)
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  image: DecorationImage(
                    image: NetworkImage(imageUrl),
                    fit: BoxFit.cover,
                  ),
                ),
              ),

            SizedBox(height: 20),

            // 종목명과 심볼
            Text(
              '$stockName ($stockSymbol)',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),

            // 보유 여부 표시
            if (owned)
              Container(
                margin: EdgeInsets.only(top: 8),
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '보유 중',
                  style: TextStyle(
                    color: Colors.green[800],
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

            SizedBox(height: 40),

            // 현재가 (실시간으로 변경됨)
            Text(
              '${formatPrice(currentPrice)}원',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: priceColor,
              ),
            ),

            SizedBox(height: 15),

            // 등락률과 등락가
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: priceColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${changeRate > 0 ? '+' : ''}${changeRate.toStringAsFixed(2)}%',
                    style: TextStyle(
                      fontSize: 16,
                      color: priceColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(width: 15),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: priceColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${changeAmount > 0 ? '+' : ''}${formatPrice(changeAmount)}원',
                    style: TextStyle(
                      fontSize: 16,
                      color: priceColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 50),

            // 상태 표시
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: stompClient?.isActive == true ? Colors.green : Colors.grey,
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(
                    stompClient?.isActive == true ? '실시간 연결됨' : '연결 대기 중',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 화면 종료 시 웹소켓 연결 해제
  @override
  void dispose() {
    stompClient?.deactivate();
    super.dispose();
  }
}
