import 'package:flutter/material.dart';
import '../../models/stock_model.dart';
import '../../services/api_service.dart';
import 'stock_detail_screen.dart';

class StockSearchScreen extends StatefulWidget {
  const StockSearchScreen({super.key});
  @override
  State<StockSearchScreen> createState() => _StockSearchScreenState();
}

class _StockSearchScreenState extends State<StockSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Stock> _searchResults = [];
  bool _isLoading = false;
  bool _noResults = false;

  final ApiService apiService = ApiService();

  Future<void> _performSearch(String keyword) async {
    if (keyword.isEmpty) {
      setState(() {
        _searchResults.clear();
        _noResults = false;
      });
      return;
    }
    setState(() {
      _isLoading = true;
      _noResults = false;
    });
    try {
      final results = await apiService.searchStocks(keyword);
      setState(() {
        _searchResults = results;
        _noResults = results.isEmpty;
      });
    } catch (e) {
      // 오류 처리 필요
      setState(() {
        _searchResults.clear();
        _noResults = true;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9FAFB),
        surfaceTintColor: const Color(0xFFF9FAFB),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios), onPressed: () => Navigator.of(context).pop()),
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: const InputDecoration(hintText: '종목명 검색', border: InputBorder.none),
          onSubmitted: (value) => _performSearch(value.trim()),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _noResults
          ? const Center(child: Text('검색 결과가 없습니다'))
          : ListView.builder(
        itemCount: _searchResults.length,
        itemBuilder: (context, index) {
          final stock = _searchResults[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundImage: NetworkImage(stock.imageUrl ?? 'https://default-image-url.com/default.png'
              ),
            ),
            title: Text(stock.name),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => StockDetailScreen(stockId: stock.stockId),
                ),
              );
            },
          );
        },
      )
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
