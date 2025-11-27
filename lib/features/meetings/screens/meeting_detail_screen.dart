import 'package:flutter/material.dart';
import 'package:gestor_lds/features/meetings/models/meeting_model.dart';
import 'package:intl/intl.dart';

import '../utils/meeting_types.dart';
import 'meeting_form_screen.dart';

class MeetingDetailScreen extends StatelessWidget {
  final MeetingModel meeting;

  const MeetingDetailScreen({super.key, required this.meeting});

  @override
  Widget build(BuildContext context) {
    // Formateo de fecha y hora
    final String formattedDate = DateFormat('EEEE, d MMMM yyyy', 'es').format(meeting.date);

    // Verifica si la reunión tiene agenda dinámica
    final bool hasAgendaItems = meeting.agendaItems != null && meeting.agendaItems!.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(meeting.type.displayName),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // Navega a la pantalla de formulario, pasando la reunión para edición
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) =>  MeetingFormScreen(meetingToEdit: meeting),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- BLOQUE DE DETALLES BÁSICOS ---
            _buildHeader(meeting.type.displayName, formattedDate, meeting.time),
            const Divider(height: 30),

            _buildDetailRow(Icons.person, 'Preside', meeting.presidedBy),
            _buildDetailRow(Icons.group, 'Dirige', meeting.directedBy),

            // --- BLOQUE DE AGENDA Y COMPROMISOS ---
            const SizedBox(height: 30),
            const Text('Agenda de Reunión', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo)),
            const Divider(),

            if (hasAgendaItems)
              ...meeting.agendaItems!.map((item) => ListTile(
                leading: const Icon(Icons.push_pin, color: Colors.indigoAccent),
                title: Text(item.topic, style: const TextStyle(fontWeight: FontWeight.w500)),
                subtitle: Text('Responsable: ${item.assignedTo}'),
                trailing: item.isCompleted
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : const Icon(Icons.schedule, color: Colors.orange),
              )).toList(),

            if (!hasAgendaItems)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Text('Esta reunión no tiene puntos de agenda detallados.', style: TextStyle(fontStyle: FontStyle.italic)),
              ),

            // TODO: Integrar la lista de compromisos cuando la modelemos completamente
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String title, String date, String time) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.calendar_month, size: 18, color: Colors.grey),
            const SizedBox(width: 5),
            Text(date, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 15),
            const Icon(Icons.access_time, size: 18, color: Colors.grey),
            const SizedBox(width: 5),
            Text(time, style: const TextStyle(fontSize: 16)),
          ],
        ),
      ],
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.indigo),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
                Text(value),
              ],
            ),
          ),
        ],
      ),
    );
  }
}