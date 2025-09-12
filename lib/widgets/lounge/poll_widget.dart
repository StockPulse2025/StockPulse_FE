import 'package:flutter/material.dart';

class PollWidget extends StatefulWidget {
  const PollWidget({super.key});

  @override
  State<PollWidget> createState() => _PollWidgetState();
}

class _PollWidgetState extends State<PollWidget> {
  int? _selectedIndex;
  bool _hasVoted = false;
  final Map<int, double> _voteResults = {0: 0.6, 1: 0.25, 2: 0.15};
  final Color navyColor = const Color(0xFF2B3A66);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 24), // 좌우 여백
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFD3D7E0), width: 1.5), // 테두리 색상, 두께
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('🗳️ 투표', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _hasVoted ? _buildPollResults() : _buildPollOptions(),
          const SizedBox(height: 8),
          const Text(
              '78명 참여',
              style: TextStyle(fontSize: 12, color: Color(0xFF7C7C7C), fontWeight: FontWeight.bold)
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
          onPressed: canVote ? () => setState(() => _hasVoted = true) : null,
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
    return Column(
      children: [
        _buildResultItem(0, '매수하기', _voteResults[0]!),
        _buildResultItem(1, '매도하기', _voteResults[1]!),
        _buildResultItem(2, '기다리기', _voteResults[2]!),
      ],
    );
  }

  Widget _buildOptionItem(int index, String title) {
    bool isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
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
    bool isMyChoice = _selectedIndex == index;
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
                        color: isMyChoice ? Colors.white : Colors.black,
                        fontWeight: FontWeight.bold
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