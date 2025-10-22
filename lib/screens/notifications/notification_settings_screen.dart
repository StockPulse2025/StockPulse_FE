import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});
  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  bool _holdingsFilter = true;
  bool _watchlistFilter = false;
  bool _neutralFilter = false;
  bool _goodNewsFilter = true;
  bool _badNewsFilter = true;
  RangeValues _goodNewsRange = const RangeValues(50, 100);
  RangeValues _badNewsRange = const RangeValues(20, 70);

  final Color navyColor = const Color(0xFF2B3A66);
  final Color sliderInactiveColor = const Color(0xFFACB0BF);
  // final ApiService apiService = ApiService(); // ApiService 인스턴스는 필요 시에만 생성

  // --- CHANGED ---
  // 저장 기능은 백엔드 API가 준비될 때까지 임시로 처리합니다.
  Future<void> _saveSettings() async {
    // --- 백엔드 알림 설정 저장 API가 준비되면 아래 주석을 풀고 연결합니다. ---
    /*
    try {
      // 1. ApiService에 알림 설정을 저장하는 새로운 함수를 만들어야 합니다.
      //    (예: ApiService().saveNotificationSettings)
      await ApiService().saveNotificationSettings(
        holdingsEnabled: _holdingsFilter,
        watchlistEnabled: _watchlistFilter,
        neutralEnabled: _neutralFilter,
        goodNewsEnabled: _goodNewsFilter,
        goodNewsRange: _goodNewsRange,
        badNewsEnabled: _badNewsFilter,
        badNewsRange: _badNewsRange,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('설정이 저장되었습니다.')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('설정 저장에 실패했습니다: $e')));
      }
    }
    */

    // --- 임시 코드 ---
    // 현재는 기능이 준비되지 않았음을 사용자에게 알립니다.
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('알림 설정 저장 기능은 현재 준비 중입니다.')),
      );
      // 저장이 완료된 것처럼 화면을 닫아줍니다.
      Navigator.pop(context);
    }
  }

  void _resetFilters() {
    setState(() {
      _holdingsFilter = true;
      _watchlistFilter = false;
      _neutralFilter = false;
      _goodNewsFilter = true;
      _badNewsFilter = true;
      _goodNewsRange = const RangeValues(50, 100);
      _badNewsRange = const RangeValues(20, 70);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        centerTitle: false,
        title: const Text('알림 설정', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle('종목 필터'),
                        const Divider(thickness: 1.5),
                        _buildSwitchTile('내 보유 종목', _holdingsFilter, (val) => setState(() => _holdingsFilter = val)),
                        _buildSwitchTile('내 관심 종목', _watchlistFilter, (val) => setState(() => _watchlistFilter = val)),
                      ],
                    ),
                  ),
                  Container(height: 8, color: const Color(0xFFF9FAFB)),
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle('민감도 필터'),
                        const Divider(thickness: 1.5),
                        _buildSwitchTile('중립', _neutralFilter, (val) => setState(() => _neutralFilter = val)),
                        _buildSwitchTile('호재', _goodNewsFilter, (val) => setState(() => _goodNewsFilter = val)),
                        if (_goodNewsFilter)
                          _buildRangeSlider(_goodNewsRange, (val) => setState(() => _goodNewsRange = val)),
                        _buildSwitchTile('악재', _badNewsFilter, (val) => setState(() => _badNewsFilter = val)),
                        if (_badNewsFilter)
                          _buildRangeSlider(_badNewsRange, (val) => setState(() => _badNewsRange = val)),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _resetFilters, // 초기화 함수 연결
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
                    onPressed: _saveSettings,
                    child: const Text('저장', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: navyColor,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  // _buildSectionTitle, _buildSwitchTile, _buildRangeSlider 위젯들은 수정 없이 그대로 사용합니다.
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 8),
      child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
    );
  }

  Widget _buildSwitchTile(String title, bool value, Function(bool) onChanged) {
    return SwitchListTile(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
      value: value,
      onChanged: onChanged,
      activeColor: navyColor,
      inactiveTrackColor: Colors.grey[200],
      inactiveThumbColor: Colors.white,
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
            values: values,
            min: 0,
            max: 100,
            divisions: 100,
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
                    ))),
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
                    ))),
          ],
        )
      ],
    );
  }
}