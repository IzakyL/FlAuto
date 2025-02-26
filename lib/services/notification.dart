import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin notificationsPlugin = 
      FlutterLocalNotificationsPlugin();

  Future<void> initNotification() async {
    AndroidInitializationSettings initializationSettingsAndroid =
        const AndroidInitializationSettings('@mipmap/ic_launcher');

    var initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid);
    await notificationsPlugin.initialize(initializationSettings);
  }

  Future<void> showNotification(String title, String body) async {
    AndroidNotificationDetails androidDetails = const AndroidNotificationDetails(
      'channel_id',
      'Course Schedule',
      importance: Importance.max,
      priority: Priority.high,
      ongoing: true,
    );

    NotificationDetails notificationDetails =
        NotificationDetails(android: androidDetails);
        
    await notificationsPlugin.show(
      0, 
      title,
      body,
      notificationDetails
    );
  }
}