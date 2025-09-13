import 'package:flutter/material.dart';

class ReminderTile extends StatelessWidget {
  final String title;
  final String time;

  const ReminderTile(this.title, this.time, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(children: [
            const Icon(Icons.alarm, size: 18),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(fontSize: 15)),
          ]),
          Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.blue[200],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(time,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.black)),
          )
        ],
      ),
    );
  }
}
