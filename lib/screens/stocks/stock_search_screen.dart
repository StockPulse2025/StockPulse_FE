import 'package:flutter/material.dart';

class StockSearchScreen extends StatefulWidget {
  const StockSearchScreen({super.key});

  @override
  State<StockSearchScreen> createState() => _StockSearchScreenState();
}

class _StockSearchScreenState extends State<StockSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _hasSearched = false;
  // TODO: 실제 검색 결과로 교체될 예시 데이터
  final List<String> _searchResults = ['삼성전자', '삼성바이오로직스'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9FAFB),
        surfaceTintColor: const Color(0xFFF9FAFB),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: const InputDecoration(hintText: '종목명 검색', border: InputBorder.none),
          onSubmitted: (value) => setState(() => _hasSearched = true),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: _hasSearched
            ? (_searchResults.isNotEmpty
            ? ListView.builder(
          itemCount: _searchResults.length,
          itemBuilder: (context, index) {
            return ListTile(
              leading: const CircleAvatar(
                backgroundImage: AssetImage('assets/images/stock_logo/stock_logo_7.png'),
                backgroundColor: Colors.transparent,
              ),
              title: Text(_searchResults[index]),
              onTap: () {
                // TODO: 해당 종목 상세 페이지로 이동하는 로직 추가
              },
            );
          },
        )
            : const Center(child: Text('해당하는 주식이 없습니다.')))
            : const Center(child: Text('최근 검색 내역이 없습니다.')),
      ),
    );
  }
}