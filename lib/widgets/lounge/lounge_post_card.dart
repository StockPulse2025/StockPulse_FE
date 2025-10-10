import 'package:flutter/material.dart';
import '../../models/post_model.dart';

class LoungePostCard extends StatelessWidget {
  final Post post;
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
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: post.postImageUrl != null
                      ? Image.network(post.postImageUrl!, width: 80, height: 80, fit: BoxFit.cover)
                      : Container(width: 80, height: 80, color: Colors.grey.shade300),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(post.postTitle, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                          ),
                          const SizedBox(width: 8),
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 11,
                                backgroundImage: post.stockLogoUrl != null ? NetworkImage(post.stockLogoUrl!) : null,
                                child: post.stockLogoUrl == null ? const Icon(Icons.image) : null,
                              ),
                              const SizedBox(width: 4),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(post.stockName ?? '', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
                                  Row(
                                    children: [
                                      Text(post.stockPrice?.toString() ?? '', style: const TextStyle(fontSize: 7, fontWeight: FontWeight.bold)),
                                      const SizedBox(width: 4),
                                      Text(
                                        post.stockChange ?? '',
                                        style: TextStyle(
                                          color: post.stockChange?.startsWith('+') ?? false ? Colors.red : Colors.blue,
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
                      ),
                      const SizedBox(height: 4),
                      Text(post.postContent, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFFC7C7C7), fontSize: 10, fontWeight: FontWeight.bold)),
                      const Spacer(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.chat, size: 12, color: Color(0xFF2B3A66)),
                              const SizedBox(width: 4),
                              Text(post.commentCount.toString(), style: const TextStyle(color: Color(0xFF2B3A66), fontSize: 11, fontWeight: FontWeight.bold)),
                              const SizedBox(width: 12),
                              const Icon(Icons.how_to_vote, size: 12, color: Color(0xFF2B3A66)),
                              const SizedBox(width: 4),
                              Text(post.pollCount.toString(), style: const TextStyle(color: Color(0xFF2B3A66), fontSize: 11, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(width: 8),
                          Text(post.author, style: const TextStyle(fontSize: 11, color: Color(0xFFC2C2C2), fontWeight: FontWeight.bold)),
                        ],
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.article_outlined, size: 12, color: Color(0xFF585858)),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '${post.newsTitle ?? ''} | ${post.newsSource ?? ''}',
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
