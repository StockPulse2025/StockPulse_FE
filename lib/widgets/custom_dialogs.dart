import 'package:flutter/material.dart';

class CustomDialogs {
  // 닉네임 변경 팝업
  static void showNicknameDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text(
            '닉네임 변경',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const TextField(
            decoration: InputDecoration(hintText: "새로운 닉네임을 입력하세요"),
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
              onPressed: () => Navigator.of(context).pop(),
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
                // TODO: 닉네임 변경 로직
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // 로그아웃 팝업
  static void showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
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
              onPressed: () => Navigator.of(context).pop(),
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
                // TODO: 로그아웃 로직
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}