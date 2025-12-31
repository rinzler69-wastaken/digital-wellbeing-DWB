import 'package:flutter/material.dart';
import 'package:usage_stats/usage_stats.dart';
import '../models/app_usage_model.dart';
import '../providers/settings_provider.dart';
import 'notification_service.dart';

class UsageService with ChangeNotifier {
  List<AppUsageModel> _appUsages = [];
  bool _hasPermission = false;
  bool _isLoading = false;
  bool _hasShownLimitWarning = false;

  List<AppUsageModel> get appUsages => _appUsages;
  bool get hasPermission => _hasPermission;
  bool get isLoading => _isLoading;

  Duration get totalTimeUsedToday {
    return _appUsages.fold(
      Duration.zero,
      (sum, usage) => sum + usage.totalTimeUsed,
    );
  }

  Future<void> checkAndRequestPermission() async {
    _isLoading = true;
    notifyListeners();

    try {
      _hasPermission = await UsageStats.checkUsagePermission() ?? false;

      if (!_hasPermission) {
        await UsageStats.grantUsagePermission();
        await Future.delayed(const Duration(seconds: 2));
        _hasPermission = await UsageStats.checkUsagePermission() ?? false;
      }

      if (_hasPermission) {
        await fetchUsageData();
      }
    } catch (e) {
      debugPrint("Error in checkAndRequestPermission: $e");
      _hasPermission = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchUsageData() async {
    if (!_hasPermission) {
      _isLoading = false;
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      DateTime now = DateTime.now();
      DateTime startDate = DateTime(now.year, now.month, now.day);

      List<UsageInfo> usageStatsList = await UsageStats.queryUsageStats(
        startDate,
        now,
      );

      List<AppUsageModel> result = [];

      for (var info in usageStatsList) {
        if (info.packageName == null) continue;
        if (_isIgnoredSystemApp(info.packageName!)) continue;

        int totalTime = 0;
        if (info.totalTimeInForeground != null) {
          if (info.totalTimeInForeground is String) {
            totalTime = int.tryParse(info.totalTimeInForeground as String) ?? 0;
          } else if (info.totalTimeInForeground is num) {
            totalTime = (info.totalTimeInForeground as num).toInt();
          }
        }

        // REFINED LOGIC: Only count apps used for > 5 minutes (300,000 ms)
        if (totalTime > 300000) {
          result.add(
            AppUsageModel(
              appName: _getAppName(info.packageName!),
              packageName: info.packageName!,
              totalTimeUsed: Duration(milliseconds: totalTime),
            ),
          );
        }
      }

      _appUsages = result;
      _appUsages.sort((a, b) => b.totalTimeUsed.compareTo(a.totalTimeUsed));
    } catch (e) {
      debugPrint("Error fetching usage data: $e");
      _appUsages = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  bool _isIgnoredSystemApp(String packageName) {
    const List<String> ignoredExact = [
      'com.android.systemui',
      'com.google.android.gms',
      'com.android.vending',
      'com.android.pixel.launcher',
      'com.miui.home',
      'android',
    ];

    if (ignoredExact.contains(packageName)) return true;

    if (packageName.startsWith('com.android.') ||
        packageName.startsWith('com.google.android.')) {
      const List<String> whitelist = [
        'com.android.chrome',
        'com.google.android.youtube',
        'com.google.android.gm',
        'com.google.android.apps.maps',
        'com.google.android.apps.photos',
      ];

      if (!whitelist.contains(packageName)) {
        return true;
      }
    }

    return false;
  }

  Future<void> checkDailyLimit(SettingsProvider settingsProvider) async {
    final totalTime = totalTimeUsedToday;
    final hasExceeded = settingsProvider.hasExceededDailyLimit(totalTime);

    if (hasExceeded &&
        !_hasShownLimitWarning &&
        settingsProvider.notificationsEnabled) {
      await NotificationService().showLimitExceededNotification(
        totalTime,
        Duration(hours: settingsProvider.dailyLimitHours),
      );
      _hasShownLimitWarning = true;
    }

    if (!hasExceeded) {
      _hasShownLimitWarning = false;
    }
  }

  void resetDailyWarning() {
    _hasShownLimitWarning = false;
  }

  String _getAppName(String packageName) {
    switch (packageName) {
      case 'com.android.chrome':
        return 'Chrome';
      case 'com.whatsapp':
        return 'WhatsApp';
      case 'com.instagram.android':
        return 'Instagram';
      case 'com.facebook.katana':
        return 'Facebook';
      case 'com.twitter.android':
        return 'X (Twitter)';
      case 'com.google.android.youtube':
        return 'YouTube';
      case 'com.zhiliaoapp.musically':
      case 'com.ss.android.ugc.trill':
        return 'TikTok';
      case 'com.google.android.gm':
        return 'Gmail';
      case 'com.google.android.apps.maps':
        return 'Maps';
      case 'com.spotify.music':
        return 'Spotify';
      case 'com.netflix.mediaclient':
        return 'Netflix';
      case 'com.microsoft.teams':
        return 'Teams';
      case 'com.discord':
        return 'Discord';
      default:
        List<String> parts = packageName.split('.');
        String name = parts.isNotEmpty ? parts.last : packageName;
        if (name.isNotEmpty) {
          return name[0].toUpperCase() + name.substring(1);
        }
        return name;
    }
  }
}
