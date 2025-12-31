import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/usage_service.dart';
import '../providers/settings_provider.dart';
import '../widgets/usage_list_tile.dart';
import '../widgets/permission_card.dart';

import 'journal_screen.dart';
import 'settings_screen.dart';
import 'analytics_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<String> _pageTitles = ['Beranda', 'Jurnal Mood', 'Analytics'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final usageService = Provider.of<UsageService>(context, listen: false);
      final settingsProvider = Provider.of<SettingsProvider>(
        context,
        listen: false,
      );

      usageService.checkAndRequestPermission().then((_) {
        usageService.checkDailyLimit(settingsProvider);
      });
    });
  }

  // List of main pages
  List<Widget> _getPages() {
    return [
      _buildHomeContent(), // Index 0
      const JournalScreen(), // Index 1
      const AnalyticsScreen(), // Index 2
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.appBarTheme.foregroundColor;

    // DefaultTabController wraps the Scaffold to coordinate AppBar Tabs & Body View
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(_pageTitles[_selectedIndex]),
          actions: [
            if (_selectedIndex == 0)
              Consumer<UsageService>(
                builder: (context, usageService, child) {
                  return IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: usageService.isLoading
                        ? null
                        : () async {
                            await usageService.fetchUsageData();
                          },
                  );
                },
              ),

            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const SettingsScreen(),
                  ),
                );
              },
            ),
          ],
          // DYNAMIC TAB BAR: Only appears on Analytics Page
          bottom: _selectedIndex == 2
              ? TabBar(
                  indicatorColor: primaryColor,
                  labelColor: primaryColor,
                  labelStyle: const TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.bold,
                  ),
                  unselectedLabelColor: primaryColor?.withValues(alpha: 0.5),
                  dividerColor:
                      Colors.transparent, // Remove double border effect
                  tabs: const [
                    Tab(text: 'Penggunaan App'),
                    Tab(text: 'Mood Tracking'),
                  ],
                )
              : null,
        ),

        body: _getPages()[_selectedIndex],

        // Material You Navigation Bar
        bottomNavigationBar: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: _onItemTapped,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Beranda',
            ),
            NavigationDestination(
              icon: Icon(Icons.book_outlined),
              selectedIcon: Icon(Icons.book),
              label: 'Jurnal',
            ),
            NavigationDestination(
              icon: Icon(Icons.bar_chart_outlined),
              selectedIcon: Icon(Icons.bar_chart),
              label: 'Analytics',
            ),
          ],
        ),
      ),
    );
  }

  // --- CONTENT FOR "BERANDA" ---
  Widget _buildHomeContent() {
    return Consumer2<UsageService, SettingsProvider>(
      builder: (context, usageService, settingsProvider, child) {
        if (usageService.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!usageService.hasPermission) {
          return PermissionDeniedWidget(service: usageService);
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTotalTimeCard(usageService.totalTimeUsedToday),

            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Text(
                'Aplikasi dengan Durasi > 5 Menit',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
            ),

            Expanded(
              child: usageService.appUsages.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Text(
                          "Tidak ada aplikasi yang digunakan lebih dari 5 menit hari ini.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Theme.of(context).textTheme.bodyMedium?.color
                                ?.withValues(alpha: 0.6),
                          ),
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: usageService.appUsages.length,
                      itemBuilder: (context, index) {
                        final usage = usageService.appUsages[index];
                        return UsageListTile(
                          usage: usage,
                          formatDuration: _formatDuration,
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  String _formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      return "${duration.inHours}j ${duration.inMinutes.remainder(60)}m";
    }
    if (duration.inMinutes > 0) {
      return "${duration.inMinutes}m ${duration.inSeconds.remainder(60)}d";
    }
    return "${duration.inSeconds}d";
  }

  Widget _buildTotalTimeCard(Duration totalTime) {
    return Consumer<SettingsProvider>(
      builder: (context, settingsProvider, child) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;

        final progress = settingsProvider.getDailyLimitProgress(totalTime);
        final hasExceeded = settingsProvider.hasExceededDailyLimit(totalTime);

        // Dynamic colors matching new Theme logic
        final cardColor = isDark
            ? const Color(0xFF1E1E1E)
            : theme.colorScheme.primary.withValues(alpha: 0.05);

        final textColor = theme.colorScheme.primary;

        return Card(
          margin: const EdgeInsets.all(16.0),
          color: cardColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.withValues(alpha: 0.1)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Waktu Layar Hari Ini',
                  style: TextStyle(
                    fontSize: 16,
                    color: textColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _formatDuration(totalTime),
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: hasExceeded ? Colors.red : textColor,
                    fontFamily: 'Inter',
                  ),
                ),
                const SizedBox(height: 12),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Target: ${settingsProvider.dailyLimitHours}h',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.textTheme.bodyMedium?.color,
                          ),
                        ),
                        Text(
                          '${(progress * 100).toStringAsFixed(0)}%',
                          style: TextStyle(
                            fontSize: 12,
                            color: hasExceeded
                                ? Colors.red
                                : theme.textTheme.bodyMedium?.color,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: progress,
                      borderRadius: BorderRadius.circular(4),
                      backgroundColor: Colors.grey.withValues(alpha: 0.2),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        hasExceeded ? Colors.red : textColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
