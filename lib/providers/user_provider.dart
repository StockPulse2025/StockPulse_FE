import 'package:flutter/material.dart';
import '../services/api_service.dart';

class UserProvider with ChangeNotifier {
  String? _nickname;
  final ApiService _apiService;

  UserProvider(this._apiService) {
    _loadInitialNickname();
  }

  String? get nickname => _nickname;

  // 초기 닉네임 로드
  Future<void> _loadInitialNickname() async {
    _nickname = await _apiService.fetchUserNickname();
    notifyListeners(); // UI에 변경 사항 알림
  }

  // 닉네임 업데이트
  Future<bool> updateNickname(String newNickname) async {
    bool success = await _apiService.updateNickname(newNickname);
    if (success) {
      _nickname = newNickname;
      notifyListeners(); // UI에 변경 사항 알림
    }
    return success;
  }

  // 로그아웃 시 닉네임 초기화
  void clearNickname() {
    _nickname = null;
    notifyListeners();
  }
}