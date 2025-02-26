import 'package:flutter/material.dart';
import '../models/course.dart';
import '../services/database.dart';
import 'dart:math' as math;

class ScheduleScreen extends StatefulWidget {
  @override
  _ScheduleScreenState createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> with SingleTickerProviderStateMixin {
  final DatabaseService _databaseService = DatabaseService();
  List<Course> _courses = [];
  bool _isLoading = true;
  int _currentWeek = 1; // 当前周次
  late TabController _tabController;
  final List<String> _weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
  
  // 课程时间表（根据学校实际情况调整）
  final List<Map<String, dynamic>> _classTimes = [
    {"index": 1, "start": "8:00", "end": "8:45"},
    {"index": 2, "start": "8:55", "end": "9:40"},
    {"index": 3, "start": "10:00", "end": "10:45"},
    {"index": 4, "start": "10:55", "end": "11:40"},
    {"index": 5, "start": "14:00", "end": "14:45"},
    {"index": 6, "start": "14:55", "end": "15:40"},
    {"index": 7, "start": "16:00", "end": "16:45"},
    {"index": 8, "start": "16:55", "end": "17:40"},
    {"index": 9, "start": "19:00", "end": "19:45"},
    {"index": 10, "start": "19:55", "end": "20:40"},
    {"index": 11, "start": "20:50", "end": "21:35"},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadCourses();
    _calculateCurrentWeek();
  }

  // 计算当前周次
  void _calculateCurrentWeek() {
    // 假设学期开始时间为2024-02-26
    DateTime semesterStart = DateTime(2024, 2, 26);
    DateTime now = DateTime.now();
    int daysSinceSemesterStart = now.difference(semesterStart).inDays;
    setState(() {
      _currentWeek = (daysSinceSemesterStart / 7).floor() + 1;
    });
  }

  // 加载课程数据
  Future<void> _loadCourses() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final courses = await _databaseService.getCourses();
      setState(() {
        _courses = courses;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('加载课程失败: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('课程表 (第$_currentWeek周)'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadCourses,
          ),
          PopupMenuButton<int>(
            onSelected: (int value) {
              setState(() {
                _currentWeek = value;
              });
            },
            itemBuilder: (BuildContext context) {
              return List.generate(20, (index) {
                return PopupMenuItem<int>(
                  value: index + 1,
                  child: Text('第${index + 1}周'),
                );
              });
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: '日视图'),
            Tab(text: '周视图'),
          ],
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildDayView(),
                _buildWeekView(),
              ],
            ),
    );
  }

  // 构建日视图
  Widget _buildDayView() {
    // 获取当前星期几 (1-7, 周一到周日)
    int todayWeekday = DateTime.now().weekday;
    
    // 筛选今天且在当前周有课的课程
    List<Course> todayCourses = _courses.where((course) {
      return course.weekday == todayWeekday && 
             _currentWeek >= course.startWeek && 
             _currentWeek <= course.endWeek;
    }).toList();
    
    // 按照开始时间排序
    todayCourses.sort((a, b) => a.startTime.compareTo(b.startTime));
    
    if (todayCourses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              '今天没有课程',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: EdgeInsets.all(8),
      itemCount: todayCourses.length,
      itemBuilder: (context, index) {
        final course = todayCourses[index];
        
        // 判断课程状态：未开始、进行中、已结束
        String status = _getCourseStatus(course);
        Color statusColor;
        switch (status) {
          case '进行中':
            statusColor = Colors.green;
            break;
          case '已结束':
            statusColor = Colors.grey;
            break;
          default:
            statusColor = Colors.blue;
        }
        
        return Card(
          elevation: 2,
          margin: EdgeInsets.symmetric(vertical: 8),
          child: ListTile(
            contentPadding: EdgeInsets.all(16),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  course.name,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(color: statusColor, fontSize: 12),
                  ),
                ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 16, color: Colors.grey),
                    SizedBox(width: 4),
                    Text('第${course.startTime}-${course.endTime}节'),
                    SizedBox(width: 16),
                    Icon(Icons.location_on, size: 16, color: Colors.grey),
                    SizedBox(width: 4),
                    Text(course.classroom),
                  ],
                ),
                SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.person, size: 16, color: Colors.grey),
                    SizedBox(width: 4),
                    Text(course.teacher),
                    SizedBox(width: 16),
                    Icon(Icons.date_range, size: 16, color: Colors.grey),
                    SizedBox(width: 4),
                    Text('第${course.startWeek}-${course.endWeek}周'),
                  ],
                ),
              ],
            ),
            onTap: () {
              // 点击课程显示详情
              _showCourseDetails(course);
            },
          ),
        );
      },
    );
  }

  // 构建周视图
  Widget _buildWeekView() {
    // 筛选当前周的课程
    List<Course> weekCourses = _courses.where((course) {
      return _currentWeek >= course.startWeek && _currentWeek <= course.endWeek;
    }).toList();
    
    if (weekCourses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              '本周没有课程',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }
    
    // 课程表网格的最大节数
    int maxClassTime = 11;
    
    return SingleChildScrollView(
      child: Column(
        children: [
          // 头部周几栏
          Container(
            height: 40,
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
            ),
            child: Row(
              children: [
                // 左侧时间栏占位
                Container(
                  width: 30,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    border: Border(right: BorderSide(color: Colors.grey.shade300)),
                  ),
                ),
                // 星期几栏
                ...List.generate(7, (index) {
                  bool isToday = index + 1 == DateTime.now().weekday;
                  return Expanded(
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isToday ? Colors.blue.withOpacity(0.2) : null,
                        border: Border(right: BorderSide(color: Colors.grey.shade300)),
                      ),
                      child: Text(
                        _weekdays[index],
                        style: TextStyle(
                          fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
          
          // 课程表主体
          Container(
            height: maxClassTime * 60.0,  // 每节课高度60
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 左侧时间栏
                Container(
                  width: 30,
                  child: Column(
                    children: List.generate(maxClassTime, (index) {
                      return Container(
                        height: 60,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          border: Border(
                            right: BorderSide(color: Colors.grey.shade300),
                            bottom: BorderSide(color: Colors.grey.shade300),
                          ),
                        ),
                        child: Text('${index + 1}'),
                      );
                    }),
                  ),
                ),
                
                // 课程格子
                ...List.generate(7, (weekday) {
                  return Expanded(
                    child: Stack(
                      children: [
                        // 背景网格
                        Column(
                          children: List.generate(maxClassTime, (index) {
                            return Container(
                              height: 60,
                              decoration: BoxDecoration(
                                border: Border(
                                  right: BorderSide(color: Colors.grey.shade300),
                                  bottom: BorderSide(color: Colors.grey.shade300),
                                ),
                              ),
                            );
                          }),
                        ),
                        
                        // 课程卡片
                        ...weekCourses.where((course) => course.weekday == weekday + 1).map((course) {
                          double top = (course.startTime - 1) * 60.0;
                          double height = (course.endTime - course.startTime + 1) * 60.0;
                          
                          // 为每个课程生成随机但固定的颜色
                          Color courseColor = Color((math.Random(course.name.hashCode).nextDouble() * 0xFFFFFF).toInt()).withOpacity(1.0);
                          // 调整颜色亮度，让它不太暗也不太亮
                          HSLColor hslColor = HSLColor.fromColor(courseColor);
                          courseColor = hslColor.withLightness(0.7).withSaturation(0.5).toColor();
                          
                          return Positioned(
                            top: top,
                            left: 0,
                            right: 0,
                            height: height,
                            child: GestureDetector(
                              onTap: () => _showCourseDetails(course),
                              child: Container(
                                margin: EdgeInsets.all(1),
                                padding: EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: courseColor,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      course.name,
                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (height > 40) // 只在足够高的情况下显示额外信息
                                      Text(
                                        course.classroom,
                                        style: TextStyle(fontSize: 10, color: Colors.white),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 显示课程详情对话框
  void _showCourseDetails(Course course) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(course.name),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDetailRow(Icons.person, '教师', course.teacher),
            _buildDetailRow(Icons.location_on, '教室', course.classroom),
            _buildDetailRow(Icons.access_time, '时间', '第${course.startTime}-${course.endTime}节'),
            _buildDetailRow(Icons.calendar_today, '周次', '第${course.startWeek}-${course.endWeek}周'),
            _buildDetailRow(Icons.today, '星期', '周${['一', '二', '三', '四', '五', '六', '日'][course.weekday - 1]}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('关闭'),
          ),
        ],
      ),
    );
  }

  // 构建详情行
  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.blue),
          SizedBox(width: 8),
          Text('$label: ', style: TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  // 获取课程当前状态
  String _getCourseStatus(Course course) {
    DateTime now = DateTime.now();
    TimeOfDay currentTime = TimeOfDay.fromDateTime(now);
    int currentMinutes = currentTime.hour * 60 + currentTime.minute;
    
    // 解析课程的开始和结束时间
    String startTimeString = _classTimes[course.startTime - 1]['start'];
    String endTimeString = _classTimes[course.endTime - 1]['end'];
    
    List<String> startParts = startTimeString.split(':');
    List<String> endParts = endTimeString.split(':');
    
    int startMinutes = int.parse(startParts[0]) * 60 + int.parse(startParts[1]);
    int endMinutes = int.parse(endParts[0]) * 60 + int.parse(endParts[1]);
    
    if (currentMinutes < startMinutes) {
      return '未开始';
    } else if (currentMinutes > endMinutes) {
      return '已结束';
    } else {
      return '进行中';
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}