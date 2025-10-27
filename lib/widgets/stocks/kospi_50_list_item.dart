import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:stockpulse2/services/api_service.dart';

class Kospi50ListItem extends StatefulWidget {
  final int stockId;
  final bool isOwned;
  final bool isFavorite;
  final String rank;
  final String name;
  final String logoPath;
  final double price;
  final double changeRate;

  final EdgeInsetsGeometry? contentPadding;
  final VoidCallback onToggle;

  const Kospi50ListItem({
    super.key,
    required this.stockId,
    required this.isOwned,
    required this.isFavorite,
    required this.rank,
    required this.logoPath,
    required this.name,
    required this.price,
    required this.changeRate,
    this.contentPadding,
    required this.onToggle,
  });

  @override
  State<Kospi50ListItem> createState() => _Kospi50ListItemState();
}

class _Kospi50ListItemState extends State<Kospi50ListItem> {
  late bool _isOwned;
  late bool _isFavorite;
  final ApiService apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _isOwned = widget.isOwned;
    _isFavorite = widget.isFavorite;
  }

  Future<void> _toggleOwned() async {
    setState(() => _isOwned = !_isOwned);
    try {
      await apiService.toggleOwnedStock(widget.stockId);
      widget.onToggle();
    } catch (e) {
      setState(() => _isOwned = !_isOwned);
      print('보유 종목 토글 실패: $e');
    }
  }

  Future<void> _toggleFavorite() async {
    setState(() => _isFavorite = !_isFavorite);
    try {
      await apiService.toggleFavoriteStock(widget.stockId);
      widget.onToggle();
    } catch (e) {
      setState(() => _isFavorite = !_isFavorite);
      print('관심 종목 토글 실패: $e');
    }
  }

  @override
  void didUpdateWidget(covariant Kospi50ListItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isOwned != oldWidget.isOwned) {
      setState(() {
        _isOwned = widget.isOwned;
      });
    }
    if (widget.isFavorite != oldWidget.isFavorite) {
      setState(() {
        _isFavorite = widget.isFavorite;
      });
    }
  }

  final Color positiveColor = const Color(0xFFFF0000);
  final Color negativeColor = const Color(0xFF0042FF);

  @override
  Widget build(BuildContext context) {
    final logoPath = widget.logoPath.isNotEmpty ? widget.logoPath : 'https://via.placeholder.com/40';
    final bool isUp = widget.changeRate >= 0;

    final priceFormatter = NumberFormat('#,###');
    final formattedPrice = '${priceFormatter.format(widget.price)}원';
    final formattedChangeRate = '${isUp ? '+' : ''}${widget.changeRate.toStringAsFixed(2)}%';

    return Padding(
      padding: widget.contentPadding ?? const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          Text(widget.rank, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(width: 16),
          ClipOval(
            child: Image.network(
              logoPath,
              width: 40,
              height: 40,
              fit: BoxFit.cover,

              errorBuilder: (context, error, stackTrace) {
                return const Icon(Icons.error, size: 40);
              },
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

                    Text(formattedPrice, style: const TextStyle(color: Color(0xFF585858), fontSize: 14, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    Text(formattedChangeRate, style: TextStyle(color: isUp ? positiveColor : negativeColor, fontSize: 14, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
      IconButton(
        icon: Icon(Icons.credit_card, color: _isOwned ? const Color(0xFF2B3A66) : const Color(0xFFACB4B0)),
        onPressed: _toggleOwned,
      ),
      IconButton(
        icon: Icon(Icons.favorite, color: _isFavorite ? const Color(0xFF2B3A66) : const Color(0xFFACB4B0)),
        onPressed: _toggleFavorite,
      )
        ],
      ),
    );
  }
}