import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  // Initialize notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Initialize timezone
    tz_data.initializeTimeZones();

    // Android initialization
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _isInitialized = true;
    if (kDebugMode) {
      print('NotificationService initialized');
    }
  }

  void _onNotificationTapped(NotificationResponse notificationResponse) {
    final String? payload = notificationResponse.payload;
    if (payload != null) {
      if (kDebugMode) {
        print('Notification payload: $payload');
      }
    }
  }

  // Schedule a reminder notification
  Future<void> scheduleReminder({
    required String title,
    required String body,
    required DateTime scheduledTime,
    int id = 0,
  }) async {
    if (!_isInitialized) await initialize();

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'reminder_channel',
      'Reminder Notifications',
      channelDescription: 'Pengingat istirahat dan batas waktu layar',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails();

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await _flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledTime, tz.local),
      platformChannelSpecifics,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'reminder_$id',
    );

    if (kDebugMode) {
      print('Reminder scheduled: $title at $scheduledTime');
    }
  }

  // Send an immediate notification
  Future<void> showNotification({
    required String title,
    required String body,
    int id = 0,
    String? payload,
  }) async {
    if (!_isInitialized) await initialize();

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'instant_channel',
      'Instant Notifications',
      channelDescription: 'Notifikasi langsung dari aplikasi',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails();

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await _flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      platformChannelSpecifics,
      payload: payload ?? 'instant_$id',
    );

    if (kDebugMode) {
      print('Notification shown: $title - $body');
    }
  }

  // Schedule periodic break reminders
  Future<void> scheduleBreakReminders({
    required int intervalMinutes,
    required bool enabled,
  }) async {
    if (!enabled) {
      await cancelAllNotifications();
      return;
    }

    await cancelAllNotifications();

    // Schedule reminders for the next 24 hours
    final now = DateTime.now();
    for (int i = 1; i <= 24; i++) {
      final reminderTime = now.add(Duration(minutes: intervalMinutes * i));
      
      await scheduleReminder(
        title: '🕐 Waktunya Istirahat!',
        body: 'Anda sudah menggunakan perangkat selama ${intervalMinutes * i} menit. Istirahatkan mata Anda sejenak.',
        scheduledTime: reminderTime,
        id: i,
      );
    }
  }

  // Show limit exceeded notification
  Future<void> showLimitExceededNotification(Duration usedTime, Duration limit) async {
    await showNotification(
      title: '⚠️ Batas Waktu Layar Terlampaui',
      body: 'Anda telah menggunakan perangkat selama ${_formatDuration(usedTime)} dari batas ${_formatDuration(limit)}',
      id: 999,
      payload: 'limit_exceeded',
    );
  }

  // Cancel all notifications
  Future<void> cancelAllNotifications() async {
    if (!_isInitialized) await initialize();

    await _flutterLocalNotificationsPlugin.cancelAll();

    if (kDebugMode) {
      print('All notifications cancelled');
    }
  }

  // Cancel specific notification
  Future<void> cancelNotification(int id) async {
    if (!_isInitialized) await initialize();

    await _flutterLocalNotificationsPlugin.cancel(id);
  }

  // Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    if (!_isInitialized) await initialize();

    final bool? result = await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.areNotificationsEnabled();

    return result ?? false;
  }

  // Request notification permissions
  Future<bool> requestPermissions() async {
    if (!_isInitialized) await initialize();

    final bool? result = await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );

    return result ?? await areNotificationsEnabled();
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