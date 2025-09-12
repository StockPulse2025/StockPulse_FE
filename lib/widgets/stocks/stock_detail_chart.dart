import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class StockDetailChart extends StatelessWidget {
  final List<Map<String, dynamic>> candleData;
  final Function(DateTime date) onCandleTap;
  final double candleWidth;
  final double xAxisInterval;
  final String selectedPeriod;

  const StockDetailChart({
    super.key,
    required this.candleData,
    required this.onCandleTap,
    required this.candleWidth,
    required this.xAxisInterval,
    required this.selectedPeriod,
  });

  @override
  Widget build(BuildContext context) {
    if (candleData.isEmpty) {
      return const SizedBox(height: 250, child: Center(child: Text("데이터가 없습니다.")));
    }

    final double maxY = candleData.map((d) => d['high'] as double).reduce((a, b) => a > b ? a : b) * 1.02;
    final double minY = candleData.map((d) => d['low'] as double).reduce((a, b) => a < b ? a : b) * 0.98;

    return SizedBox(
      height: 250,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        reverse: true,
        child: Container(
          width: candleData.length * (candleWidth + 8),
          child: BarChart(
            BarChartData(
              maxY: maxY,
              minY: minY,
              alignment: BarChartAlignment.spaceBetween,
              barGroups: List.generate(candleData.length, (index) {
                final data = candleData[index];
                final bool isRising = data['close']! > data['open']!;
                return BarChartGroupData(
                  x: index,
                  barRods: [
                    BarChartRodData(
                      toY: data['high']!,
                      fromY: data['low']!,
                      color: Colors.transparent,
                      width: candleWidth * 0.2,
                      rodStackItems: [
                        BarChartRodStackItem(data['low']!, isRising ? data['open']! : data['close']!, Colors.transparent),
                        BarChartRodStackItem(isRising ? data['open']! : data['close']!, isRising ? data['close']! : data['open']!, isRising ? Colors.red : Colors.blue),
                        BarChartRodStackItem(isRising ? data['close']! : data['open']!, data['high']!, Colors.transparent),
                      ],
                      borderRadius: BorderRadius.zero,
                    ),
                  ],
                  barsSpace: 4,
                );
              }),
              titlesData: FlTitlesData(
                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 50,
                    getTitlesWidget: (value, meta) {
                      if (value == meta.max || value == meta.min) return const Text('');
                      return Text('${(value / 1000).toStringAsFixed(0)}k', style: const TextStyle(color: Colors.grey, fontSize: 10));
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    interval: xAxisInterval,
                    getTitlesWidget: (value, meta) {
                      int index = value.toInt();
                      if (index >= 0 && index < candleData.length) {
                        DateTime date = candleData[index]['date'];
                        String format = selectedPeriod == '1개월' ? 'yy/MM' : 'MM/dd';
                        return Text(DateFormat(format).format(date), style: const TextStyle(color: Colors.grey, fontSize: 10));
                      }
                      return const Text('');
                    },
                  ),
                ),
              ),
              gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (value) => const FlLine(color: Color(0xffe7e8ec), strokeWidth: 1)),
              borderData: FlBorderData(show: true, border: Border.all(color: const Color(0xffe7e8ec), width: 1)),
              barTouchData: BarTouchData(
                touchCallback: (event, response) {
                  if (event is FlTapUpEvent && response != null && response.spot != null) {
                    final int index = response.spot!.touchedBarGroupIndex;
                    if (index >= 0 && index < candleData.length) {
                      final DateTime selectedDate = candleData[index]['date'];
                      onCandleTap(selectedDate);
                    }
                  }
                },
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (group) => Colors.black87,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    if(group.x.toInt() >= candleData.length) return null;
                    final data = candleData[group.x.toInt()];
                    final DateTime date = data['date'];
                    final priceFormat = NumberFormat.currency(locale: 'ko_KR', symbol: '', decimalDigits: 0);

                    // --- [여기 수정!] const 키워드를 제거했습니다. ---
                    return BarTooltipItem(
                        DateFormat('yy/MM/dd').format(date),
                        const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        children: [
                          TextSpan(
                            text: '\n${priceFormat.format(data['close'])}원',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ]
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}