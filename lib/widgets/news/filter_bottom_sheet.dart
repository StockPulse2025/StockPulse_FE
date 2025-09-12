import 'package:flutter/material.dart';

class FilterBottomSheet extends StatefulWidget {
  const FilterBottomSheet({super.key});
  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  String _sortOrder = '최신순';
  String _stockFilter = '전체종목';
  final Set<String> _selectedIndustries = {};
  bool _neutralFilter = false;
  bool _goodNewsFilter = false;
  bool _badNewsFilter = false;
  RangeValues _goodNewsRange = const RangeValues(50, 100);
  RangeValues _badNewsRange = const RangeValues(20, 70);

  final Color navyColor = const Color(0xFF2B3A66);
  final Color sliderInactiveColor = const Color(0xFFACB0BF);

  @override
  Widget build(BuildContext context) {
    return Container(
        height: MediaQuery.of(context).size.height * 0.85,
        padding: const EdgeInsets.symmetric(vertical: 16), // 수평 패딩은 제거
        decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20))),
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24), // 헤더에만 패딩 적용
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('필터', style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold)),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
            ]),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

              Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('뉴스 필터'),
                  const Divider(color: Color(0xFFE8EBF2), thickness: 1.5),
                  _buildSubHeader('정렬'),
                  _buildSingleChoiceChip(['최신순', '오래된순'], _sortOrder, (val) => setState(() => _sortOrder = val)),
                  _buildSubHeader('종목'),
                  _buildSingleChoiceChip(
                      ['전체종목', '보유종목', '관심종목'], _stockFilter, (val) => setState(() => _stockFilter = val)),
                  _buildSubHeader('관련 종목 산업군'),
                  _buildMultiChoiceChip([
                    '전체테마', '철강소재', '바이오제약', '자동차부품', '2차전지전기차', '에너지신재생', '반도체디스플레이',
                    '건설부동산', '게인엔터', '통신5G', '유통소비재', 'IT소프트웨어', '금융보험', '운송물류', '유틸리티'
                  ]),
                  const SizedBox(height: 24),
                ],
              ),
            ),

            Container(
              height: 8,
              color: const Color(0xFFF9FAFB),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('민감도 필터'),
                    const Divider(color: Color(0xFFE8EBF2), thickness: 1.5, height: 2),
                    _buildSwitchTile('중립', _neutralFilter, (val) => setState(() => _neutralFilter = val)),
                    _buildSwitchTile('호재', _goodNewsFilter, (val) => setState(() => _goodNewsFilter = val)),
                    if (_goodNewsFilter)
                      _buildRangeSlider(_goodNewsRange, (val) => setState(() => _goodNewsRange = val)),
                    _buildSwitchTile('악재', _badNewsFilter, (val) => setState(() => _badNewsFilter = val)),
                    if (_badNewsFilter)
                      _buildRangeSlider(_badNewsRange, (val) => setState(() => _badNewsRange = val)),
                    const SizedBox(height: 50),
                  ],
              ),
            ),
              ]),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {},
                      child: Text('초기화', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: navyColor)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: navyColor, width: 2.0),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {},
                      child: const Text('저장', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: navyColor,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                ]
            ),
          )
        ]));
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 8),
      child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
    );
  }

  Widget _buildSubHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
    );
  }

  Widget _buildSingleChoiceChip(List<String> items, String selected, Function(String) onSelected) {
    return Wrap(
      spacing: 8.0, runSpacing: 8.0,
      children: items.map((item) {
        final bool isSelected = selected == item;
        return ChoiceChip(
          label: Text(item, style: const TextStyle(fontSize: 12)),
          selected: isSelected,
          onSelected: (selected) {
            if (selected) onSelected(item);
          },
          backgroundColor: Colors.white,
          selectedColor: navyColor,
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
          checkmarkColor: Colors.white,
          shape: StadiumBorder(
            side: BorderSide(
              width: 1.5,
              color: isSelected ? navyColor : Colors.grey[300]!,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        );
      }).toList(),
    );
  }

  Widget _buildMultiChoiceChip(List<String> items) {
    return Wrap(
        spacing: 8.0, runSpacing: 8.0,
        children: items.map((item) {
          final bool isSelected = _selectedIndustries.contains(item);
          return FilterChip(
              label: Text(item, style: const TextStyle(fontSize: 12)),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) _selectedIndustries.add(item);
                  else _selectedIndustries.remove(item);
                });
              },
              backgroundColor: Colors.white,
              selectedColor: navyColor,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.black,
                fontWeight: FontWeight.bold,
              ),
            checkmarkColor: Colors.white,
            shape: StadiumBorder(
              side: BorderSide(
                width: 1.5,
                color: isSelected ? navyColor : Colors.grey[300]!,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          );
        }).toList(),
    );
  }

  Widget _buildSwitchTile(String title, bool value, Function(bool) onChanged) {
    return SwitchListTile(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
      value: value,
      onChanged: onChanged,
      activeColor: navyColor,
      inactiveTrackColor: Colors.white,
      inactiveThumbColor: Colors.grey[400],
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildRangeSlider(RangeValues values, Function(RangeValues) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: navyColor,
            inactiveTrackColor: sliderInactiveColor,
            thumbColor: navyColor,
          ),
          child: RangeSlider(
            values: values, min: 0, max: 100, divisions: 100,
            labels: RangeLabels(values.start.round().toString(), values.end.round().toString()),
            onChanged: onChanged,
          ),
        ),

        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
                width: 80,
                height: 40,
                child: TextField(
                    textAlign: TextAlign.center,

                    textAlignVertical: TextAlignVertical.center,
                    style: const TextStyle(fontSize: 12),
                    controller: TextEditingController(text: values.start.round().toString()),
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.zero,
                    )
                )
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.0),
              child: Text('~', style: TextStyle(fontSize: 12)),
            ),
            SizedBox(
                width: 80,
                height: 40,
                child: TextField(
                    textAlign: TextAlign.center,

                    textAlignVertical: TextAlignVertical.center,
                    style: const TextStyle(fontSize: 12),
                    controller: TextEditingController(text: values.end.round().toString()),
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.zero,
                    )
                )
            ),
          ],
        )
      ],
    );
  }
}