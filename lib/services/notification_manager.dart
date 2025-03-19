import 'dart:async';
import 'notification.dart';
import 'database.dart';
import '../models/event.dart';

class NotificationManager {
  final NotificationService _notificationService;
  final DatabaseService _databaseService;
  Timer? _timer;
  
  // 使用常量标识持久性通知ID
  static const int PERSISTENT_NOTIFICATION_ID = 9999;

  NotificationManager({
    required NotificationService notificationService,
    required DatabaseService databaseService,
  }) : _notificationService = notificationService,
       _databaseService = databaseService;

  // 初始化通知服务
  Future<void> initialize() async {
    await _notificationService.initNotification();
    await updateNextClassNotification();

    // 每分钟更新一次通知
    _timer = Timer.periodic(Duration(minutes: 1), (timer) async {
      await updateNextClassNotification();
    });
  }

  // 更新下一节课程的通知
  Future<void> updateNextClassNotification() async {
    Event? nextEvent = await _getNextEvent();
    
    if (nextEvent != null) {
      // 格式化时间
      String startTime = _formatTime(nextEvent.startTime);
      String endTime = _formatTime(nextEvent.endTime);
      
      await _notificationService.showPersistentNotification(
        id: PERSISTENT_NOTIFICATION_ID,
        title: "下一节课程",
        body: "课程：${nextEvent.name}\n"
            "地点：${nextEvent.location}\n"
            "时间：$startTime - $endTime\n"
            "描述：${nextEvent.description}",
      );
    } else {
      // 尝试获取下一个工作日的课程
      Event? nextWorkDayEvent = await _getNextWorkDayEvent();
      
      if (nextWorkDayEvent != null) {
        String startTime = _formatTime(nextWorkDayEvent.startTime);
        String endTime = _formatTime(nextWorkDayEvent.endTime);
        String nextDate = "${nextWorkDayEvent.startTime.month}月${nextWorkDayEvent.startTime.day}日";
        
        await _notificationService.showPersistentNotification(
          id: PERSISTENT_NOTIFICATION_ID,
          title: "下一个工作日课程",
          body: "日期：$nextDate\n"
              "课程：${nextWorkDayEvent.name}\n"
              "地点：${nextWorkDayEvent.location}\n"
              "时间：$startTime - $endTime",
        );
      } else {
        await _notificationService.showPersistentNotification(
          id: PERSISTENT_NOTIFICATION_ID,
          title: "课程提醒", 
          body: "近期没有安排的课程"
        );
      }
    }
  }

  // 格式化时间为 HH:MM 格式
  String _formatTime(DateTime time) {
    return "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";
  }

  // 获取下一节课程
  Future<Event?> _getNextEvent() async {
    return null;
  
    // ...existing code...
  }

  // 查找下一个工作日的第一节课
  Future<Event?> _getNextWorkDayEvent() async {
    return null;
  
    // ...existing code...
  }

  // 为即将到来的课程设置提醒
  Future<void> scheduleReminderForNextClass() async {
    Event? nextEvent = await _getNextEvent();
    
    nextEvent ??= await _getNextWorkDayEvent();
    
    if (nextEvent != null) {
      // 计算提前多少分钟提醒（例如提前15分钟）
      DateTime reminderTime = nextEvent.startTime.subtract(Duration(minutes: 15));
      
      // 如果提醒时间已经过了，就不设置提醒
      if (reminderTime.isAfter(DateTime.now())) {
        await _notificationService.scheduleNotification(
          id: nextEvent.id ?? 0,
          title: "课程提醒",
          body: "课程：${nextEvent.name}\n地点：${nextEvent.location}\n时间：${_formatTime(nextEvent.startTime)}",
          scheduledTime: reminderTime,
        );
      }
    }
  }

  // 移除持久性通知
  Future<void> cancelPersistentNotification() async {
    await _notificationService.cancelNotification(PERSISTENT_NOTIFICATION_ID);
  }

  void dispose() {
    _timer?.cancel();
    // 清理通知
    cancelPersistentNotification();
  }
}