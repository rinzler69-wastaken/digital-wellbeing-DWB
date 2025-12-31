import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/app_usage_model.dart';

class UsageChart extends StatelessWidget {
  final List<AppUsageModel> usageData;
  final String chartType; // 'bar' or 'pie'

  const UsageChart({
    super.key,
    required this.usageData,
    this.chartType = 'bar',
  });

  @override
  Widget build(BuildContext context) {
    if (usageData.isEmpty) {
      return Center(
        child: Text(
          'Tidak ada data untuk ditampilkan',
          style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
        ),
      );
    }

    return Container(
      height: 300,
      padding: const EdgeInsets.all(16),
      child: chartType == 'pie'
          ? _buildPieChart(context)
          : _buildBarChart(context),
    );
  }

  Widget _buildBarChart(BuildContext context) {
    final topApps = usageData.take(5).toList();
    final colorScheme = Theme.of(context).colorScheme;
    final textStyle = TextStyle(
      color: Theme.of(context).textTheme.bodySmall?.color,
      fontSize: 10,
    );

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: topApps.isNotEmpty
            ? topApps.first.totalTimeUsed.inMinutes.toDouble() * 1.2
            : 100,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            // Fixed: Removed getTooltipColor to prevent version conflicts
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final appName = topApps[group.x.toInt()].appName;
              final duration = topApps[group.x.toInt()].totalTimeUsed;
              return BarTooltipItem(
                '$appName\n${_formatDuration(duration)}',
                TextStyle(color: colorScheme.onPrimary),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= topApps.length) return const Text('');
                final appName = topApps[value.toInt()].appName;
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    appName.length > 8
                        ? '${appName.substring(0, 8)}...'
                        : appName,
                    style: textStyle,
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text('${value.toInt()}m', style: textStyle);
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: topApps.asMap().entries.map((entry) {
          return BarChartGroupData(
            x: entry.key,
            barRods: [
              BarChartRodData(
                toY: entry.value.totalTimeUsed.inMinutes.toDouble(),
                color: colorScheme.primary,
                width: 20,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPieChart(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final totalMinutes = usageData.fold<int>(
      0,
      (sum, item) => sum + item.totalTimeUsed.inMinutes,
    );

    if (totalMinutes == 0) {
      return const Center(child: Text('Tidak ada data penggunaan'));
    }

    final topApps = usageData.take(4).toList();
    final otherApps = usageData.skip(4).toList();
    final otherMinutes = otherApps.fold<int>(
      0,
      (sum, item) => sum + item.totalTimeUsed.inMinutes,
    );

    // Dynamic Palette
    final colors = [
      colorScheme.primary,
      colorScheme.secondary,
      colorScheme.tertiary,
      colorScheme.error,
      colorScheme.surfaceContainerHighest,
    ];

    List<PieChartSectionData> sections = [];

    for (int i = 0; i < topApps.length; i++) {
      final minutes = topApps[i].totalTimeUsed.inMinutes;
      final percentage = (minutes / totalMinutes * 100);

      sections.add(
        PieChartSectionData(
          color: colors[i % colors.length],
          value: minutes.toDouble(),
          title: '${percentage.toStringAsFixed(1)}%',
          radius: 60,
          titleStyle: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: colorScheme.onPrimary,
          ),
        ),
      );
    }

    if (otherMinutes > 0) {
      final percentage = (otherMinutes / totalMinutes * 100);
      sections.add(
        PieChartSectionData(
          color: colors.last,
          value: otherMinutes.toDouble(),
          title: '${percentage.toStringAsFixed(1)}%',
          radius: 60,
          titleStyle: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: PieChart(
            PieChartData(
              sections: sections,
              centerSpaceRadius: 50,
              sectionsSpace: 2,
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildLegend(context, topApps, otherMinutes > 0, colors),
      ],
    );
  }

  Widget _buildLegend(
    BuildContext context,
    List<AppUsageModel> topApps,
    bool hasOthers,
    List<Color> colors,
  ) {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: [
        ...topApps.asMap().entries.map((entry) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 12,
                height: 12,
                color: colors[entry.key % colors.length],
              ),
              const SizedBox(width: 4),
              Text(
                entry.value.appName.length > 10
                    ? '${entry.value.appName.substring(0, 10)}...'
                    : entry.value.appName,
                style: const TextStyle(fontSize: 12),
              ),
            ],
          );
        }),
        if (hasOthers)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 12, height: 12, color: colors.last),
              const SizedBox(width: 4),
              const Text('Lainnya', style: TextStyle(fontSize: 12)),
            ],
          ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      return "${duration.inHours}j ${duration.inMinutes.remainder(60)}m";
    }
    return "${duration.inMinutes}m";
  }
}

class MoodChart extends StatelessWidget {
  final List<Map<String, dynamic>> moodData;

  const MoodChart({super.key, required this.moodData});

  @override
  Widget build(BuildContext context) {
    if (moodData.isEmpty) {
      return Center(
        child: Text(
          'Tidak ada data mood untuk ditampilkan',
          style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
        ),
      );
    }

    final primaryColor = Theme.of(context).colorScheme.primary;

    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: true),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < moodData.length) {
                    final date = moodData[index]['date'] as DateTime;
                    return Text(
                      '${date.day}/${date.month}',
                      style: const TextStyle(fontSize: 10),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  const moods = [
                    'Sangat Sedih',
                    'Sedih',
                    'Netral',
                    'Senang',
                    'Sangat Senang',
                  ];
                  final index = value.toInt();
                  if (index >= 0 && index < moods.length) {
                    return Text(
                      moods[index].substring(0, 4),
                      style: const TextStyle(fontSize: 8),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          borderData: FlBorderData(show: true),
          lineBarsData: [
            LineChartBarData(
              spots: moodData.asMap().entries.map((entry) {
                final moodValue = _moodToValue(entry.value['mood'] as String);
                return FlSpot(entry.key.toDouble(), moodValue.toDouble());
              }).toList(),
              isCurved: true,
              color: primaryColor,
              barWidth: 3,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) =>
                    FlDotCirclePainter(color: primaryColor),
              ),
              belowBarData: BarAreaData(
                show: true,
                color: primaryColor.withValues(
                  alpha: 0.2,
                ), // Fixed deprecated opacity
              ),
            ),
          ],
          minY: 0,
          maxY: 4,
        ),
      ),
    );
  }

  int _moodToValue(String mood) {
    switch (mood) {
      case 'Sangat Sedih':
        return 0;
      case 'Sedih':
        return 1;
      case 'Netral':
        return 2;
      case 'Senang':
        return 3;
      case 'Sangat Senang':
        return 4;
      default:
        return 2;
    }
  }
}
