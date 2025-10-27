import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});
  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;

  bool _holdingsFilter = true;
  bool _watchlistFilter = false;
  bool _neutralFilter = false;
  bool _goodNewsFilter = true;
  bool _badNewsFilter = true;

  RangeValues _goodNewsRange = const RangeValues(2.5, 5.0);
  RangeValues _badNewsRange = const RangeValues(1.0, 3.5);

  final Color navyColor = const Color(0xFF2B3A66);
  final Color sliderInactiveColor = const Color(0xFFACB0BF);

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    try {
      final settings = await _apiService.fetchNotificationSettings();
      setState(() {
        _holdingsFilter = settings['ownStock'];
        _watchlistFilter = settings['interestStock'];
        _goodNewsFilter = settings['goodNews'];
        _badNewsFilter = settings['badNews'];
        _neutralFilter = settings['neutralNews'];

        _goodNewsRange = RangeValues(
          (settings['goodSensitivity1'] as num).toDouble() / 20.0,
          (settings['goodSensitivity2'] as num).toDouble() / 20.0,
        );
        _badNewsRange = RangeValues(
          (settings['badSensitivity1'] as num).toDouble() / 20.0,
          (settings['badSensitivity2'] as num).toDouble() / 20.0,
        );
      });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('설정 로딩 실패: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSettings() async {
    final success = await _apiService.updateNotificationSettings(
      ownStock: _holdingsFilter,
      interestStock: _watchlistFilter,
      goodNews: _goodNewsFilter,
      badNews: _badNewsFilter,
      neutralNews: _neutralFilter,

      goodSensitivity1: _goodNewsRange.start * 20.0,
      goodSensitivity2: _goodNewsRange.end * 20.0,
      badSensitivity1: _badNewsRange.start * 20.0,
      badSensitivity2: _badNewsRange.end * 20.0,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(success ? '설정이 저장되었습니다.' : '설정 저장에 실패했습니다.')),
      );
      if (success) Navigator.pop(context);
    }
  }

  Future<void> _resetFilters() async {
    final success = await _apiService.resetNotificationSettings();
    if (success) {
      await _loadSettings();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('설정이 초기화되었습니다.')));
    } else {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('초기화에 실패했습니다.')));
    }
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
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
            min: 0.0,
            max: 5.0,
            divisions: 500, // (5.0 - 0.0) / 0.01 = 500
            labels: RangeLabels(
              values.start.toStringAsFixed(2),
              values.end.toStringAsFixed(2),
            ),
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
                    controller: TextEditingController(text: values.start.toStringAsFixed(2)),
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
                    controller: TextEditingController(text: values.end.toStringAsFixed(2)),
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