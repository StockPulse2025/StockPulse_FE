import 'package:flutter/material.dart';
// PollWidget은 더 이상 필요 없으므로 import를 제거합니다.

class PostDetailNoPollScreen extends StatelessWidget {
  // isPollPost 파라미터는 더 이상 필요 없습니다.
  const PostDetailNoPollScreen({super.key});

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
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: _buildPostHeader(),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('지금 매도해야할까요?', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        SizedBox(height: 16),
                        Text('내일되면 많이 떨어질거 같아서 고민이 되네요ㅠㅠ',
                            style: TextStyle(color: Color(0xFF7C7C7C), fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // --- [삭제됨] 투표 관련 위젯 및 SizedBox 제거 ---

                  _buildDiscussionTopic(),

                  const Divider(height: 32),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Row(
                        children: [
                          const Icon(Icons.chat_bubble_outline, size: 16, color: Colors.grey),
                          const SizedBox(width: 4),
                          const Text('0', style: TextStyle(fontWeight: FontWeight.bold)),
                          // --- [삭제됨] 투표 수 관련 위젯 제거 ---
                        ]
                    ),
                  ),
                ],
              ),
            ),
          ),
          _buildCommentInput(),
        ],
      ),
    );
  }


  Widget _buildPostHeader() {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFFE8EBF2),
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Icon(Icons.person, color: Colors.white),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('플러스', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('25.08.28 | 14:40', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        )
      ],
    );
  }

  // --- [수정됨] 토론 주제 위젯 빌더 (디자인 전면 수정) ---
  Widget _buildDiscussionTopic() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('토론 TOPIC💬', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          // --- [수정됨] 남색 세로 막대를 추가하는 Row ---
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(width: 4, color: const Color(0xFF2B3A66)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    children: [
                      // 1. 뉴스 정보
                      Container(
                        padding: const EdgeInsets.all(12),
                        color: const Color(0xFFF9FAFB),
                        child: Row(
                          children: [
                            Image.asset('assets/images/news_logo/news_logo_1.jpg', width: 50, height: 50, fit: BoxFit.cover),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("한화 필리조선소 찾은 李대통령... 조선주 '들썩'", style: TextStyle(fontWeight: FontWeight.bold)),
                                  SizedBox(height: 4),
                                  Text('25.08.28 | 뉴스1', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      // 2. 주식 정보
                      Container(
                        padding: const EdgeInsets.all(12.0),
                        color: const Color(0xFFF9FAFB),
                        child: Row(
                          children: [
                            const CircleAvatar(backgroundImage: AssetImage('assets/images/stock_logo/stock_logo_3.png')),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('HD현대중공업', style: TextStyle(fontWeight: FontWeight.bold)),
                                  Row(children: [Text('500,000원'), SizedBox(width: 8), Text('+6.8%', style: TextStyle(color: Colors.red))])
                                ],
                              ),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  // --- [수정됨] 하단 댓글 입력창 위젯 ---
  Widget _buildCommentInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, -2),
          )
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: '의견을 남겨주세요.',
                // --- [수정됨] 힌트 텍스트 스타일 ---
                hintStyle: const TextStyle(fontWeight: FontWeight.bold),
                filled: true,
                fillColor: Colors.grey[200],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // --- [수정됨] 등록 버튼 스타일 ---
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2B3A66), // 남색 배경
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            child: const Text(
              '등록',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white // 흰색 글씨
              ),
            ),
          ),
        ],
      ),
    );
  }
}