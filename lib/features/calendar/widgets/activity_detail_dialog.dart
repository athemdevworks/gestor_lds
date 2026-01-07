import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../activities/models/activity_model.dart';

class ActivityDetailDialog extends StatelessWidget {
  final ActivityModel activity;

  const ActivityDetailDialog({super.key, required this.activity});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.event, color: Colors.blue.shade800),
          const SizedBox(width: 10),
          Expanded(child: Text(activity.title, style: const TextStyle(fontSize: 18))),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _infoRow(Icons.groups, activity.organization),
          const SizedBox(height: 10),
          _infoRow(Icons.calendar_today, DateFormat('EEEE d MMMM', 'es').format(activity.date)),
          const SizedBox(height: 10),
          _infoRow(Icons.access_time, activity.time),
          const SizedBox(height: 10),
          _infoRow(Icons.location_on, activity.location),
          if (activity.description.isNotEmpty) ...[
            const Divider(height: 20),
            Text(activity.description, style: const TextStyle(fontStyle: FontStyle.italic)),
          ]
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cerrar'),
        ),
      ],
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 8),
        Expanded(child: Text(text)),
      ],
    );
  }
}