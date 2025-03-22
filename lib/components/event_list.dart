import 'package:flutter/material.dart';
import '../../models/event.dart';

class EventList extends StatelessWidget {
  final List<Event> events;

  const EventList({
    super.key,
    required this.events,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '已导入的课程: ${events.length}',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              return ListTile(
                title: Text(event.name),
                subtitle: Text('${event.description} | ${event.location}'),
                trailing: Text(
                  '${event.startTime}-${event.endTime}节',
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}