import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/notification_service.dart';

class SettingsProvider with ChangeNotifier {
  static const String _keyDailyLimit = 'daily_limit_hours';
  static const String _keyNotificationsEnabled = 'notifications_enabled';
  static const String _keyReminderInterval = 'reminder_interval_minutes';
  static const String _keyBreakReminder = 'break_reminder_enabled';
  static const String _keyDarkMode = 'dark_mode_enabled';

  int _dailyLimitHours = 8;
  bool _notificationsEnabled = true;
  int _reminderIntervalMinutes = 60;
  bool _breakReminderEnabled = true;
  bool _darkModeEnabled = false; // Default to Light (Purple)
  bool _isLoading = false;

  // Getters
  int get dailyLimitHours => _dailyLimitHours;
  bool get notificationsEnabled => _notificationsEnabled;
  int get reminderIntervalMinutes => _reminderIntervalMinutes;
  bool get breakReminderEnabled => _breakReminderEnabled;
  bool get darkModeEnabled => _darkModeEnabled;
  bool get isLoading => _isLoading;

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      _dailyLimitHours = prefs.getInt(_keyDailyLimit) ?? 8;
      _notificationsEnabled = prefs.getBool(_keyNotificationsEnabled) ?? true;
      _reminderIntervalMinutes = prefs.getInt(_keyReminderInterval) ?? 60;
      _breakReminderEnabled = prefs.getBool(_keyBreakReminder) ?? true;
      _darkModeEnabled = prefs.getBool(_keyDarkMode) ?? false;
    } catch (e) {
      debugPrint('Error loading settings: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_keyDailyLimit, _dailyLimitHours);
      await prefs.setBool(_keyNotificationsEnabled, _notificationsEnabled);
      await prefs.setInt(_keyReminderInterval, _reminderIntervalMinutes);
      await prefs.setBool(_keyBreakReminder, _breakReminderEnabled);
      await prefs.setBool(_keyDarkMode, _darkModeEnabled);
    } catch (e) {
      debugPrint('Error saving settings: $e');
    }
  }

  Future<void> setDailyLimit(int hours) async {
    if (hours != _dailyLimitHours && hours > 0 && hours <= 24) {
      _dailyLimitHours = hours;
      await _saveSettings();
      notifyListeners();
    }
  }

  Future<void> toggleNotifications(bool enabled) async {
    if (enabled != _notificationsEnabled) {
      _notificationsEnabled = enabled;
      await _saveSettings();

      if (enabled) {
        await NotificationService().requestPermissions();
        if (_breakReminderEnabled) {
          await NotificationService().scheduleBreakReminders(
            intervalMinutes: _reminderIntervalMinutes,
            enabled: true,
          );
        }
      } else {
        await NotificationService().cancelAllNotifications();
      }
      notifyListeners();
    }
  }

  Future<void> setReminderInterval(int minutes) async {
    if (minutes != _reminderIntervalMinutes && minutes > 0) {
      _reminderIntervalMinutes = minutes;
      await _saveSettings();

      if (_notificationsEnabled && _breakReminderEnabled) {
        await NotificationService().scheduleBreakReminders(
          intervalMinutes: minutes,
          enabled: true,
        );
      }
      notifyListeners();
    }
  }

  Future<void> toggleBreakReminder(bool enabled) async {
    if (enabled != _breakReminderEnabled) {
      _breakReminderEnabled = enabled;
      await _saveSettings();

      if (_notificationsEnabled) {
        await NotificationService().scheduleBreakReminders(
          intervalMinutes: _reminderIntervalMinutes,
          enabled: enabled,
        );
      }
      notifyListeners();
    }
  }

  // This is the key function for your Theme Requirement
  Future<void> toggleDarkMode(bool enabled) async {
    if (enabled != _darkModeEnabled) {
      _darkModeEnabled = enabled;
      await _saveSettings();
      notifyListeners(); // This triggers main.dart to rebuild the MaterialApp
    }
  }

  Future<void> resetToDefaults() async {
    _dailyLimitHours = 8;
    _notificationsEnabled = true;
    _reminderIntervalMinutes = 60;
    _breakReminderEnabled = true;
    _darkModeEnabled = false;

    await _saveSettings();
    notifyListeners();
  }

  bool hasExceededDailyLimit(Duration usageTime) {
    final limitDuration = Duration(hours: _dailyLimitHours);
    return usageTime > limitDuration;
  }

  double getDailyLimitProgress(Duration usageTime) {
    final limitDuration = Duration(hours: _dailyLimitHours);
    if (limitDuration.inMinutes == 0) return 0.0;

    double progress = usageTime.inMinutes / limitDuration.inMinutes;
    return progress.clamp(0.0, 1.0);
  }
}
