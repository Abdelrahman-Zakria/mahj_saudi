import 'dart:convert';
import 'dart:io';
import 'dart:developer' as dev;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart' as fcm;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:alarm/alarm.dart';
import 'package:flutter/material.dart';
import '../../main.dart';
import '../../features/home/presentation/screens/notifications/notifications_page.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();
    final String timeZoneName = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZoneName));
    
    // FCM Initialization
    await _initFirebaseMessaging();
    
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('app_icon');
        
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      ),
    );
    
    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        dev.log("Notification clicked: ${details.payload}");
        _navigateToNotifications();
      },
    );

    // Create Notification Channels for Android
    if (Platform.isAndroid) {
      await _createNotificationChannels();
    }

    // Check if app was opened from a notification when terminated (Local)
    final NotificationAppLaunchDetails? notificationAppLaunchDetails =
        await flutterLocalNotificationsPlugin.getNotificationAppLaunchDetails();
    if (notificationAppLaunchDetails?.didNotificationLaunchApp ?? false) {
      _navigateToNotifications();
    }

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

  void _navigateToNotifications() {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (navigatorKey.currentState != null) {
        navigatorKey.currentState!.push(
          MaterialPageRoute(builder: (_) => const NotificationsPage()),
        );
      }
    });
  }

  Future<void> _createNotificationChannels() async {
    const List<AndroidNotificationChannel> channels = [
      AndroidNotificationChannel(
        'fcm_foreground_channel',
        'إشعارات عامة',
        description: 'إشعارات مستلمة أثناء استخدام التطبيق',
        importance: Importance.max,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('arabian_notification'),
      ),
      AndroidNotificationChannel(
        'welcome_channel',
        'التنبيهات العامة',
        description: 'تنبيهات الترحيب والتحديثات',
        importance: Importance.max,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('arabian_notification'),
      ),
      AndroidNotificationChannel(
        'daily_reminder_channel_v4',
        'تذكير المذاكرة اليومي',
        description: 'تذكير يومي للمراجعة والمذاكرة',
        importance: Importance.max,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('arabian_notification'),
      ),
      AndroidNotificationChannel(
        'study_timer_channel_final',
        'منبهات المذاكرة',
        description: 'منبهات هامة لبدء وانتهاء جلسات المذاكرة',
        importance: Importance.max,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('arabian_notification'),
      ),
    ];

    final androidImplementation =
        flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      for (final channel in channels) {
        await androidImplementation.createNotificationChannel(channel);
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

  Future<void> saveToHistory(String title, String body, {String? imageUrl}) async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString('notifications_history');
    List history = [];
    if (data != null) {
      try { history = jsonDecode(data); } catch (_) {}
    }
    
    // Check if already exists to avoid duplicates
    final bool alreadyExists = history.any((e) => 
      e['title'] == title && 
      e['body'] == body && 
      (DateTime.parse(e['timestamp']).difference(DateTime.now()).inMinutes.abs() < 1)
    );
    
    if (alreadyExists) return;

    history.insert(0, {
      'title': title,
      'body': body,
      'image': imageUrl,
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
        sound: RawResourceAndroidNotificationSound('arabian_notification'),
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
        await saveToHistory(title, body);
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
            sound: RawResourceAndroidNotificationSound('arabian_notification'),
            largeIcon: DrawableResourceAndroidBitmap('app_icon'),
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            sound: 'arabian_notification.wav',
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
              sound: RawResourceAndroidNotificationSound('arabian_notification'),
              largeIcon: DrawableResourceAndroidBitmap('app_icon'),
            ),
            iOS: DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
              sound: 'arabian_notification.wav',
              interruptionLevel: InterruptionLevel.critical,
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
        await saveToHistory('بدء المذاكرة: $title', 'بدأت الجلسة الدراسية بنجاح.');
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
              sound: RawResourceAndroidNotificationSound('arabian_notification'),
              largeIcon: DrawableResourceAndroidBitmap('app_icon'),
            ),
            iOS: DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
              sound: 'arabian_notification.wav',
              interruptionLevel: InterruptionLevel.critical,
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
        await saveToHistory('انتهاء المذاكرة: $title', 'انتهت الجلسة الدراسية بنجاح.');
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

  // --- Firebase Cloud Messaging ---

  Future<void> _initFirebaseMessaging() async {
    fcm.FirebaseMessaging messaging = fcm.FirebaseMessaging.instance;

    // Request permissions (important for iOS and Android 13+)
    fcm.NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == fcm.AuthorizationStatus.authorized) {
      dev.log('User granted FCM permission');
      
      // Get the token for debugging
      String? token = await messaging.getToken();
      dev.log('FCM Token: $token');
      
      // Auto-subscribe to 'all_users' topic
      try {
        await messaging.subscribeToTopic('all_users');
        dev.log('Subscribed to all_users topic');
      } catch (e) {
        dev.log('Error subscribing to all_users topic: $e');
      }
    } else {
      dev.log('User declined or has not accepted FCM permission');
    }

    // Handle initial message if app was terminated
    fcm.RemoteMessage? initialMessage = await messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleFcmMessage(initialMessage);
      _navigateToNotifications();
    }

    // Handle messages when app is in background but not terminated
    fcm.FirebaseMessaging.onMessageOpenedApp.listen((fcm.RemoteMessage message) {
      _handleFcmMessage(message);
      _navigateToNotifications();
    });

    // Handle foreground messages
    fcm.FirebaseMessaging.onMessage.listen((fcm.RemoteMessage message) {
      dev.log('Got a message whilst in the foreground!');
      _handleFcmMessage(message);

      if (message.notification != null) {
        _showForegroundNotification(message.notification!);
      }
    });
  }

  void _handleFcmMessage(fcm.RemoteMessage message) {
    if (message.notification != null) {
      saveToHistory(
        message.notification!.title ?? '', 
        message.notification!.body ?? '',
        imageUrl: message.notification!.android?.imageUrl ?? message.notification!.apple?.imageUrl,
      );
    }
  }

  Future<void> _showForegroundNotification(fcm.RemoteNotification notification) async {
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'fcm_foreground_channel',
        'إشعارات عامة',
        channelDescription: 'إشعارات مستلمة أثناء استخدام التطبيق',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        sound: RawResourceAndroidNotificationSound('arabian_notification'),
      );
    
    const DarwinNotificationDetails iosPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'arabian_notification.wav',
      interruptionLevel: InterruptionLevel.critical,
    );
    
    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iosPlatformChannelSpecifics,
    );

    await flutterLocalNotificationsPlugin.show(
      notification.hashCode,
      notification.title,
      notification.body,
      platformChannelSpecifics,
    );
  }
}
