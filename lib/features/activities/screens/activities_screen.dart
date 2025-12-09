import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:gestor_lds/features/activities/models/activity_model.dart';
import 'package:gestor_lds/features/activities/services/activity_service.dart';
import 'package:gestor_lds/features/activities/screens/activity_form_screen.dart';

class ActivitiesScreen extends StatelessWidget {
  const ActivitiesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Actividades del Barrio')),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const ActivityFormScreen()));
        },
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<List<ActivityModel>>(
        stream: ActivityService().getActivities(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No hay actividades programadas.'));
          }

          final activities = snapshot.data!;

          return ListView.builder(
            itemCount: activities.length,
            padding: const EdgeInsets.all(12),
            itemBuilder: (context, index) {
              final activity = activities[index];
              final isPast = activity.date.isBefore(DateTime.now().subtract(const Duration(days: 1)));

              return Card(
                elevation: 2,
                color: isPast ? Colors.grey[200] : Colors.white,
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isPast ? Colors.grey : _getColorForOrg(activity.organization),
                    child: Icon(Icons.event, color: Colors.white),
                  ),
                  title: Text(activity.title, style: TextStyle(fontWeight: FontWeight.bold, decoration: isPast ? TextDecoration.lineThrough : null)),
                  subtitle: Text('${DateFormat('dd/MM').format(activity.date)} - ${activity.time}\n${activity.organization}'),
                  isThreeLine: true,
                  trailing: IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => ActivityFormScreen(activityToEdit: activity)));
                    },
                  ),
                  onLongPress: () {
                    // Opcional: Eliminar
                    ActivityService().deleteActivity(activity.id);
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  Color _getColorForOrg(String org) {
    if (org.contains('Primaria')) return Colors.yellow.shade700;
    if (org.contains('Sociedad')) return Colors.amber;
    if (org.contains('Jóvenes')) return Colors.green;
    return Colors.blue;
  }
}