import 'package:flutter/material.dart';
import '../../models/notification_model.dart';

class NotificationCard extends StatelessWidget {
  final NotificationModel notification;

  const NotificationCard({
    super.key,
    required this.notification,
  });

  @override
  Widget build(BuildContext context) {
    final double impact = notification.impactRate;
    final bool isUp = impact >= 0; // 0 이상을 호재로 간주
    const Color positiveColor = Color(0xFFF04E52);
    const Color negativeColor = Color(0xFF3687F6);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // [수정] Image.network로 변경하고 에러 빌더 추가
          ClipRRect(
            borderRadius: BorderRadius.circular(8.0),
            child: Image.network(
              notification.stockImgUrl, // API에서 받은 이미지 URL 사용
              width: 70,
              height: 70,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container( // 이미지 로딩 실패 시 회색 박스와 아이콘 표시
                  width: 70,
                  height: 70,
                  color: Colors.grey[200],
                  child: const Icon(Icons.image_not_supported_outlined, color: Colors.grey),
                );
              },
            ),
          ),
          const SizedBox(width: 10),
          // [수정] Row 안에서 남는 공간을 모두 차지하도록 Expanded 추가
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: const TextStyle(color: Colors.black, fontSize: 13, fontWeight: FontWeight.bold, fontFamily: 'Pretendard'),
                    children: [
                      TextSpan(text: '"${notification.stockName}" 주가변동 예측 영향도 '),
                      TextSpan(
                        text: '${isUp ? '+' : ''}${impact.toStringAsFixed(1)}%',
                        style: TextStyle(color: isUp ? positiveColor : negativeColor),
                      ),
                      const TextSpan(text: ' 포착 📸'),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                    notification.newsTitle, // API 데이터 사용
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    ClipOval(
                      child: Image.network(
                        notification.stockImgUrl, // 로고 이미지도 동일 URL 사용
                        width: 20,
                        height: 20,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.grey[200]),
                            child: const Icon(Icons.business, size: 12, color: Colors.grey),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 7),
                    Text(notification.stockName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}