import 'dart:async'; // Timer를 사용하기 위해 import
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/stock_model.dart';

class StockSelectionScreen extends StatefulWidget {
  const StockSelectionScreen({super.key});

  @override
  State<StockSelectionScreen> createState() => _StockSelectionScreenState();
}

class _StockSelectionScreenState extends State<StockSelectionScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();

  List<Stock> _searchResults = [];
  bool _isLoading = false;
  bool _hasSearched = false; // 최초 검색 여부를 확인하기 위한 플래그
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    // 검색창의 텍스트가 변경될 때마다 _onSearchChanged 함수 호출
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounce?.cancel(); // 위젯이 사라질 때 타이머 취소
    super.dispose();
  }

  // 사용자의 타이핑이 멈추면(500ms) 검색을 실행하여 불필요한 API 호출을 줄임
  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _performSearch(_searchController.text);
    });
  }

  // API를 호출하여 주식을 검색하는 함수
  Future<void> _performSearch(String keyword) async {
    // 검색어가 비어있으면 목록을 비우고 함수 종료
    if (keyword.trim().isEmpty) {
      if (mounted) {
        setState(() {
          _searchResults = [];
          _hasSearched = false;
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        _isLoading = true;
        _hasSearched = true;
      });
    }

    try {
      final results = await _apiService.searchStocks(keyword);
      if (mounted) {
        setState(() {
          _searchResults = results;
        });
      }
    } catch (e) {
      print('종목 검색 실패: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('검색 중 오류가 발생했습니다.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(), // 인자 없이 pop
        ),
        // 제목 대신 검색창(TextField) 배치
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: '종목명 또는 종목코드로 검색',
            border: InputBorder.none,
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  // 화면의 상태에 따라 다른 위젯을 보여주는 함수
  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!_hasSearched) {
      return const Center(
        child: Text(
          '검색어를 입력해 주세요.',
          style: TextStyle(color: Colors.grey, fontSize: 16),
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return const Center(
        child: Text(
          '검색 결과가 없습니다.',
          style: TextStyle(fontSize: 16),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      itemCount: _searchResults.length,
      separatorBuilder: (context, index) => const Divider(color: Color(0xFFE1E1E3), height: 1),
      itemBuilder: (context, index) {
        final stock = _searchResults[index];
        // search API 응답에는 가격 정보가 없으므로, 이름과 심볼만 표시
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(
            backgroundImage: stock.imageUrl != null && stock.imageUrl!.isNotEmpty
                ? NetworkImage(stock.imageUrl!)
                : null,
            backgroundColor: Colors.grey[200],
            child: stock.imageUrl == null || stock.imageUrl!.isEmpty
                ? Text(stock.name.isNotEmpty ? stock.name[0] : '')
                : null,
          ),
          title: Text(stock.name, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(stock.symbol),
          onTap: () {
            // 주식을 선택하면, 선택된 stock 객체를 이전 화면으로 반환
            Navigator.pop(context, stock);
          },
        );
      },
    );
  }
}