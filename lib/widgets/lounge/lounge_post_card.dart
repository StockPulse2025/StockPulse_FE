import 'package:flutter/material.dart';

typedef PostData = Map<String, dynamic>;

class LoungePostCard extends StatelessWidget {
  final PostData post;
  const LoungePostCard({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFF0F0F0), width: 1.0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- [수정됨] IntrinsicHeight를 사용하여 Row의 자식들이 동일한 높이를 갖도록 합니다. ---
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. 게시글 썸네일 (이 위젯의 높이가 기준이 됩니다)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(post['postImageUrl'], width: 80, height: 80, fit: BoxFit.cover),
                ),
                const SizedBox(width: 12),
                // 2. 텍스트 정보 영역
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: Text(post['postTitle'], style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis)),
                          const SizedBox(width: 8),
                          // 관련 주식 정보
                          Row(
                            children: [
                              CircleAvatar(radius: 11, backgroundImage: AssetImage(post['stockLogoUrl'])),
                              const SizedBox(width: 4),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(post['stockName'], style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
                                  Row(
                                    children: [
                                      Text(post['stockPrice'], style: const TextStyle(fontSize: 7, fontWeight: FontWeight.bold)),
                                      const SizedBox(width: 4),
                                      Text(post['stockChange'], style: TextStyle(color: (post['stockChange'] as String).startsWith('+') ? Colors.red : Colors.blue, fontSize: 7, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ],
                              )
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(post['postContent'], maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFFC7C7C7), fontSize: 10, fontWeight: FontWeight.bold)),

                      const Spacer(), // 이제 IntrinsicHeight 덕분에 정상적으로 동작합니다.

                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.chat, size: 12, color: Color(0xFF2B3A66)),
                              const SizedBox(width: 4),
                              Text(post['commentCount'].toString(), style: const TextStyle(color: Color(0xFF2B3A66), fontSize: 11, fontWeight: FontWeight.bold)),
                              const SizedBox(width: 12),
                              const Icon(Icons.how_to_vote, size: 12, color: Color(0xFF2B3A66)),
                              const SizedBox(width: 4),
                              Text(post['pollCount'].toString(), style: const TextStyle(color: Color(0xFF2B3A66), fontSize: 11, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(width: 8),
                          Text(post['authorInfo'], style: const TextStyle(fontSize: 11, color: Color(0xFFC2C2C2), fontWeight: FontWeight.bold)),
                        ],
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // 관련 뉴스 제목
          Row(
            children: [
              const Icon(Icons.article_outlined, size: 12, color: Color(0xFF585858)),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '${post['newsTitle']} | ${post['newsSource']}',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF585858), fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}