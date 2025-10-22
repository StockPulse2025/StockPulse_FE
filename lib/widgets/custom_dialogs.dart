import 'package:flutter/material.dart';

class CustomDialogs {
  // 닉네임 변경 팝업
  static Future<String?> showNicknameDialog(
      BuildContext context, {
        required String currentNickname,
        required Future<bool> Function(String) onUpdate, // 닉네임 업데이트 콜백
      }) async {
    TextEditingController nicknameController = TextEditingController(text: currentNickname);
    String? newNickname;

    await showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('닉네임 변경'),
          content: TextField(
            controller: nicknameController,
            decoration: const InputDecoration(
              hintText: '새로운 닉네임을 입력하세요',
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('취소'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              child: const Text('변경'),
              onPressed: () async {
                final inputNickname = nicknameController.text.trim();
                if (inputNickname.isNotEmpty && inputNickname != currentNickname) {
                  bool success = await onUpdate(inputNickname);
                  if (success) {
                    newNickname = inputNickname; // 성공 시에만 새 닉네임 저장
                    Navigator.of(dialogContext).pop(newNickname); // 다이얼로그 닫기
                  }
                  // 실패 시 onUpdate 내부에서 스낵바 표시하고 다이얼로그는 닫지 않음
                } else {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(content: Text('닉네임을 입력하거나 현재 닉네임과 다른 닉네임을 입력해주세요.')),
                  );
                }
              },
            ),
          ],
        );
      },
    );
    return newNickname;
  }

  // 로그아웃 팝업
  // 로그아웃 팝업
  static void showLogoutDialog(BuildContext context, {required VoidCallback onConfirm}) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) { // buildContext를 dialogContext로 변경하여 혼동 방지
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text(
            '로그아웃',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const Text(
            '정말로 로그아웃 하시겠습니까?',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text(
                '취소',
                style: TextStyle(
                  color: Color(0xFF2B3A66),
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            TextButton(
              child: const Text(
                '확인',
                style: TextStyle(
                  color: Color(0xFF2B3A66),
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop(); // 다이얼로그 닫기
                onConfirm(); // 전달받은 콜백 함수 실행
              },
            ),
          ],
        );
      },
    );
  }
}