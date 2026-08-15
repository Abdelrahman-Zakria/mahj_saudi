import 'dart:convert';
import 'dart:developer' as dev;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:alarm/alarm.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();
    final String timeZoneName = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZoneName));
    
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('app_icon');
        
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: DarwinInitializationSettings(),
    );
    
    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        dev.log("Notification clicked: ${details.payload}");
      },
    );

    final prefs = await SharedPreferences.getInstance();
    final bool enabled = prefs.getBool('notifications_enabled') ?? true;
    
    if (enabled) {
      final bool granted = await _requestPermissions();
      if (granted) {
        dev.log("Notifications granted, checking for welcome notification...");
        // Add a small delay to ensure system is ready after permission grant
        await Future.delayed(const Duration(seconds: 1));
        await _sendWelcomeNotificationIfNeeded(prefs);
        await _scheduleStudyReminder(prefs);
      } else {
        dev.log("Notifications NOT granted");
      }
    }
  }

  Future<void> cancelAll() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }

  Future<void> reInitialize() async {
    final prefs = await SharedPreferences.getInstance();
    final bool granted = await _requestPermissions();
    if (granted) {
      await _scheduleStudyReminder(prefs);
    }
  }

  Future<bool> _requestPermissions() async {
    try {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidImplementation != null) {
        // Request primary notification permission
        final bool? granted = await androidImplementation.requestNotificationsPermission();
        
        // Android 12+ requires explicit check/request for exact alarms
        // This will trigger the system prompt or open settings
        await androidImplementation.requestExactAlarmsPermission();
        
        return granted ?? false;
      }
      
      final bool? granted = await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
      return granted ?? false;
    } catch (e) {
      dev.log("Error requesting permissions: $e");
      return false;
    }
  }

  Future<void> _saveToHistory(String title, String body) async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString('notifications_history');
    List history = [];
    if (data != null) {
      try { history = jsonDecode(data); } catch (_) {}
    }
    history.insert(0, {
      'title': title,
      'body': body,
      'timestamp': DateTime.now().toIso8601String(),
    });
    if (history.length > 50) history.removeLast();
    await prefs.setString('notifications_history', jsonEncode(history));
  }

  Future<void> _sendWelcomeNotificationIfNeeded(SharedPreferences prefs) async {
    final bool isFirstTime = prefs.getBool('first_time_notification') ?? true;

    if (isFirstTime) {
      dev.log("Sending welcome notification for the first time...");
      const String title = 'مرحباً بك في منهجي السعودي';
      const String body = 'نتمنى لك رحلة تعليمية ممتعة وناجحة!';
      
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'welcome_channel',
        'التنبيهات العامة',
        channelDescription: 'تنبيهات الترحيب والتحديثات',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
        playSound: true,
        enableVibration: true,
        largeIcon: DrawableResourceAndroidBitmap('app_icon'),
      );
      const NotificationDetails platformChannelSpecifics =
          NotificationDetails(android: androidPlatformChannelSpecifics);

      try {
        await flutterLocalNotificationsPlugin.show(
          0,
          title,
          body,
          platformChannelSpecifics,
        );
        dev.log("Welcome notification shown successfully");
        await _saveToHistory(title, body);
        await prefs.setBool('first_time_notification', false);
      } catch (e) {
        dev.log("Error showing welcome notification: $e");
      }
    }
  }

  Future<void> _scheduleStudyReminder(SharedPreferences prefs) async {
    // Schedule a daily reminder at 4 PM
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      16, // 4 PM
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    const String title = 'هل أنت مستعد للمذاكرة؟ 📚';
    const String body = 'حان وقت التقدم في دروسك! افتح التطبيق الآن وتابع رحلتك التعليمية الممتعة.';

    try {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        999,
        title,
        body,
        scheduledDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'daily_reminder_channel_v4',
            'تذكير المذاكرة اليومي',
            channelDescription: 'تذكير يومي للمراجعة والمذاكرة لزيادة التحصيل الدراسي',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
            largeIcon: DrawableResourceAndroidBitmap('app_icon'),
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time, // This makes it repeat every 24 hours
      );
      dev.log("Daily study reminder scheduled for $scheduledDate (Repeating)");
    } catch (e) {
      dev.log("Error scheduling daily reminder: $e");
    }
  }

  Future<void> scheduleAlarmNotifications({
    required int id,
    required String title,
    required DateTime start,
    required DateTime end,
  }) async {
    try {
      final now = DateTime.now();

      // 1. Schedule Start Notification (Only if in future)
      if (start.isAfter(now)) {
        final tzStart = tz.TZDateTime.from(start, tz.local);
        dev.log("Scheduling START notification $id for: $tzStart");
        
        await flutterLocalNotificationsPlugin.zonedSchedule(
          id,
          'بدأ وقت المذاكرة: $title',
          'حان الوقت للبدء في جلستك الدراسية. بالتوفيق!',
          tzStart,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'study_timer_channel_final',
              'منبهات المذاكرة',
              channelDescription: 'منبهات هامة لبدء وانتهاء جلسات المذاكرة',
              importance: Importance.max,
              priority: Priority.high,
              fullScreenIntent: true,
              category: AndroidNotificationCategory.alarm,
              visibility: NotificationVisibility.public,
              playSound: true,
              enableVibration: true,
              largeIcon: DrawableResourceAndroidBitmap('app_icon'),
            ),
            iOS: DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
              interruptionLevel: InterruptionLevel.critical,
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
        await _saveToHistory('بدء المذاكرة: $title', 'بدأت الجلسة الدراسية بنجاح.');
      }

      // 2. Schedule End Notification (Only if in future)
      if (end.isAfter(now)) {
        final tzEnd = tz.TZDateTime.from(end, tz.local);
        dev.log("Scheduling END notification ${id + 10000} for: $tzEnd");

        await flutterLocalNotificationsPlugin.zonedSchedule(
          id + 10000, // Unique ID for end notification
          'انتهى وقت المذاكرة: $title',
          'لقد أتممت جلستك الدراسية. خذ قسطاً من الراحة!',
          tzEnd,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'study_timer_channel_final',
              'منبهات المذاكرة',
              channelDescription: 'منبهات هامة لبدء وانتهاء جلسات المذاكرة',
              importance: Importance.max,
              priority: Priority.high,
              fullScreenIntent: true,
              category: AndroidNotificationCategory.alarm,
              visibility: NotificationVisibility.public,
              playSound: true,
              enableVibration: true,
              largeIcon: DrawableResourceAndroidBitmap('app_icon'),
            ),
            iOS: DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
              interruptionLevel: InterruptionLevel.critical,
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
        await _saveToHistory('انتهاء المذاكرة: $title', 'انتهت الجلسة الدراسية بنجاح.');
      }

      dev.log("Dual notifications check complete for $title");
    } catch (e) {
      dev.log("Error scheduling dual notifications for $title: $e");
    }
  }

  Future<void> scheduleSystemAlarm({
    required int id,
    required DateTime time,
    required String title,
    required String body,
  }) async {
    final alarmSettings = AlarmSettings(
      id: id,
      dateTime: time,
      assetAudioPath: 'assets/alarm.mp3',
      loopAudio: false, // Changed to false to play only once
      vibrate: true,
      volume: 0.8,
      fadeDuration: 3.0,
      notificationSettings: NotificationSettings(
        title: title,
        body: body,
      ),
    );

    await Alarm.set(alarmSettings: alarmSettings);
    dev.log("System alarm $id scheduled for $time");
  }

  Future<void> stopAlarm(int id) async {
    await Alarm.stop(id);
  }

  Future<void> cancelAlarm(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id);
    await flutterLocalNotificationsPlugin.cancel(id + 10000);
  }
}
