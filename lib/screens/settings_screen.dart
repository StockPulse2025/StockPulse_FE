import 'package:flutter/material.dart';
import 'delete_account_screen.dart';
import '../widgets/custom_dialogs.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

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
            '설정',
            style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold
            )
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 28.0),
        children: [
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.only(left: 1.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Image.asset(
                  'assets/images/setting_person_icon.png',
                  width: 80,
                  height: 80,
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('닉네임', style: TextStyle(fontSize: 16,
                        fontWeight: FontWeight.bold, color: Color(0xFF585858))),
                    const SizedBox(height: 4),
                    GestureDetector(
                      onTap: () => CustomDialogs.showNicknameDialog(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFF7C7C7C)),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Text(
                                '플러스',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold
                                )
                            ),
                            SizedBox(width: 5),
                            Icon(Icons.edit, size: 20, color: Color(0xFF7C7C7C)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          _buildSectionTitle('계정 관리'),
          _buildMenuTile(
            title: '로그아웃',
            onTap: () => CustomDialogs.showLogoutDialog(context),
            color: const Color(0xFF585858),
          ),
          _buildMenuTile(
            title: '회원 탈퇴',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const DeleteAccountScreen()),
              );
            },
            color: const Color(0xFF585858),
          ),
          const SizedBox(height: 24),

          _buildSectionTitle('정보 및 지원'),
          _buildInfoTile('공지사항', color: const Color(0xFF585858)),
          _buildInfoTile('이용약관', color: const Color(0xFF585858)),
          _buildInfoTile('버전', trailing: '1.0', color: const Color(0xFF585858)),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
              title,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold
              )
          ),
        ),
        const Divider(
          thickness: 2,
            color: Color(0xFFD3D7E0),
        ),
      ],
    );
  }

  Widget _buildMenuTile({required String title, required VoidCallback onTap, Color? color}) {
    return ListTile(
      title: Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: color,
          )
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildInfoTile(String title, {String? trailing, Color? color}) {
    return ListTile(
      title: Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: color,
          )
      ),
      trailing: trailing != null ? Text(trailing, style: const TextStyle(color: Colors.grey, fontSize: 16)) : null,
      contentPadding: EdgeInsets.zero,
    );
  }
}