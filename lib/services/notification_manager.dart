import 'package:flutter/material.dart';
import 'dart:async';
import 'notification.dart';
import 'database.dart';
import '../models/course.dart';

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
    Course? nextCourse = await _getNextCourse();
    if (nextCourse != null) {
      await _notificationService.showNotification(
        "下一节课程",
        "课程：${nextCourse.name}\n"
        "教师：${nextCourse.teacher}\n"
        "教室：${nextCourse.classroom}\n"
        "时间：第${nextCourse.startTime}-${nextCourse.endTime}节"
      );
    } else {
      await _notificationService.showNotification(
        "今日课程",
        "今天没有更多课程了"
      );
    }
  }
  
  // 获取下一节课程
  Future<Course?> _getNextCourse() async {
    final courses = await _databaseService.getCourses();
    if (courses.isEmpty) {
      return null;
    }
    
    final now = DateTime.now();
    final currentWeekday = now.weekday;  // 1-7，周一到周日
    
    // 获取当前学期的第几周（这部分需要根据学校的具体学期安排来计算）
    final int currentWeek = _calculateCurrentWeek(now);
    
    // 假设每节课的时间表（需要根据学校的作息时间调整）
    final classTimes = [
      {"start": TimeOfDay(hour: 8, minute: 0), "end": TimeOfDay(hour: 9, minute: 30)},    // 第1节
      {"start": TimeOfDay(hour: 9, minute: 50), "end": TimeOfDay(hour: 11, minute: 20)},  // 第2节
      {"start": TimeOfDay(hour: 13, minute: 30), "end": TimeOfDay(hour: 15, minute: 0)},  // 第3节
      {"start": TimeOfDay(hour: 15, minute: 20), "end": TimeOfDay(hour: 16, minute: 50)}, // 第4节
      {"start": TimeOfDay(hour: 18, minute: 30), "end": TimeOfDay(hour: 20, minute: 0)},  // 第5节
    ];
    
    // 计算当前时间对应的课程节次
    int currentClassIndex = -1;
    final currentTime = TimeOfDay.fromDateTime(now);
    final currentTimeInMinutes = currentTime.hour * 60 + currentTime.minute;
    
    for (int i = 0; i < classTimes.length; i++) {
      final classStartTime = classTimes[i]["start"]!;
      final classStartInMinutes = classStartTime.hour * 60 + classStartTime.minute;
      
      final classEndTime = classTimes[i]["end"]!;
      final classEndInMinutes = classEndTime.hour * 60 + classEndTime.minute;
      
      if (currentTimeInMinutes >= classStartInMinutes && 
          currentTimeInMinutes <= classEndInMinutes) {
        currentClassIndex = i + 1;  // 当前正在上的课
        break;
      } else if (currentTimeInMinutes < classStartInMinutes) {
        break;  // 找到下一节课
      }
    }
    
    // 筛选出今天剩余的课程
    List<Course> todayCourses = courses.where((course) {
      // 检查是否在当前周内
      bool isInCurrentWeek = currentWeek >= course.startWeek && currentWeek <= course.endWeek;
      
      // 检查是否是今天的课程
      bool isToday = course.weekday == currentWeekday;
      
      // 检查是否是未来的课程（还没上过的）
      bool isFutureCourse = course.startTime > currentClassIndex;
      
      return isInCurrentWeek && isToday && isFutureCourse;
    }).toList();
    
    // 按照开始时间排序
    todayCourses.sort((a, b) => a.startTime.compareTo(b.startTime));
    
    // 返回最近的一节课
    return todayCourses.isNotEmpty ? todayCourses.first : null;
  }
  
  // 计算当前是学期的第几周
  // 这部分需要根据学校具体情况实现
  int _calculateCurrentWeek(DateTime now) {
    // 假设学期第一周的第一天
    final firstDayOfSemester = DateTime(2024, 2, 26); // 根据学校实际情况修改
    
    // 计算当前时间距离学期开始有多少天
    final difference = now.difference(firstDayOfSemester).inDays;
    
    // 计算当前是第几周
    return (difference / 7).floor() + 1;
  }
  
  void dispose() {
    _timer?.cancel();
  }
}