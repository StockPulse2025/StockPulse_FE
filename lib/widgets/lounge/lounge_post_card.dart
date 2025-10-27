import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/post_model.dart';

class LoungePostCard extends StatelessWidget {
  final Post post;
  const LoungePostCard({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    // --- 1. 데이터 포맷팅 로직 ---
    final NumberFormat priceFormat = NumberFormat('###,###,###,###');
    final DateFormat dateFormat = DateFormat('yyyy.MM.dd');
    final DateFormat timeFormat = DateFormat('HH:mm');

    // 가격 및 등락률
    final priceString = post.stockPrice != null ? '${priceFormat.format(post.stockPrice)}원' : ' - ';
    final changeRate = post.stockChangeRate ?? 0.0;
    final isUp = changeRate >= 0;
    final changeRateString = '${isUp ? '+' : ''}${changeRate.toStringAsFixed(2)}%';

    final postDate = dateFormat.format(post.createdAt);
    final postTime = timeFormat.format(post.createdAt);
    final authorInfo = '$postDate｜$postTime｜${post.author}';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFF0F0F0), width: 1.0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: post.newsImageUrl != null && post.newsImageUrl!.isNotEmpty
                      ? Image.network(post.newsImageUrl!, width: 80, height: 80, fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(width: 80, height: 80, color: Colors.grey.shade300, child: const Icon(Icons.error)))
                      : Container(width: 80, height: 80, color: Colors.grey.shade300, child: const Icon(Icons.image_not_supported)),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // --- 2. 제목이 남는 공간을 모두 차지하도록 Expanded로 감싸기 ---
                          Expanded(
                            child: Text(
                              post.postTitle,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (post.stockName != null && post.stockName!.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            // 주식 정보 UI (오른쪽 정렬됨)
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 11,
                                  backgroundColor: Colors.grey.shade200,
                                  backgroundImage: post.stockLogoUrl != null && post.stockLogoUrl!.isNotEmpty ? NetworkImage(post.stockLogoUrl!) : null,
                                  child: post.stockLogoUrl == null || post.stockLogoUrl!.isEmpty ? const Icon(Icons.business, size: 14) : null,
                                ),
                                const SizedBox(width: 4),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(post.stockName!, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
                                    Row(
                                      children: [
                                        // --- 3. 포맷팅된 가격 및 등락률 표시 ---
                                        Text(priceString, style: const TextStyle(fontSize: 7, color: Color(0xFF585858), fontWeight: FontWeight.bold)),
                                        const SizedBox(width: 4),
                                        Text(
                                          changeRateString,
                                          style: TextStyle(
                                            color: isUp ? Colors.red : Colors.blue,
                                            fontSize: 7,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    )
                                  ],
                                )
                              ],
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        post.postContent,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Color(0xFF7C7C7C), fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          const Icon(Icons.chat, size: 12, color: Color(0xFF2B3A66)),
                          const SizedBox(width: 4),
                          Text(post.commentCount.toString(), style: const TextStyle(color: Color(0xFF2B3A66), fontSize: 11, fontWeight: FontWeight.bold)),
                          const SizedBox(width: 12),
                          const Icon(Icons.how_to_vote, size: 12, color: Color(0xFF2B3A66)),
                          const SizedBox(width: 4),
                          Text(post.pollCount.toString(), style: const TextStyle(color: Color(0xFF2B3A66), fontSize: 11, fontWeight: FontWeight.bold)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              authorInfo,
                              style: const TextStyle(fontSize: 11, color: Color(0xFFC2C2C2), fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          if (post.newsTitle != null && post.newsTitle!.isNotEmpty)
            Row(
              children: [
                const Icon(Icons.article_outlined, size: 12, color: Color(0xFF585858)),
                const SizedBox(width: 4),
                Expanded( // 여기의 Expanded는 Column 바로 아래에 있으므로 안전합니다.
                  child: Text(
                    '${post.newsTitle!} | ${post.newsSource ?? ''}',
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