import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:streak/app/theme/app_tokens.dart';
import 'package:streak/core/i18n/date_labels.dart';
import 'package:streak/features/statistics/widgets/stat_kit.dart';

class WeekdayBars extends StatelessWidget {
  const WeekdayBars({
    super.key,
    required this.values,
    required this.color,
    this.height = 150,
  });

  final List<int> values;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    final labels = WeekdayLabels.narrowMonFirst(
      Localizations.localeOf(context).languageCode,
    );
    final maxV = (values.isEmpty ? 0 : values.reduce((a, b) => a > b ? a : b))
        .toDouble();
    final maxY = (maxV <= 0 ? 1.0 : maxV) * 1.2;

    return SizedBox(
      height: height,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxY,
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => context.colors.surfaceContainerHighest,
              getTooltipItem: (group, _, rod, __) => BarTooltipItem(
                '${rod.toY.round()}',
                TextStyle(
                  color: context.colors.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 26,
                getTitlesWidget: (value, _) => Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    labels[value.toInt() % 7],
                    style: TextStyle(
                      color: context.tokens.muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
          barGroups: [
            for (var i = 0; i < 7; i++)
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: values[i].toDouble(),
                    color: color,
                    width: 12,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(6),
                    ),
                    backDrawRodData: BackgroundBarChartRodData(
                      show: true,
                      toY: maxY,

                      color: context.colors.surfaceContainerHighest
                          .withValues(alpha: 0.22),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class HabitRanking extends StatefulWidget {
  const HabitRanking({super.key, required this.entries});

  final List<({String name, Color color, int count})> entries;

  @override
  State<HabitRanking> createState() => _HabitRankingState();
}

class _HabitRankingState extends State<HabitRanking>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..forward();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _step(int index) {
    final start = (index * 0.11).clamp(0.0, 0.5);
    return Curves.easeOutCubic.transform(
      ((_controller.value - start) / 0.5).clamp(0.0, 1.0),
    );
  }

  @override
  Widget build(BuildContext context) {
    final entries = widget.entries;
    if (entries.isEmpty) return const SizedBox.shrink();
    final max = entries.map((e) => e.count).reduce((a, b) => a > b ? a : b);

    return Column(
      children: [
        for (var i = 0; i < entries.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                SizedBox(
                  width: 92,
                  child: Text(
                    entries[i].name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: context.colors.onSurface,
                    ),
                  ),
                ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, box) => AnimatedBuilder(
                      animation: _controller,
                      builder: (context, _) {
                        final t = _step(i);
                        final share = max == 0 ? 0.0 : entries[i].count / max;
                        return Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            height: 10,
                            width: (box.maxWidth * share * t)
                                .clamp(4, box.maxWidth),
                            decoration: BoxDecoration(
                              color: entries[i].color,
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 34,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: AnimatedStatNumber(
                      value: '${entries[i].count}',
                      style: statNumber(context, 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
