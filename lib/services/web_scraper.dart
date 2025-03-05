import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:url_launcher/url_launcher.dart';

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
              initialUrlRequest: URLRequest(
                url: WebUri(Uri.parse(url).toString()),
              ),
              onLoadStop: (controller, url) async {
                // 检测到用户已登录并进入课程表页面
                if (url.toString().contains(
                  'https://jw.ustc.edu.cn/for-std/course-table/get-data',
                )) {
                  // 延迟执行，确保页面完全加载
                  await Future.delayed(Duration(seconds: 2));

                  // 执行JavaScript脚本提取课程表数据
                  final result = await controller.evaluateJavascript(
                    source: """
                    // 这里编写提取课程信息的JavaScript代码
                    (function() {
                      try{
                        var classes=[];
                        var table=document.getElementsByClassName('timetable');
                        var tbodies=table.getElementsByTagName('tbody');
                        for(tbody of tbodies){
                          var trs=tbody.getElementsByTagName('tr');
                          for(tr of trs){
                            var tds=tbody.getElementsByTagName('td');
                            for(let td of tds){
                              var cells=getElementsByClassName('cell');
                              for(let cell of cells){
                                var cs=getElementsByClassName('c');
                                for(let c of cs){
                                  var number=c.getElementsByClassName('number');
                                  var title=c.getElementsByClassName('title');
                                  var teacher=c.getElementsByClassName('teacher');
                                  var time=c.getElementsByClassName('time');
                                  var classroom=c.getElementsByClassName('classroom');
                                  classes.push({
                                    number:number,
                                    title:title,
                                    teacher:teacher,
                                    time:time,
                                    classroom:classroom
                                  });
                                }
                              }
                            }
                          }
                        }
                      }catch(err){
                        console.log(err);
                      }
                      console.log(classes);
                      return JSON.stringify(classes);
                    })();
                  """,
                  );

                  if (result != null) {
                    // 解析JavaScript返回的JSON数据
                    List<dynamic> parsedData = jsonDecode(result);

                    // 获取当前学期开始日期（假设学期从2024年2月26日开始）
                    DateTime semesterStart = DateTime(
                      2024,
                      2,
                      26,
                    ); // 调整为实际的学期开始日期

                    for (var eventData in parsedData) {
                      // 将节次转换为当天的具体时间
                      Map<int, TimeOfDay> classTimeMap = {
                        1: TimeOfDay(hour: 7, minute: 50),
                        2: TimeOfDay(hour: 8, minute: 40),
                        3: TimeOfDay(hour: 9, minute: 45),
                        4: TimeOfDay(hour: 10, minute: 35),
                        5: TimeOfDay(hour: 11, minute: 25),
                        6: TimeOfDay(hour: 14, minute: 0),
                        7: TimeOfDay(hour: 14, minute: 50),
                        8: TimeOfDay(hour: 15, minute: 55),
                        9: TimeOfDay(hour: 16, minute: 45),
                        10: TimeOfDay(hour: 14, minute: 35),
                        11: TimeOfDay(hour: 19, minute: 30),
                        12: TimeOfDay(hour: 20, minute: 20),
                        13: TimeOfDay(hour: 21, minute: 10),
                      };

                      // 课程的周几（1-7对应周一至周日）
                      int weekday = eventData['weekday'];
                      int startWeek = eventData['startWeek'];

                      // 计算课程的第一次上课日期
                      // 先找到学期开始的那周的周一，然后加上weekday-1天（周一加0天，周二加1天...）
                      DateTime firstDayOfSemester = _findFirstDayOfWeek(
                        semesterStart,
                      );
                      DateTime firstClassDay = firstDayOfSemester.add(
                        Duration(days: weekday - 1),
                      );

                      // 再加上(startWeek-1)周，得到课程开始的具体日期
                      DateTime classDate = firstClassDay.add(
                        Duration(days: (startWeek - 1) * 7),
                      );

                      // 设置课程开始和结束时间
                      TimeOfDay startTimeOfDay =
                          classTimeMap[eventData['startTime']] ??
                          TimeOfDay(hour: 8, minute: 0);
                      TimeOfDay endTimeOfDay =
                          classTimeMap[eventData['endTime']] ??
                          TimeOfDay(hour: 8, minute: 50);

                      // 合并日期和时间
                      DateTime startDateTime = DateTime(
                        classDate.year,
                        classDate.month,
                        classDate.day,
                        startTimeOfDay.hour,
                        startTimeOfDay.minute,
                      );

                      DateTime endDateTime = DateTime(
                        classDate.year,
                        classDate.month,
                        classDate.day,
                        endTimeOfDay.hour,
                        endTimeOfDay.minute,
                      );

                      // 格式化地点信息
                      String location = _formatLocation(
                        eventData['rawClassroom'],
                      );

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
}
