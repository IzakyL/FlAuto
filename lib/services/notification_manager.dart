import 'package:flutter/material.dart';
import 'dart:async';
import 'notification.dart';
import 'database.dart';
import '../models/event.dart';

class NotificationManager {
  final NotificationService _notificationService;
  final DatabaseService _databaseService;
  Timer? _timer;

  NotificationManager({
    required NotificationService notificationService,
    required DatabaseService databaseService,
  }) : _notificationService = notificationService,
       _databaseService = databaseService;

  // 初始化通知服务
  Future<void> initialize() async {
    await _notificationService.initNotification();
    updateNextClassNotification();

    // 每分钟更新一次通知
    _timer = Timer.periodic(Duration(minutes: 1), (timer) {
      updateNextClassNotification();
    });
  }

  // 更新下一节课程的通知
  Future<void> updateNextClassNotification() async {
    Event? nextEvent = await _getNextEvent();
    if (nextEvent != null) {
      // 格式化时间
      String startTime = _formatTime(nextEvent.startTime);
      String endTime = _formatTime(nextEvent.endTime);
      
      await _notificationService.showNotification(
        "下一节课程",
        "课程：${nextEvent.name}\n"
            "地点：${nextEvent.location}\n"
            "时间：$startTime - $endTime\n"
            "描述：${nextEvent.description}",
      );
    } else {
      await _notificationService.showNotification("今日课程", "今天没有更多课程了");
    }
  }

  // 格式化时间为 HH:MM 格式
  String _formatTime(DateTime time) {
    return "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";
  }

  // 获取下一节课程
  Future<Event?> _getNextEvent() async {
    final events = await _databaseService.getEvents();
    if (events.isEmpty) {
      return null;
    }

    final now = DateTime.now();
    
    // 筛选出今天剩余的课程（开始时间在当前时间之后的课程）
    List<Event> todayEvents = events.where((event) {
      // 检查是否是同一天
      bool isSameDay = event.startTime.year == now.year && 
                        event.startTime.month == now.month && 
                        event.startTime.day == now.day;
      
      // 检查开始时间是否在当前时间之后
      bool isAfterNow = event.startTime.isAfter(now);
      
      return isSameDay && isAfterNow;
    }).toList();

    // 按照开始时间排序
    todayEvents.sort((a, b) => a.startTime.compareTo(b.startTime));

    // 返回最近的一节课
    return todayEvents.isNotEmpty ? todayEvents.first : null;
  }

  // 查找下一个工作日的第一节课
  Future<Event?> _getNextWorkDayEvent() async {
    final events = await _databaseService.getEvents();
    if (events.isEmpty) {
      return null;
    }

    final now = DateTime.now();
    DateTime nextDay = now.add(Duration(days: 1));
    
    // 最多查找未来7天
    for (int i = 0; i < 7; i++) {
      // 筛选下一天的课程
      List<Event> nextDayEvents = events.where((event) {
        return event.startTime.year == nextDay.year &&
               event.startTime.month == nextDay.month &&
               event.startTime.day == nextDay.day;
      }).toList();

      if (nextDayEvents.isNotEmpty) {
        // 按照开始时间排序
        nextDayEvents.sort((a, b) => a.startTime.compareTo(b.startTime));
        return nextDayEvents.first;
      }
      
      // 继续查找下一天
      nextDay = nextDay.add(Duration(days: 1));
    }
    
    return null;
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

  void dispose() {
    _timer?.cancel();
  }
}