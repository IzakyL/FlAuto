import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'dart:convert';
import '../models/course.dart';
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
  Future<List<Course>> fetchCoursesWithWebView(BuildContext context, String url) async {
    List<Course> courses = [];
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
                  final result = await controller.evaluateJavascript(source: """
                    // 这里编写提取课程信息的JavaScript代码
                    // 根据网页结构来定制
                    (function() {
                      var courses = [];
                      try {
                        // 假设课程表在某个表格中
                        var table = document.querySelector('.course-table');
                        if (table) {
                          var rows = table.querySelectorAll('tr');
                          rows.forEach(function(row, rowIndex) {
                            if (rowIndex > 0) { // 跳过表头
                              var cells = row.querySelectorAll('td');
                              courses.push({
                                name: cells[0].innerText,
                                teacher: cells[1].innerText,
                                classroom: cells[2].innerText,
                                weekday: parseInt(cells[3].innerText),
                                startTime: parseInt(cells[4].innerText),
                                endTime: parseInt(cells[5].innerText),
                                startWeek: parseInt(cells[6].innerText),
                                endWeek: parseInt(cells[7].innerText)
                              });
                            }
                          });
                        }
                      } catch(e) {
                        console.error(e);
                      }
                      return JSON.stringify(courses);
                    })();
                  """);
                  
                  if (result != null) {
                    // 解析JavaScript返回的JSON数据
                    List<dynamic> parsedData = jsonDecode(result);
                    for (var courseData in parsedData) {
                      Course course = Course(
                        name: courseData['name'],
                        teacher: courseData['teacher'],
                        classroom: courseData['classroom'],
                        weekday: courseData['weekday'],
                        startTime: courseData['startTime'],
                        endTime: courseData['endTime'],
                        startWeek: courseData['startWeek'],
                        endWeek: courseData['endWeek'],
                      );
                      courses.add(course);
                      await _databaseService.insertCourse(course);
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
                  // 类似上面的JavaScript执行过程
                }
                Navigator.of(context).pop();
              },
              child: Text('完成'),
            ),
          ],
        );
      },
    );
    
    return courses;
  }
  
  // 抓取特定教务系统的课程表并解析
  // 这部分需要根据具体学校的教务系统定制
  Future<List<Course>> scrapeCourseSchedule(BuildContext context, String schoolSystem) async {
    switch (schoolSystem) {
      case 'zfsoft': // 正方教务系统
        return await fetchCoursesWithWebView(context, 'http://your-school-educational-system.com/login');
      case 'custom':
        // 其他教务系统
        break;
      default:
        throw Exception('不支持的教务系统');
    }
    return [];
  }
}