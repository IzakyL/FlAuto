import 'package:flutter/material.dart';
import '../../models/event.dart';

class EventListItem extends StatelessWidget {
  final Event event;
  final bool isActive;
  final VoidCallback onTap;

  const EventListItem({
    super.key,
    required this.event,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2.0,
      color: isActive ? Colors.blue.shade50 : null,
      child: ListTile(
        onTap: onTap,
        leading: Icon(Icons.event, color: isActive ? Colors.blue : Colors.grey),
        title: Text(
          event.name,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isActive ? Colors.blue.shade800 : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${event.startTime}-${event.endTime}节'),
            Text(event.location),
          ],
        ),
        trailing: isActive
            ? Icon(Icons.notifications_active, color: Colors.orange)
            : null,
      ),
    );
  }
}