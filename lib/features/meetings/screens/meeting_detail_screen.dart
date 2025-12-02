import 'package:flutter/material.dart';
import 'package:gestor_lds/features/meetings/models/meeting_model.dart';
import 'package:intl/intl.dart';
import 'package:gestor_lds/features/meetings/services/meeting_service.dart';
import 'package:gestor_lds/features/meetings/models/sacrament_agenda_model.dart';
import 'package:gestor_lds/features/meetings/utils/meeting_types.dart';
import 'package:printing/printing.dart';
import 'meeting_form_screen.dart';
import 'package:gestor_lds/features/meetings/services/pdf_service.dart';
import 'package:gestor_lds/features/commitments/widgets/new_commitment_modal.dart';

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

          // Botón de IMPRIMIR (NUEVO)
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: () async {
              // Muestra una barra de carga/espera
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Generando PDF... por favor, espere.')),
              );

              try {
                // 1. Generar el PDF
                final pdfBytes = await PdfService().generateAgendaPdf(meeting);

                // 2. Abrir el diálogo de impresión/compartir
                await Printing.sharePdf(bytes: pdfBytes, filename: 'Agenda_${meeting.id}.pdf');

              } catch (e) {
                // 3. Si falla, muestra el error en la barra
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error de impresión: ${e.toString()}. Verifique la Consola del Navegador.'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
          ),

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

          IconButton(
            icon: const Icon(Icons.delete_forever, color: Colors.red),
            onPressed: () => _confirmAndDelete(context), // Llama a la función de confirmación
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

          // LÓGICA CONDICIONAL DE AGENDA
                    if (meeting.type == MeetingType.sacramental && meeting.sacramentAgenda != null)
                  // A. AGENDA SACRAMENTAL (FIJA)
                  _buildSacramentAgendaView(meeting.sacramentAgenda!)
              else if (hasAgendaItems)
              // B. AGENDA DE LIDERAZGO (DINÁMICA)
              ...meeting.agendaItems!.map((item) => ListTile(
                  leading: const Icon(Icons.push_pin, color: Colors.indigoAccent),
                  title: Text(item.topic, style: const TextStyle(fontWeight: FontWeight.w500)),
                  subtitle: Text('Responsable: ${item.assignedTo}'),
                // MODIFICAMOS EL TRAILING PARA TENER DOS ACCIONES
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 1. Botón para crear compromiso vinculado a ESTE punto
                    IconButton(
                      icon: const Icon(Icons.add_task, color: Colors.blue),
                      tooltip: 'Asignar Compromiso',
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => NewCommitmentModal(
                            meetingId: meeting.id,
                            agendaItems: meeting.agendaItems,
                            initialAgendaItem: item, // <-- ¡AQUÍ PASAMOS EL ÍTEM ESPECÍFICO!
                          ),
                        );
                      },
                    ),

                    // 2. Icono de estado (Completado o Pendiente)
                    item.isCompleted
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : const Icon(Icons.schedule, color: Colors.orange),
                  ],
                ),
              )).toList(),

              if (!hasAgendaItems && meeting.sacramentAgenda == null)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Text('Esta reunión no tiene agenda detallada.', style: TextStyle(fontStyle: FontStyle.italic)),
              ),

          // TODO: Integrar la lista de compromisos cuando la modelemos completamente
          ],
        ),
      ),
    );
  }

  Widget _buildAgendaItem(String label, String value, {IconData icon = Icons.check_circle_outline, Color color = Colors.black87}) {
    if (value.isEmpty) return const SizedBox.shrink(); // Oculta si está vacío
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(value),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSacramentAgendaView(SacramentAgendaModel agenda) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Protocolo y Música', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        _buildAgendaItem('Himno Apertura', agenda.openingHymn, icon: Icons.music_note),
        _buildAgendaItem('Oración Apertura', agenda.openingPrayer, icon: Icons.person_outline),
        _buildAgendaItem('Himno Sacramental', agenda.sacramentHymn, icon: Icons.music_note),
        _buildAgendaItem('Anuncios', agenda.announcements, icon: Icons.campaign),

        const Divider(height: 30),

        // LÓGICA DEL DOMINGO DE AYUNO
        if (agenda.isFastAndTestimony)
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.yellow.shade100, borderRadius: BorderRadius.circular(8)),
            child: const Text('¡Domingo de Ayuno y Testimonio! No hay discursos asignados.', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
          )
        else
        // ORDEN DE DISCURSOS
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Discursos Asignados', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              _buildAgendaItem('1er Discurso', '${agenda.firstSpeakerName}: ${agenda.firstSpeakerTopic}', icon: Icons.mic),
              _buildAgendaItem('Himno Especial', agenda.intermediateHymn ?? 'No asignado', icon: Icons.music_video),
              _buildAgendaItem('2do Discurso', '${agenda.secondSpeakerName}: ${agenda.secondSpeakerTopic}', icon: Icons.mic),
            ],
          ),

        const Divider(height: 30),
        _buildAgendaItem('Himno Cierre', agenda.closingHymn, icon: Icons.music_note),
        _buildAgendaItem('Oración Cierre', agenda.closingPrayer, icon: Icons.person_outline),
      ],
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

  void _confirmAndDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar Eliminación'),
          content: const Text('¿Estás seguro de que deseas eliminar esta reunión y toda su agenda? Esta acción no se puede deshacer.'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(), // Cierra el diálogo
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                // 1. Eliminar de Firestore
                await MeetingService().deleteMeeting(meeting.id);

                // 2. Cerrar el diálogo
                Navigator.of(context).pop();

                // 3. Regresar a la lista de reuniones
                Navigator.of(context).pop();
              },
              child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

}