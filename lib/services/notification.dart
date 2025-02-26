import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

class NotificationService {
  final FlutterLocalNotificationsPlugin notificationsPlugin = FlutterLocalNotificationsPlugin();

  // 初始化通知服务
  Future<void> initNotification() async {
    // 初始化时区数据，用于定时通知
    tz_data.initializeTimeZones();
    
    // 设置安卓通知渠道
    AndroidInitializationSettings initializationSettingsAndroid = 
        const AndroidInitializationSettings('@mipmap/ic_launcher');
  
    
    // 整合平台设置
    InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );
    
    // 初始化插件
    await notificationsPlugin.initialize(
      initializationSettings,
      onSelectNotification: (String? payload) {
        // 处理通知点击事件
        print("通知点击: $payload");
      },
    );
    
    // 请求通知权限
    await _requestPermissions();
  }

  // 请求通知权限
  Future<void> _requestPermissions() async {
    await notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestPermission();
        
    await notificationsPlugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
  }

  // 显示即时通知
  Future<void> showNotification(String title, String body) async {
    AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'course_reminder',
      '课程提醒',
      channelDescription: '课程提醒通知渠道',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );
    
    
    NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );
    
    // 显示通知，使用系统时间作为ID以确保唯一性
    await notificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      notificationDetails,
    );
  }

  // 实现定时通知
  Future<void> scheduleNotification({
    required int id, 
    required String title, 
    required String body, 
    required DateTime scheduledTime,
  }) async {
    AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'scheduled_course_reminder',
      '定时课程提醒',
      channelDescription: '定时课程提醒通知渠道',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );
    
    NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );
    
    // 将本地时间转换为TZ时间
    final tz.TZDateTime scheduledDate = tz.TZDateTime.from(
      scheduledTime,
      tz.local,
    );
    
    // 安排定时通知
    await notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      notificationDetails,
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  // 取消特定ID的通知
  Future<void> cancelNotification(int id) async {
    await notificationsPlugin.cancel(id);
  }

  // 取消所有通知
  Future<void> cancelAllNotifications() async {
    await notificationsPlugin.cancelAll();
  }
}