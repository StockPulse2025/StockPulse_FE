import 'package:flutter/material.dart';
import 'package:stockpulse2/models/post_model.dart';

class PollWidget extends StatefulWidget {
  final VoteSummary voteSummary;
  final bool hasVoted;
  final String? myVoteOption; // <<--- 'BUY', 'SELL', 'HOLD'
  final Function(int voteType) onVote;

  const PollWidget({
    super.key,
    required this.voteSummary,
    required this.hasVoted,
    this.myVoteOption,
    required this.onVote,
  });

  @override
  State<PollWidget> createState() => _PollWidgetState();
}

class _PollWidgetState extends State<PollWidget> {
  int? _selectedIndex;
  final Color navyColor = const Color(0xFF2B3A66);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFD3D7E0), width: 1.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('🗳️ 투표', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          widget.hasVoted ? _buildPollResults() : _buildPollOptions(),
          const SizedBox(height: 8),
          Text(
            '${widget.voteSummary.total}명 참여',
            style: const TextStyle(fontSize: 12, color: Color(0xFF7C7C7C), fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildPollOptions() {
    final bool canVote = _selectedIndex != null;
    return Column(
      children: [
        _buildOptionItem(0, '매수하기'),
        _buildOptionItem(1, '매도하기'),
        _buildOptionItem(2, '기다리기'),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: canVote ? () => widget.onVote(_selectedIndex!) : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: canVote ? navyColor : const Color(0xFFE8EBF2),
            foregroundColor: canVote ? Colors.white : Colors.black,
            minimumSize: const Size(double.infinity, 40),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            elevation: 0,
          ),
          child: const Text('투표하기', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildPollResults() {
    final total = widget.voteSummary.total == 0 ? 1 : widget.voteSummary.total;
    final buyPercentage = widget.voteSummary.buy / total;
    final sellPercentage = widget.voteSummary.sell / total;
    final holdPercentage = widget.voteSummary.hold / total;

    return Column(
      children: [
        _buildResultItem(0, '매수하기', buyPercentage),
        _buildResultItem(1, '매도하기', sellPercentage),
        _buildResultItem(2, '기다리기', holdPercentage),
      ],
    );
  }

  Widget _buildOptionItem(int index, String title) {
    final bool isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => setState(() {
        if (!widget.hasVoted) _selectedIndex = index;
      }),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        width: double.infinity,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE8EBF2) : const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildResultItem(int index, String title, double percentage) {
    String voteOptionString = '';
    switch (index) {
      case 0: voteOptionString = 'BUY'; break;
      case 1: voteOptionString = 'SELL'; break;
      case 2: voteOptionString = 'HOLD'; break;
    }
    // <<--- 내가 투표한 옵션과 현재 항목이 일치하는지 확인
    final bool isMyChoice = widget.hasVoted && widget.myVoteOption == voteOptionString;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      height: 40,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              Container(
                width: constraints.maxWidth * percentage,
                decoration: BoxDecoration(
                  // <<--- isMyChoice에 따라 색상 변경
                  color: isMyChoice ? navyColor : const Color(0xFFACB0BF),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: Text(
                    '$title (${(percentage * 100).toStringAsFixed(0)}%)',
                    style: TextStyle(
                      // <<--- isMyChoice에 따라 텍스트 색상 변경
                      color: isMyChoice ? Colors.white : Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              )
            ],
          );
        },
      ),
    );
  }
}