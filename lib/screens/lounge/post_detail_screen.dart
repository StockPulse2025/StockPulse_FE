import 'package:flutter/material.dart';
import '../../widgets/lounge/poll_widget.dart';

class PostDetailScreen extends StatelessWidget {
  final bool isPollPost;
  const PostDetailScreen({super.key, required this.isPollPost});

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
                        Text('조선주 슬슬 반등 시작하나요?', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        SizedBox(height: 16),
                        Text('차익매물 다 털고 다시 올라갈 준비 하는 것 같긴한데 지금 빨리 매수해야할까요? 다른 분들 의견이 궁금합니다.',
                            style: TextStyle(color: Color(0xFF7C7C7C), fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (isPollPost) const PollWidget(),
                  if (isPollPost) const SizedBox(height: 24),

                  _buildDiscussionTopic(),

                  const Divider(height: 32),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Row(
                        children: [
                          const Icon(Icons.chat_bubble_outline, size: 16, color: Colors.grey),
                          const SizedBox(width: 4),
                          const Text('33', style: TextStyle(fontWeight: FontWeight.bold)),
                          if (isPollPost) const SizedBox(width: 12),
                          if (isPollPost) const Icon(Icons.poll_outlined, size: 16, color: Colors.grey),
                          if (isPollPost) const SizedBox(width: 4),
                          if (isPollPost) const Text('78', style: TextStyle(fontWeight: FontWeight.bold)),
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
            Text('KIM', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('25.07.08 | 18:40', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
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
                            Image.asset('assets/images/news_logo/news_logo_9.jpg', width: 50, height: 50, fit: BoxFit.cover),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("차익매물 털고 조선주 반등?...한화오션, 프리마켓서 2%대 강세", style: TextStyle(fontWeight: FontWeight.bold)),
                                  SizedBox(height: 4),
                                  Text('25.08.28 | 디지털타임스', style: TextStyle(fontSize: 12, color: Colors.grey)),
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
                            const CircleAvatar(backgroundImage: AssetImage('assets/images/stock_logo/stock_logo_5.png')),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('한화오션', style: TextStyle(fontWeight: FontWeight.bold)),
                                  Row(children: [Text('11,200원'), SizedBox(width: 8), Text('+2.2%', style: TextStyle(color: Colors.red))])
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