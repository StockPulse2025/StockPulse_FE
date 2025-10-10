import 'package:flutter/material.dart';
import '../../models/news_model.dart';
import 'package:stockpulse2/models/stock_model.dart';
import '../../services/api_service.dart';
import '../main_screen.dart';
import 'post_detail_screen.dart';
import 'stock_selection_screen.dart';

class CreatePostScreen extends StatefulWidget {
  final News newsData;

  const CreatePostScreen({
    super.key,
    required this.newsData,
  });

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  bool _showPoll = true;
  Stock? _selectedStock;
  final Color navyColor = const Color(0xFF2B3A66);

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();

  final ApiService apiService = ApiService();

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _navigateToStockSelection() async {
    final result = await Navigator.push<Stock?>(
      context,
      MaterialPageRoute(builder: (context) => const StockSelectionScreen()),
    );
    if (result != null) {
      setState(() {
        _selectedStock = result;
      });
    }
  }

  void _submitPost() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    final int? createdPostId = await apiService.createPost(
      newsId: widget.newsData.newsId,
      title: title,
      content: content,
      stockId: _selectedStock?.stockId ?? 0,
      requireVote: _showPoll,
    );

    if (createdPostId != null) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const MainScreen(initialIndex: 3)),
            (route) => false,
      );

      if (_showPoll) {
        Navigator.of(context).push(
          MaterialPageRoute(
              builder: (_) => PostDetailScreen(postId: createdPostId, isPollPost: true)),
        );
      } else {
        Navigator.of(context).push(
          MaterialPageRoute(
              builder: (_) => PostDetailScreen(postId: createdPostId, isPollPost: false)),
        );
      }
    } else {
      // 실패 처리
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        titleSpacing: 0,
        centerTitle: false,
        title: const Text('게시글 작성', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        actions: const [],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDecoratedBox(_buildNewsInfoCard()),
                const SizedBox(height: 16),
                _buildDecoratedBox(_buildStockSelector()),
                const Divider(height: 32, color: Colors.transparent),
                TextField(
                  controller: _titleController,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  decoration: const InputDecoration(
                    hintText: '제목을 입력해주세요.',
                    hintStyle: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFE8EBF2))),
                    focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFE8EBF2), width: 2.0)),
                  ),
                ),
                const SizedBox(height: 32),
                if (_showPoll) _buildPollSection(),
                TextField(
                  controller: _contentController,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  decoration: const InputDecoration(
                    hintText: '내용을 입력해주세요.',
                    hintStyle: TextStyle(color: Color(0xFF7C7C7C), fontWeight: FontWeight.bold),
                    border: InputBorder.none,
                  ),
                  maxLines: 5,
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 24,
            right: 24,
            child: ElevatedButton(
              onPressed: _submitPost,
              style: ElevatedButton.styleFrom(
                backgroundColor: navyColor,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('완료', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDecoratedBox(Widget child) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(width: 4, color: navyColor),
          Expanded(child: child),
        ],
      ),
    );
  }

  Widget _buildNewsInfoCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      color: const Color(0xFFF9FAFB),
      child: Row(
        children: [
          Image.network(widget.newsData.newsImage),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(widget.newsData.newsTitle, style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text(widget.newsData.dateSource, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFC2C2C2))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStockSelector() {
    final bool isUp = (_selectedStock?.changeAmount ?? 0) > 0;

    return InkWell(
      onTap: _navigateToStockSelection,
      child: Container(
        padding: const EdgeInsets.all(12),
        color: const Color(0xFFF9FAFB),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _selectedStock == null
                ? const Text('토론할 종목을 선택해주세요', style: TextStyle(fontWeight: FontWeight.bold))
                : Row(
              children: [
                CircleAvatar(
                  backgroundImage: NetworkImage(_selectedStock!.imageUrl ?? 'https://default-image-url.com/default.png'),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_selectedStock!.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    Row(
                      children: [
                        Text(_selectedStock!.currentPrice.toString(), style: const TextStyle(fontSize: 12)),
                        const SizedBox(width: 4),
                        Text(
                          _selectedStock!.changeAmount.toString(),
                          style: TextStyle(color: isUp ? Colors.red : Colors.blue, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildPollSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.2), spreadRadius: 1, blurRadius: 5)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('🗳️ 투표 추가하기', style: TextStyle(fontWeight: FontWeight.bold)),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => setState(() => _showPoll = false),
              )
            ],
          ),
          const SizedBox(height: 9),
          _buildPollItem('매수하기'),
          _buildPollItem('매도하기'),
          _buildPollItem('기다리기'),
          const SizedBox(height: 8),
          const Text('투표를 삭제하려면 x버튼을 눌러주세요', style: TextStyle(fontSize: 12, color: Color(0xFF7C7C7C), fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildPollItem(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(title, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
    );
  }
}