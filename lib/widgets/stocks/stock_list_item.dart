import 'package:flutter/material.dart';

enum IconType { holdings, watchlist }

class StockListItem extends StatefulWidget {
  final String name;
  final String price;
  final String change;
  final IconType iconType;
  final String imagePath;

  const StockListItem({
    super.key,
    required this.name,
    required this.price,
    required this.change,
    required this.iconType,
    required this.imagePath,
  });

  @override
  State<StockListItem> createState() => _StockListItemState();
}

class _StockListItemState extends State<StockListItem> {
  bool _isSelected = true;

  @override
  Widget build(BuildContext context) {
    if (!_isSelected) return const SizedBox.shrink(); // 해제 시 삭제
    final bool isUp = !widget.change.startsWith('-');
    Widget iconWidget = CircleAvatar(
      backgroundColor: Colors.grey,
      radius: 20,
      backgroundImage: AssetImage(widget.imagePath),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 6.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          children: [
            iconWidget,
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.name, style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16)),
                  Row(
                    children: [
                      Text(widget.price, style: const TextStyle(fontSize: 14)),
                      const SizedBox(width: 8),
                      Text(widget.change, style: TextStyle(
                          color: isUp ? Colors.red : Colors.blue,
                          fontSize: 14)),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(
                widget.iconType == IconType.holdings
                    ? Icons.credit_card
                    : Icons.favorite,
                color: _isSelected ? const Color(0xFF232F55) : Colors.grey,
              ),
              onPressed: () {
                setState(() {
                  _isSelected = !_isSelected;
                });
              },
            )
          ],
        ),
      ),
    );
  }
}
