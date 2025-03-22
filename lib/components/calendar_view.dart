import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../models/event.dart';

class CalendarView extends StatelessWidget {
  final DateTime selectedDay;
  final DateTime focusedDay;
  final Function(DateTime, DateTime) onDaySelected;
  final Map<DateTime, List<Event>> events;

  const CalendarView({
    super.key,
    required this.selectedDay,
    required this.focusedDay,
    required this.onDaySelected,
    required this.events,
  });

  @override
  Widget build(BuildContext context) {
    return TableCalendar(
      firstDay: DateTime.utc(2023, 1, 1),
      lastDay: DateTime.utc(2030, 12, 31),
      focusedDay: focusedDay,
      selectedDayPredicate: (day) {
        return isSameDay(selectedDay, day);
      },
      onDaySelected: onDaySelected,
      eventLoader: (day) {
        return events[day] ?? [];
      },
      calendarStyle: CalendarStyle(
        markersMaxCount: 3,
        todayDecoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.3),
          shape: BoxShape.circle,
        ),
        selectedDecoration: BoxDecoration(
          color: Colors.blue,
          shape: BoxShape.circle,
        ),
      ),
      headerStyle: HeaderStyle(
        formatButtonVisible: false,
        titleCentered: true,
      ),
    );
  }
}