import 'package:flutter/material.dart';
import '../../models/event.dart';

class TimeSlotGrid extends StatelessWidget {
  final List<Event> eventsForDay;
  final Function(Event) onEventTap;

  const TimeSlotGrid({
    super.key,
    required this.eventsForDay,
    required this.onEventTap,
  });

  @override
  Widget build(BuildContext context) {
    // 一天的课程时间段（1-12节课）
    final timeSlots = List.generate(12, (index) => index + 1);
    
    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: timeSlots.length,
        itemBuilder: (context, index) {
          final slot = timeSlots[index];
          final slotEvents = eventsForDay.where((event) {
            return event.startTime.hour <= slot && 
                   event.endTime.hour >= slot;
          }).toList();
          
          return Container(
            width: 60,
            margin: EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.all(4),
                  color: Colors.blue.shade50,
                  child: Text(
                    '$slot',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: slotEvents.isEmpty
                      ? Center(child: Text('-'))
                      : InkWell(
                          onTap: () => onEventTap(slotEvents.first),
                          child: Container(
                            color: Colors.blue.shade100,
                            padding: EdgeInsets.all(4),
                            alignment: Alignment.center,
                            child: Text(
                              slotEvents.first.name,
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 3,
                            ),
                          ),
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}