import 'package:flutter/material.dart';
import '../models/event.dart';
import '../services/database.dart';
import 'dart:math' as math;

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  _ScheduleScreenState createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen>
    with SingleTickerProviderStateMixin {
  final DatabaseService _databaseService = DatabaseService();
  List<Event> _events = [];
  bool _isLoading = true;
  int _currentWeek = 1; // 当前周次
  late TabController _tabController;
  final List<String> _weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
  
  // 学期开始时间
  final DateTime _semesterStart = DateTime(2024, 2, 26);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadEvents();
    _calculateCurrentWeek();
  }

  // 计算当前周次
  void _calculateCurrentWeek() {
    DateTime now = DateTime.now();
    int daysSinceSemesterStart = now.difference(_semesterStart).inDays;
    setState(() {
      _currentWeek = (daysSinceSemesterStart / 7).floor() + 1;
    });
  }

  // 加载课程数据
  Future<void> _loadEvents() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final events = await _databaseService.getEvents();
      setState(() {
        _events = events;
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
            onPressed: _loadEvents,
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
    // 获取当前日期
    DateTime today = DateTime.now();
    
    // 筛选今天的课程
    List<Event> todayEvents = _events.where((event) {
      // 检查日期是否是今天
      DateTime eventDate = event.startTime;
      return eventDate.year == today.year && 
             eventDate.month == today.month && 
             eventDate.day == today.day;
    }).toList();
    
    // 按照开始时间排序
    todayEvents.sort((a, b) => a.startTime.compareTo(b.startTime));
    
    if (todayEvents.isEmpty) {
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
      itemCount: todayEvents.length,
      itemBuilder: (context, index) {
        final event = todayEvents[index];
        
        // 判断课程状态：未开始、进行中、已结束
        String status = _getEventStatus(event);
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
                  event.name,
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
                    Text('${_formatTime(event.startTime)} - ${_formatTime(event.endTime)}'),
                    SizedBox(width: 16),
                    Icon(Icons.location_on, size: 16, color: Colors.grey),
                    SizedBox(width: 4),
                    Text(event.location),
                  ],
                ),
                SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.description, size: 16, color: Colors.grey),
                    SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        event.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            onTap: () {
              // 点击课程显示详情
              _showEventDetails(event);
            },
          ),
        );
      },
    );
  }

  // 构建周视图
  Widget _buildWeekView() {
    // 获取本周的开始日期（周一）
    DateTime now = DateTime.now();
    DateTime weekStart = now.subtract(Duration(days: now.weekday - 1));
    
    // 筛选本周的课程
    List<Event> weekEvents = _events.where((event) {
      DateTime eventDate = event.startTime;
      DateTime weekEnd = weekStart.add(Duration(days: 6));
      return !eventDate.isBefore(weekStart) && !eventDate.isAfter(weekEnd);
    }).toList();
    
    if (weekEvents.isEmpty) {
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
    
    // 定义每天的时间段（按小时）
    int startHour = 8;  // 从早上8点开始
    int endHour = 22;   // 到晚上10点结束
    int totalHours = endHour - startHour;
    
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
                  width: 50,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    border: Border(right: BorderSide(color: Colors.grey.shade300)),
                  ),
                ),
                // 星期几栏
                ...List.generate(7, (index) {
                  DateTime dayDate = weekStart.add(Duration(days: index));
                  String dayStr = '${dayDate.month}/${dayDate.day}';
                  bool isToday = dayDate.year == now.year && 
                                 dayDate.month == now.month && 
                                 dayDate.day == now.day;
                  return Expanded(
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isToday ? Colors.blue.withOpacity(0.2) : null,
                        border: Border(right: BorderSide(color: Colors.grey.shade300)),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _weekdays[index],
                            style: TextStyle(
                              fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          Text(
                            dayStr,
                            style: TextStyle(fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
          
          // 课程表主体
          SizedBox(
            height: totalHours * 60.0,  // 每小时高度60
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 左侧时间栏
                SizedBox(
                  width: 50,
                  child: Column(
                    children: List.generate(totalHours, (index) {
                      int hour = index + startHour;
                      return Container(
                        height: 60,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          border: Border(
                            right: BorderSide(color: Colors.grey.shade300),
                            bottom: BorderSide(color: Colors.grey.shade300),
                          ),
                        ),
                        child: Text('$hour:00'),
                      );
                    }),
                  ),
                ),
                
                // 课程格子
                ...List.generate(7, (dayIndex) {
                  DateTime currentDay = weekStart.add(Duration(days: dayIndex));
                  
                  return Expanded(
                    child: Stack(
                      children: [
                        // 背景网格
                        Column(
                          children: List.generate(totalHours, (hourIndex) {
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
                        ...weekEvents.where((event) {
                          DateTime eventDate = event.startTime;
                          return eventDate.year == currentDay.year &&
                                 eventDate.month == currentDay.month &&
                                 eventDate.day == currentDay.day;
                        }).map((event) {
                          double startMinutes = (event.startTime.hour * 60 + event.startTime.minute).toDouble();
                          double endMinutes = (event.endTime.hour * 60 + event.endTime.minute).toDouble();
                          
                          // 计算位置
                          double top = (startMinutes - startHour * 60) * (60 / 60);
                          double height = (endMinutes - startMinutes) * (60 / 60);
                          
                          // 为每个课程生成随机但固定的颜色
                          Color eventColor = Color((math.Random(event.name.hashCode).nextDouble() * 0xFFFFFF).toInt()).withOpacity(1.0);
                          // 调整颜色亮度，让它不太暗也不太亮
                          HSLColor hslColor = HSLColor.fromColor(eventColor);
                          eventColor = hslColor.withLightness(0.7).withSaturation(0.5).toColor();
                          
                          return Positioned(
                            top: top,
                            left: 0,
                            right: 0,
                            height: height > 10 ? height : 10, // 最小高度为10
                            child: GestureDetector(
                              onTap: () => _showEventDetails(event),
                              child: Container(
                                margin: EdgeInsets.all(1),
                                padding: EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: eventColor,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      event.name,
                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (height > 40) // 只在足够高的情况下显示额外信息
                                      Text(
                                        event.location,
                                        style: TextStyle(fontSize: 10, color: Colors.white),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
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
  void _showEventDetails(Event event) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(event.name),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDetailRow(Icons.access_time, '开始时间', _formatDateTime(event.startTime)),
            _buildDetailRow(Icons.access_time_filled, '结束时间', _formatDateTime(event.endTime)),
            _buildDetailRow(Icons.location_on, '地点', event.location),
            _buildDetailRow(Icons.description, '描述', event.description),
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
  String _getEventStatus(Event event) {
    DateTime now = DateTime.now();
    if (now.isBefore(event.startTime)) {
      return '未开始';
    } else if (now.isAfter(event.endTime)) {
      return '已结束';
    } else {
      return '进行中';
    }
  }

  // 格式化时间 (HH:MM)
  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  // 格式化日期和时间
  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} ${_formatTime(dateTime)}';
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}