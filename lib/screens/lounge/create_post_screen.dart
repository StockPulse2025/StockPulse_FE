import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/news_model.dart';
import 'package:stockpulse2/models/stock_model.dart';
import '../../services/api_service.dart';
import '../home_screen.dart';
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
  bool _isStockLoading = false;
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
    final basicStock = await Navigator.push<Stock?>(
      context,
      MaterialPageRoute(builder: (context) => const StockSelectionScreen()),
    );
    if (basicStock == null) return;

    setState(() {
      _isStockLoading = true;
      _selectedStock = basicStock;
    });

    try {
      final completeStock = await apiService.fetchStockDetailsForPost(basicStock.stockId);
      if (mounted) {
        setState(() {
          _selectedStock = completeStock;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('주식 정보를 불러오는 데 실패했습니다.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isStockLoading = false;
        });
      }
    }
  }

  void _submitPost() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (title.isEmpty || content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('제목과 내용을 모두 입력해주세요.')),
      );
      return;
    }

    // 게시글 생성 API 호출
    final int? createdPostId = await apiService.createPost(
      newsId: widget.newsData.newsId,
      title: title,
      content: content,
      stockId: _selectedStock?.stockId ?? 0,
      requireVote: _showPoll,
    );

    if (createdPostId != null && mounted) {
      // 성공 시 라운지 탭으로 이동
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const HomeScreen(initialIndex: 3)),
            (route) => false,
      );
      // 생성된 게시글 상세 페이지로 바로 이동
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PostDetailScreen(
            postId: createdPostId,
            isPollPost: _showPoll,
          ),
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('게시글 작성에 실패했습니다.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        titleSpacing: 0,
        centerTitle: false,
        title: const Text('게시글 작성', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),

        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: TextButton(
              onPressed: _submitPost,
              style: TextButton.styleFrom(
                backgroundColor: Colors.white,
              ),
              child: Text(
                '완료',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: navyColor,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDecoratedBox(_buildNewsInfoCard()),
            const SizedBox(height: 32),
            _buildDecoratedBox(_buildStockSelector()),
            const SizedBox(height: 16),
            const Divider(height: 32, color: Color(0xFFE8EBF2)),
            TextField(
              controller: _titleController,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              decoration: const InputDecoration(
                hintText: '제목을 입력해주세요.',
                hintStyle: TextStyle(color: Color(0xFFBDBDBD), fontWeight: FontWeight.bold, fontSize: 18),
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
    );
  }

  Widget _buildDecoratedBox(Widget child) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(width: 4, color: navyColor),
          const SizedBox(width: 12),
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

          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Image.network(
              widget.newsData.newsImage,
              width: 50,
              height: 50,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  Container(width: 50, height: 50, color: Colors.grey.shade200, child: const Icon(Icons.error)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  widget.newsData.newsTitle,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  widget.newsData.dateSource,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFC2C2C2)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStockSelector() {
   String priceString = '';
    String changeRateString = '';
    bool isUp = false;

    if (_selectedStock != null) {
      final NumberFormat priceFormat = NumberFormat('###,###,###,###');
      priceString = '${priceFormat.format(_selectedStock!.currentPrice)}원';

      final changeRate = _selectedStock!.changeRate ?? 0.0;
      isUp = changeRate >= 0;
      changeRateString = '${isUp ? '+' : ''}${changeRate.toStringAsFixed(2)}%';
    }
   return InkWell(
     onTap: _isStockLoading ? null : _navigateToStockSelection,
     child: Container(
       padding: const EdgeInsets.all(12),
       color: const Color(0xFFF9FAFB),
       child: Row(
         mainAxisAlignment: MainAxisAlignment.spaceBetween,
         children: [
           if (_isStockLoading)
             const SizedBox(
               height: 24,
               width: 24,
               child: CircularProgressIndicator(strokeWidth: 2.0),
             )
           else if (_selectedStock == null)
             const Text('토론할 종목을 선택해주세요', style: TextStyle(fontWeight: FontWeight.bold))
           else
             Flexible(
               child: Row(
                 children: [
                   CircleAvatar(
                     backgroundImage: _selectedStock!.imageUrl != null && _selectedStock!.imageUrl!.isNotEmpty
                         ? NetworkImage(_selectedStock!.imageUrl!)
                         : null,
                     child: _selectedStock!.imageUrl == null || _selectedStock!.imageUrl!.isEmpty ? Text(_selectedStock!.name[0]) : null,
                   ),
                   const SizedBox(width: 8),
                   Expanded(
                     child: Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                         Text(_selectedStock!.name, style: const TextStyle(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                         Row(
                           children: [
                             Text(priceString, style: const TextStyle(fontSize: 12)),
                             const SizedBox(width: 8),
                             Text(
                               changeRateString,
                               style: TextStyle(
                                 color: isUp ? Colors.red : Colors.blue,
                                 fontSize: 12,
                               ),
                             ),
                           ],
                         ),
                       ],
                     ),
                   ),
                 ],
               ),
             ),
           if (!_isStockLoading)
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