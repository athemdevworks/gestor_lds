import 'package:flutter/material.dart';
import 'package:gestor_lds/features/auth/models/user_model.dart'; // Necesario para UserRole
import 'package:gestor_lds/features/meetings/models/meeting_model.dart';
import 'package:gestor_lds/features/meetings/services/meeting_service.dart';
import 'package:gestor_lds/features/meetings/utils/meeting_types.dart';
import 'package:gestor_lds/features/meetings/screens/meeting_form_screen.dart';
import 'package:gestor_lds/features/meetings/screens/meeting_detail_screen.dart';
import 'package:intl/intl.dart';

import '../../../core/widgets/empty_state_widget.dart';

class MeetingsListScreen extends StatelessWidget {
  // 1. Recibimos el usuario actual para saber sus permisos
  final UserModel currentUser;

  const MeetingsListScreen({super.key, required this.currentUser});

  @override
  Widget build(BuildContext context) {
    final MeetingService meetingService = MeetingService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Agenda de Reuniones'),
      ),
      // Solo mostramos el botón de crear si es Obispado o Líder (Miembros no crean)
      floatingActionButton: currentUser.role != UserRole.miembro
          ? FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const MeetingFormScreen()),
          );
        },
      )
          : null,
      body: StreamBuilder<List<MeetingModel>>(
        stream: meetingService.getMeetings(),
        builder: (context, snapshot) {

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final allMeetings = snapshot.data ?? [];

          if (allMeetings.isEmpty) {
            return const Center(child: Text('No hay reuniones programadas.'));
          }

          // -----------------------------------------------------------
          // 🧠 LÓGICA DE FILTRADO POR ROL Y ORGANIZACIÓN
          // -----------------------------------------------------------
          final filteredMeetings = allMeetings.where((meeting) {

            // CASO 1: Obispado ve TODO
            if (currentUser.role == UserRole.obispado) {
              return true;
            }

            // CASO 2: Líder de Organización
            if (currentUser.role == UserRole.lider) {
              // Ve reuniones generales (Consejo de Barrio)
              if (meeting.type == MeetingType.wardCouncil) return true;

              // Ve reuniones de SU PROPIA organización
              // (Ej: Si soy Primaria, veo reuniones donde organization == 'Primaria')
              if (meeting.organization == currentUser.organization) return true;
            }

            // CASO 3: Miembro (Solo ve Sacramentales y quizás generales)
            if (currentUser.role == UserRole.miembro) {
              if (meeting.type == MeetingType.sacramental) return true;
            }

            // Si no cumple nada, se oculta
            return false;
          }).toList();
          // -----------------------------------------------------------

          if (filteredMeetings.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.event_busy,
              title: 'Nada por aquí',
              message: 'No hay reuniones programadas para tu organización.',
            );
          }

          return ListView.builder(
            itemCount: filteredMeetings.length,
            itemBuilder: (context, index) {
              final meeting = filteredMeetings[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _getColorForType(meeting.type),
                    child: Icon(_getIconForType(meeting.type), color: Colors.white),
                  ),
                  title: Text(meeting.type.displayName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Mostramos la organización si es específica
                      if (meeting.organization != null)
                        Text(meeting.organization!, style: TextStyle(color: Colors.blue.shade800, fontWeight: FontWeight.w500)),

                      Text('${DateFormat('dd/MM/yyyy').format(meeting.date)} - ${meeting.time}'),
                      Text('Preside: ${meeting.presidedBy}'),
                    ],
                  ),
                  isThreeLine: true,
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => MeetingDetailScreen(meeting: meeting),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  // Helpers visuales
  Color _getColorForType(MeetingType type) {
    switch (type) {
      case MeetingType.bishopric: return const Color(0xFF164772); // Azul Obispado
      case MeetingType.wardCouncil: return Colors.orange.shade800;
      case MeetingType.presidency: return Colors.green.shade700;
      case MeetingType.sacramental: return Colors.purple.shade700;
      case MeetingType.interview: return Colors.teal;
      default: return Colors.grey;
    }
  }

  IconData _getIconForType(MeetingType type) {
    switch (type) {
      case MeetingType.bishopric: return Icons.security;
      case MeetingType.wardCouncil: return Icons.groups;
      case MeetingType.presidency: return Icons.assignment_ind;
      case MeetingType.sacramental: return Icons.home; // Icono de capilla
      case MeetingType.interview: return Icons.record_voice_over;
      default: return Icons.event;
    }
  }
}