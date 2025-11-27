import 'package:flutter/material.dart';
import 'package:gestor_lds/features/meetings/models/meeting_model.dart';
import 'package:gestor_lds/features/meetings/screens/meeting_form_screen.dart';
import 'package:gestor_lds/features/meetings/services/meeting_service.dart';
import 'package:intl/intl.dart'; // Importar si deseas formato de fecha más legible
import 'package:gestor_lds/features/meetings/utils/meeting_types.dart';

class MeetingsListScreen extends StatelessWidget {
  const MeetingsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Instancia del servicio para obtener los datos
    final MeetingService meetingService = MeetingService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Registro de Reuniones'),
      ),
      body: StreamBuilder<List<MeetingModel>>(
        // Llama al stream que retorna la lista de reuniones
        stream: meetingService.getMeetings(),
        builder: (context, snapshot) {

          // 1. Manejo de Estado de Carga
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // 2. Manejo de Errores
          if (snapshot.hasError) {
            return Center(child: Text('Error al cargar reuniones: ${snapshot.error}'));
          }

          // 3. Manejo de Datos Vacíos
          final List<MeetingModel> meetings = snapshot.data ?? [];
          if (meetings.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.inbox, size: 60, color: Colors.grey),
                    SizedBox(height: 10),
                    Text(
                      'Aún no hay reuniones registradas.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            );
          }

          // 4. Mostrar la Lista de Reuniones
          return ListView.builder(
            itemCount: meetings.length,
            itemBuilder: (context, index) {
              final meeting = meetings[index];

              // Helper para formatear la fecha
              final String formattedDate = DateFormat('EEEE, d MMMM yyyy', 'es').format(meeting.date);

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                elevation: 2,
                child: ListTile(
                  leading: const Icon(Icons.event, color: Colors.indigo),
                  title: Text(
                    meeting.type.displayName, // Muestra el nombre legible del tipo
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '$formattedDate a las ${meeting.time}\nPreside: ${meeting.presidedBy}',
                  ),
                  onTap: () {
                    // TODO: Implementar navegación para ver detalles de la agenda
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MeetingFormScreen()));
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}