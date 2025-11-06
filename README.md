# StockPulse - Flutter Mobile App

---

## 개요

StockPulse는 Flutter로 개발된 뉴스 분석 및 주식 정보 제공 모바일 앱입니다.
사용자는 실시간 주가 확인, 관심 종목 관리, 최신 뉴스 열람, 커뮤니티 소통, 알림 설정 등 다양한 기능을 이용할 수 있습니다.

---

## 주요 기능

- 실시간 주가 데이터 스트리밍 및 보유/즐겨찾기 종목 관리  
- 최신 주식 뉴스 및 즐겨찾기 뉴스 확인  
- 종목별 상세 차트와 타임라인 뉴스 제공  
- 사용자 맞춤 알림 설정 및 알림 센터 관리  
- 커뮤니티 라운지에서 게시글 작성 및 투표 참여  
- 카카오톡 소셜 로그인 연동  
- 프로필 및 계정 관리 기능

---

## 스크린샷

 

---

## 기술 스택

- Flutter (Dart)  
- REST API (Dio)  
- WebSocket (STOMP 프로토콜)  
- Firebase (초기화 및 푸시 알림)  
- Provider (상태관리)  
- Kakao OAuth  

---

## 설치 및 실행

1. Flutter SDK 설치: https://flutter.dev  
2. 프로젝트 클론  
git clone https://github.com/yourusername/stockpulse-frontend.git
cd stockpulse-frontend

3. 의존성 패키지 설치  
flutter pub get

4. Android/iOS 실행  
flutter run

5. Firebase 설정  
- `android/app/google-services.json` 및 `ios/Runner/GoogleService-Info.plist` 파일 위치 확인  
- Firebase 설정 완료 필요

---

## 프로젝트 구조

lib/
├── models/ # 데이터 모델 정의
├── screens/ # 주요 화면 위젯
├── services/ # API 및 WebSocket 서비스
├── providers/ # 상태 관리 프로바이더
├── widgets/ # 재사용 위젯 컴포넌트
└── main.dart # 앱 진입점 및 라우팅

