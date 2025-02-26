import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'dart:convert';
import '../models/event.dart';
import 'database.dart';

class WebScraperService {
  final DatabaseService _databaseService = DatabaseService();

  // 打开系统浏览器访问指定URL
  Future<void> openBrowserForLogin(String url) async {
    final Uri url0 = Uri.parse(url);
    if (await canLaunchUrl(url0)) {
      await launchUrl(url0, mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch $url0';
    }
  }

  // 使用WebView来获取课程表数据
  Future<List<Event>> fetchEventsWithWebView(
    BuildContext context,
    String url,
  ) async {
    List<Event> events = [];
    bool isDataLoaded = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: Text('登录并获取课程表'),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.height * 0.8,
            child: InAppWebView(
              initialUrlRequest: URLRequest(url: Uri.parse(url)),
              onLoadStop: (controller, url) async {
                // 检测到用户已登录并进入课程表页面
                if (url.toString().contains('课程表页面的特定标识')) {
                  // 延迟执行，确保页面完全加载
                  await Future.delayed(Duration(seconds: 2));

                  // 执行JavaScript脚本提取课程表数据
                  final result = await controller.evaluateJavascript(
                    source: """
                    // 这里编写提取课程信息的JavaScript代码
                    (function() {
                      var events = [];
                      try {
                        // 假设课程表在某个表格中
                        var table = document.querySelector('.event-table');
                        if (table) {
                          var rows = table.querySelectorAll('tr');
                          rows.forEach(function(row, rowIndex) {
                            if (rowIndex > 0) { // 跳过表头
                              var cells = row.querySelectorAll('td');
                              
                              // 获取基础数据
                              var name = cells[0].innerText.trim();
                              var teacher = cells[1].innerText.trim();
                              var classroom = cells[2].innerText.trim();
                              var weekday = parseInt(cells[3].innerText);
                              var startTime = parseInt(cells[4].innerText);
                              var endTime = parseInt(cells[5].innerText);
                              var startWeek = parseInt(cells[6].innerText);
                              var endWeek = parseInt(cells[7].innerText);
                              
                              // 组合描述信息
                              var description = '授课教师: ' + teacher + 
                                              '\\n周次: ' + startWeek + '-' + endWeek + '周';
                              
                              events.push({
                                name: name,
                                location: classroom,
                                description: description,
                                weekday: weekday,
                                startTime: startTime,
                                endTime: endTime,
                                startWeek: startWeek,
                                endWeek: endWeek,
                                // 保留原始数据以便后续处理
                                rawTeacher: teacher,
                                rawClassroom: classroom
                              });
                            }
                          });
                        }
                      } catch(e) {
                        console.error(e);
                      }
                      return JSON.stringify(events);
                    })();
                  """,
                  );

                  if (result != null) {
                    // 解析JavaScript返回的JSON数据
                    List<dynamic> parsedData = jsonDecode(result);
                    
                    // 获取当前学期开始日期（假设学期从2024年2月26日开始）
                    DateTime semesterStart = DateTime(2024, 2, 26); // 调整为实际的学期开始日期
                    
                    for (var eventData in parsedData) {
                      // 将节次转换为当天的具体时间
                      Map<int, TimeOfDay> classTimeMap = {
                        1: TimeOfDay(hour: 8, minute: 0),   // 第1节：8:00
                        2: TimeOfDay(hour: 8, minute: 50),  // 第2节：8:50
                        3: TimeOfDay(hour: 10, minute: 0),  // 第3节：10:00
                        4: TimeOfDay(hour: 10, minute: 50), // 第4节：10:50
                        5: TimeOfDay(hour: 14, minute: 0),  // 第5节：14:00
                        6: TimeOfDay(hour: 14, minute: 50), // 第6节：14:50
                        7: TimeOfDay(hour: 16, minute: 0),  // 第7节：16:00
                        8: TimeOfDay(hour: 16, minute: 50), // 第8节：16:50
                        9: TimeOfDay(hour: 19, minute: 0),  // 第9节：19:00
                        10: TimeOfDay(hour: 19, minute: 50),// 第10节：19:50
                        11: TimeOfDay(hour: 20, minute: 40),// 第11节：20:40
                      };
                      
                      // 课程的周几（1-7对应周一至周日）
                      int weekday = eventData['weekday'];
                      int startWeek = eventData['startWeek'];
                      
                      // 计算课程的第一次上课日期
                      // 先找到学期开始的那周的周一，然后加上weekday-1天（周一加0天，周二加1天...）
                      DateTime firstDayOfSemester = _findFirstDayOfWeek(semesterStart);
                      DateTime firstClassDay = firstDayOfSemester.add(Duration(days: weekday - 1));
                      
                      // 再加上(startWeek-1)周，得到课程开始的具体日期
                      DateTime classDate = firstClassDay.add(Duration(days: (startWeek - 1) * 7));
                      
                      // 设置课程开始和结束时间
                      TimeOfDay startTimeOfDay = classTimeMap[eventData['startTime']] ?? TimeOfDay(hour: 8, minute: 0);
                      TimeOfDay endTimeOfDay = classTimeMap[eventData['endTime']] ?? TimeOfDay(hour: 8, minute: 50);
                      
                      // 合并日期和时间
                      DateTime startDateTime = DateTime(
                        classDate.year, 
                        classDate.month, 
                        classDate.day,
                        startTimeOfDay.hour,
                        startTimeOfDay.minute
                      );
                      
                      DateTime endDateTime = DateTime(
                        classDate.year, 
                        classDate.month, 
                        classDate.day,
                        endTimeOfDay.hour,
                        endTimeOfDay.minute
                      );
                      
                      // 格式化地点信息
                      String location = _formatLocation(eventData['rawClassroom']);
                      
                      // 创建Event对象
                      Event event = Event(
                        name: eventData['name'],
                        startTime: startDateTime,
                        endTime: endDateTime,
                        description: eventData['description'],
                        location: location,
                      );
                      
                      events.add(event);
                      await _databaseService.insertEvent(event);
                    }
                    isDataLoaded = true;
                    Navigator.of(context).pop(); // 关闭WebView对话框
                  }
                }
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('取消'),
            ),
            TextButton(
              onPressed: () async {
                // 用户手动确认数据已加载完成
                if (!isDataLoaded) {
                  // 尝试从当前页面获取数据
                  // 这里可以添加类似上面的JavaScript执行过程
                }
                Navigator.of(context).pop();
              },
              child: Text('完成'),
            ),
          ],
        );
      },
    );

    return events;
  }
  
  // 查找指定日期所在周的第一天（周一）
  DateTime _findFirstDayOfWeek(DateTime date) {
    // 周一=1, 周日=7
    int weekday = date.weekday;
    // 计算到该周周一的偏移量
    int daysToSubtract = weekday - 1;
    return date.subtract(Duration(days: daysToSubtract));
  }
  
  // 格式化地点信息
  String _formatLocation(String rawClassroom) {
    if (rawClassroom.length > 1) {
      String buildingCode = rawClassroom[0];
      String roomNumber = rawClassroom.substring(1);
      String buildingName = buildingCode;
      return '$buildingName $roomNumber';
    }
    return rawClassroom;
  }

  // 抓取特定教务系统的课程表并解析
  // 这部分需要根据具体学校的教务系统定制
  Future<List<Event>> scrapeEventSchedule(
    BuildContext context,
    String schoolSystem,
  ) async {
    switch (schoolSystem) {
      case 'zfsoft': // 正方教务系统
        return await fetchEventsWithWebView(
          context,
          'http://your-school-educational-system.com/login',
        );
      case 'custom':
        // 其他教务系统
        break;
      default:
        throw Exception('不支持的教务系统');
    }
    return [];
  }
}