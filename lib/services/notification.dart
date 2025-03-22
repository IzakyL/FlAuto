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
      onDidReceiveNotificationResponse: (NotificationResponse notificationResponse) {
        // 处理通知点击事件
        print("通知点击: ${notificationResponse.payload}");
      },
    );
    
    // 请求通知权限
    await _requestPermissions();
  }

  // 请求通知权限
  Future<void> _requestPermissions() async {
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
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> showPersistentNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
      AndroidNotificationDetails(
        'persistent_channel',  // 频道ID
        '持久性通知',  // 频道名称
        channelDescription: '显示课程提醒的持久性通知',  // 频道描述
        importance: Importance.high,
        priority: Priority.high,
        ongoing: true,  // 设置为持久性通知
        autoCancel: false,  // 防止用户轻易取消
        styleInformation: BigTextStyleInformation(''),  // 支持长文本显示
      );

  const NotificationDetails platformChannelSpecifics =
      NotificationDetails(android: androidPlatformChannelSpecifics);

  await notificationsPlugin.show(
    id,
    title,
    body,
    platformChannelSpecifics,
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