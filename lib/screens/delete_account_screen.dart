import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'login_screen.dart';

class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  _DeleteAccountScreenState createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  final ApiService apiService = ApiService();

  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  void _onDeletePressed() async {
    final password = _passwordController.text.trim();

    if (password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('비밀번호를 입력해주세요.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    // 백엔드 API 호출 (비밀번호 확인 후 탈퇴)
    bool success = await apiService.deactivateAccount(password);
    setState(() => _isLoading = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('회원 탈퇴가 완료되었습니다.')),
      );

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('회원 탈퇴에 실패했습니다.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
            onPressed: () => Navigator.of(context).pop(),
          ),
          titleSpacing: 0,
          centerTitle: false,
          title: const Text(
              '회원탈퇴',
              style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold
              )
          ),
        ),
        body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              const Text(
              '정말로 탈퇴하시겠습니까?',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              '주가 예측 정보를 더 이상 받지 못합니다.',
              style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF585858),
                  fontWeight: FontWeight.bold
              ),
            ),
            const SizedBox(height: 48),

            const Text(
                '비밀번호',
                style: TextStyle(
                    color: Color(0xFF2B3A66),
                    fontSize: 14,
                    fontWeight: FontWeight.bold
                )
            ),
            TextField(
              obscureText: true,
              decoration: InputDecoration(
                hintText: '비밀번호를 입력해주세요',
                hintStyle: const TextStyle(fontSize: 18,color: Color(0xFFC2C2C2)),
                enabledBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF005AD5), width: 1.5),
                ),
                focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF005AD5), width: 2.0),
                ),
              ),
            ),
            const SizedBox(height: 48),

            const Text(
              '14일간 계정이 비활성화되며 14일 후에 계정이 삭제됩니다',
              style: TextStyle(
                color: Color(0xFF585858),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 5),
            const Text(
              '14일 이내 재로그인 하시면 계정이 다시 활성화됩니다',
              style: TextStyle(
                  color: Color(0xFF7C7C7C),
                  fontSize: 10,
                  fontWeight: FontWeight.bold
              ),
            ),

            const SizedBox(height: 60),

                ElevatedButton(
                  onPressed: _isLoading ? null : _onDeletePressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2B3A66),
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                    '탈퇴하기',
                    style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                )
              ],
            ),
        ),
    );
  }
}