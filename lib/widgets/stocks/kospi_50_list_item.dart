import 'package:flutter/material.dart';

class Kospi50ListItem extends StatefulWidget {
  final String rank;
  final String name;
  final String logoPath;
  final String price;
  final String change;
  final EdgeInsetsGeometry? contentPadding;

  const Kospi50ListItem({
    super.key,
    required this.rank,
    required this.logoPath,
    required this.name,
    required this.price,
    required this.change,
    this.contentPadding,
  });

  @override
  State<Kospi50ListItem> createState() => _Kospi50ListItemState();
}

class _Kospi50ListItemState extends State<Kospi50ListItem> {
  bool _isHolding = false;
  bool _isWatching = false;

  final Color positiveColor = const Color(0xFFFF0000);
  final Color negativeColor = const Color(0xFF0042FF);

  @override
  Widget build(BuildContext context) {
    final bool isUp = !widget.change.startsWith('-');
    return Padding(

      padding: widget.contentPadding ?? const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          Text(widget.rank, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(width: 16),
          ClipOval(
            child: Image.asset(
              widget.logoPath,
              width: 40,
              height: 40,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Text(widget.price, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF585858))),
                    const SizedBox(width: 8),
                    Text(widget.change, style: TextStyle(color: isUp ? positiveColor : negativeColor, fontSize: 14, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.credit_card, color: _isHolding ? const Color(0xFF2B3A66) : const Color(0xFFACB0BF)),
            onPressed: () => setState(() => _isHolding = !_isHolding),
          ),
          IconButton(
            icon: Icon(Icons.favorite, color: _isWatching ? const Color(0xFF2B3A66) : const Color(0xFFACB0BF)),
            onPressed: () => setState(() => _isWatching = !_isWatching),
          ),
        ],
      ),
    );
  }
}