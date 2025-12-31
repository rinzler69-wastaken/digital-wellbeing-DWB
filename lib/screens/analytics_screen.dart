import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/mood_provider.dart';
import '../services/usage_service.dart';
import '../widgets/custom_chart.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  // State to track the selected chart type
  String _selectedChartType = 'bar';

  @override
  Widget build(BuildContext context) {
    return TabBarView(
      children: [_buildUsageAnalytics(context), _buildMoodAnalytics(context)],
    );
  }

  Widget _buildUsageAnalytics(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Consumer<UsageService>(
      builder: (context, usageService, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle(context, 'Penggunaan Hari Ini'),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: _buildSummaryCard(
                      context: context,
                      title: 'Total Waktu',
                      value: _formatDuration(usageService.totalTimeUsedToday),
                      icon: Icons.access_time,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSummaryCard(
                      context: context,
                      title: 'Aplikasi Aktif',
                      value: '${usageService.appUsages.length}',
                      icon: Icons.apps,
                      color: colorScheme.secondary,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),
              _buildSectionTitle(context, 'Distribusi Penggunaan'),
              const SizedBox(height: 16),

              // --- TOGGLE BUTTONS RESTORED ---
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          setState(() => _selectedChartType = 'bar'),
                      icon: const Icon(Icons.bar_chart),
                      label: const Text('Bar Chart'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _selectedChartType == 'bar'
                            ? colorScheme.primary
                            : colorScheme.surface,
                        foregroundColor: _selectedChartType == 'bar'
                            ? colorScheme.onPrimary
                            : colorScheme.primary,
                        side: BorderSide(color: colorScheme.primary),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          setState(() => _selectedChartType = 'pie'),
                      icon: const Icon(Icons.pie_chart),
                      label: const Text('Pie Chart'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _selectedChartType == 'pie'
                            ? colorScheme.primary
                            : colorScheme.surface,
                        foregroundColor: _selectedChartType == 'pie'
                            ? colorScheme.onPrimary
                            : colorScheme.primary,
                        side: BorderSide(color: colorScheme.primary),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.withValues(alpha: 0.1)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedChartType == 'bar'
                            ? 'Top Aplikasi (Bar Chart)'
                            : 'Distribusi (Pie Chart)',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Pass the selected chart type here
                      UsageChart(
                        usageData: usageService.appUsages,
                        chartType: _selectedChartType,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.withValues(alpha: 0.1)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Detail Penggunaan',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ...usageService.appUsages.take(10).map((usage) {
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundColor: colorScheme.primary.withValues(
                              alpha: 0.1,
                            ),
                            child: Icon(Icons.apps, color: colorScheme.primary),
                          ),
                          title: Text(
                            usage.appName,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(usage.packageName),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                _formatDuration(usage.totalTimeUsed),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.primary,
                                ),
                              ),
                              Text(
                                '${((usage.totalTimeUsed.inMinutes / (usageService.totalTimeUsedToday.inMinutes == 0 ? 1 : usageService.totalTimeUsedToday.inMinutes)) * 100).toStringAsFixed(1)}%',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: theme.textTheme.bodySmall?.color
                                      ?.withValues(alpha: 0.6),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMoodAnalytics(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final secondaryColor = theme.colorScheme.secondary;

    return Consumer<MoodProvider>(
      builder: (context, moodProvider, child) {
        if (moodProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final moodData = _processMoodDataForChart(moodProvider.moodEntries);
        final moodStats = _calculateMoodStats(moodProvider.moodEntries);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle(context, 'Mood Overview'),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: _buildSummaryCard(
                      context: context,
                      title: 'Total Entries',
                      value: '${moodProvider.moodEntries.length}',
                      icon: Icons.edit_note,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSummaryCard(
                      context: context,
                      title: 'Mood Dominan',
                      value: moodStats['dominant'] ?? 'Netral',
                      icon: Icons.mood,
                      color: secondaryColor,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),
              _buildSectionTitle(context, 'Mood Trend (7 Hari Terakhir)'),
              const SizedBox(height: 16),

              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.withValues(alpha: 0.1)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Grafik Mood Harian',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      MoodChart(moodData: moodData),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.withValues(alpha: 0.1)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Distribusi Mood',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ...moodStats.entries
                          .where((entry) => entry.key != 'dominant')
                          .map((entry) {
                            final percentage = entry.value as double;
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  Expanded(flex: 2, child: Text(entry.key)),
                                  Expanded(
                                    flex: 3,
                                    child: LinearProgressIndicator(
                                      value: percentage / 100,
                                      backgroundColor: Colors.grey.shade300,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        primaryColor,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      '${percentage.toStringAsFixed(1)}%',
                                      textAlign: TextAlign.end,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        fontFamily: 'Inter',
      ),
    );
  }

  Widget _buildSummaryCard({
    required BuildContext context,
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(
                        context,
                      ).textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
                fontFamily: 'Inter',
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _processMoodDataForChart(
    List<dynamic> moodEntries,
  ) {
    final now = DateTime.now();
    final last7Days = List.generate(
      7,
      (index) => now.subtract(Duration(days: 6 - index)),
    );

    return last7Days.map((date) {
      final dayEntries = moodEntries.where((entry) {
        final entryDate = (entry as dynamic).timestamp as DateTime;
        return entryDate.year == date.year &&
            entryDate.month == date.month &&
            entryDate.day == date.day;
      }).toList();

      String dominantMood = 'Netral';
      if (dayEntries.isNotEmpty) {
        dominantMood = (dayEntries.last as dynamic).mood;
      }

      return {'date': date, 'mood': dominantMood, 'count': dayEntries.length};
    }).toList();
  }

  Map<String, dynamic> _calculateMoodStats(List<dynamic> moodEntries) {
    if (moodEntries.isEmpty) {
      return {
        'dominant': 'Netral',
        'Sangat Senang': 0.0,
        'Senang': 0.0,
        'Netral': 0.0,
        'Sedih': 0.0,
        'Sangat Sedih': 0.0,
      };
    }

    final moodCounts = <String, int>{};
    for (final entry in moodEntries) {
      final mood = (entry as dynamic).mood as String;
      moodCounts[mood] = (moodCounts[mood] ?? 0) + 1;
    }

    final total = moodEntries.length;
    final moodPercentages = <String, double>{};
    String dominantMood = 'Netral';
    int maxCount = 0;

    for (final entry in moodCounts.entries) {
      final percentage = (entry.value / total) * 100;
      moodPercentages[entry.key] = percentage;

      if (entry.value > maxCount) {
        maxCount = entry.value;
        dominantMood = entry.key;
      }
    }

    return {'dominant': dominantMood, ...moodPercentages};
  }

  String _formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      return "${duration.inHours}j ${duration.inMinutes.remainder(60)}m";
    }
    if (duration.inMinutes > 0) {
      return "${duration.inMinutes}m";
    }
    return "${duration.inSeconds}d";
  }
}
