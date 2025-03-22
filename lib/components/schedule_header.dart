import 'package:flutter/material.dart';

class ScheduleHeader extends StatelessWidget {
  final DateTime selectedDay;
  final List<String> weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
  final int? currentWeek;

  ScheduleHeader({
    super.key,
    required this.selectedDay,
    this.currentWeek,
  });

  @override
  Widget build(BuildContext context) {
    final weekday = weekdays[selectedDay.weekday - 1];
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '${selectedDay.month}月${selectedDay.day}日 $weekday',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (currentWeek != null)
            Chip(
              label: Text('第$currentWeek周'),
              backgroundColor: Colors.blue.shade100,
            ),
        ],
      ),
    );
  }
}