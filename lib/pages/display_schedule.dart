import 'package:flutter/material.dart';
import '../models/event.dart';
import '../services/database.dart';
import '../components/calendar_view.dart';
import '../components/event_list_item.dart';
import '../components/schedule_header.dart';
import '../components/time_slot_grid.dart';

class DisplaySchedulePage extends StatefulWidget {
  const DisplaySchedulePage({super.key});

  @override
  _DisplaySchedulePageState createState() => _DisplaySchedulePageState();
}

class _DisplaySchedulePageState extends State<DisplaySchedulePage> {
  final DatabaseService _databaseService = DatabaseService();
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  Map<DateTime, List<Event>> _events = {};
  List<Event> _selectedEvents = [];
  int? _currentWeek;
  Event? _selectedEvent;

  @override
  void initState() {
    super.initState();
    _loadEvents();
    _calculateCurrentWeek();
  }

  void _calculateCurrentWeek() {
    // 这里实现计算当前是第几教学周的逻辑
    // 示例: 假设学期开始于2024年2月26日（第1周周一）
    final DateTime semesterStart = DateTime(2024, 2, 26);
    final int daysDifference = DateTime.now().difference(semesterStart).inDays;
    final int weekNumber = (daysDifference / 7).floor() + 1;
    
    setState(() {
      _currentWeek = weekNumber > 0 ? weekNumber : 1;
    });
  }

  Future<void> _loadEvents() async {
    try {
      final events = await _databaseService.getEvents();
      final eventsByDay = _groupEventsByDay(events);
      
      setState(() {
        _events = eventsByDay;
        _updateSelectedEvents();
      });
    } catch (e) {
      print('Error loading events: $e');
    }
  }

  Map<DateTime, List<Event>> _groupEventsByDay(List<Event> events) {
    final Map<DateTime, List<Event>> eventsByDay = {};
    
    for (final event in events) {
      // 这里实现将事件按日期分组
      // 示例: 假设event.date是yyyy-MM-dd格式的字符串
      // 实际实现中需要根据你的数据模型调整
      DateTime eventDate;
      try {
        final dateString = event.startTime.toString();
        final parts = dateString.split('-');
        eventDate = DateTime(
          int.parse(parts[0]), 
          int.parse(parts[1]), 
          int.parse(parts[2])
        );
      } catch (e) {
        // 如果日期解析失败，使用今天的日期
        eventDate = DateTime.now();
      }
      
      // 标准化日期，去除时间部分
      final normalizedDate = DateTime(
        eventDate.year, 
        eventDate.month, 
        eventDate.day
      );
      
      if (!eventsByDay.containsKey(normalizedDate)) {
        eventsByDay[normalizedDate] = [];
      }
      eventsByDay[normalizedDate]!.add(event);
    }
    
    return eventsByDay;
  }

  void _updateSelectedEvents() {
    final normalizedSelectedDay = DateTime(
      _selectedDay.year, 
      _selectedDay.month, 
      _selectedDay.day
    );
    
    setState(() {
      _selectedEvents = _events[normalizedSelectedDay] ?? [];
    });
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
      _selectedEvent = null;
      _updateSelectedEvents();
    });
  }

  void _onEventSelected(Event event) {
    setState(() {
      _selectedEvent = event == _selectedEvent ? null : event;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('课程表'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadEvents,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 日历视图
            CalendarView(
              selectedDay: _selectedDay,
              focusedDay: _focusedDay,
              onDaySelected: _onDaySelected,
              events: _events,
            ),
            
            SizedBox(height: 16),
            
            // 日期和周次信息
            ScheduleHeader(
              selectedDay: _selectedDay,
              currentWeek: _currentWeek,
            ),
            
            SizedBox(height: 8),
            
            // 时间段网格
            TimeSlotGrid(
              eventsForDay: _selectedEvents,
              onEventTap: _onEventSelected,
            ),
            
            SizedBox(height: 16),
            
            // 事件列表标题
            Text(
              '课程安排',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            SizedBox(height: 8),
            
            // 事件列表
            Expanded(
              child: _selectedEvents.isEmpty
                ? Center(
                    child: Text(
                      '今天没有课程安排',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: _selectedEvents.length,
                    itemBuilder: (context, index) {
                      final event = _selectedEvents[index];
                      return EventListItem(
                        event: event,
                        isActive: event == _selectedEvent,
                        onTap: () => _onEventSelected(event),
                      );
                    },
                  ),
            ),
          ],
        ),
      ),
    );
  }
}