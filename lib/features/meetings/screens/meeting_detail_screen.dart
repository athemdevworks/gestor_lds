import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
// LIBRERÍA NUEVA
import 'package:add_2_calendar/add_2_calendar.dart';

import 'package:gestor_lds/core/utils/alert_utils.dart';
import 'package:gestor_lds/features/meetings/models/meeting_model.dart';
import 'package:gestor_lds/features/meetings/models/sacrament_agenda_model.dart';
import 'package:gestor_lds/features/meetings/models/agenda_item_model.dart';
import 'package:gestor_lds/features/meetings/services/meeting_service.dart';
import 'package:gestor_lds/features/meetings/services/pdf_service.dart';
import 'package:gestor_lds/features/meetings/utils/meeting_types.dart';
import 'package:gestor_lds/features/meetings/screens/meeting_form_screen.dart';
import 'package:gestor_lds/features/commitments/widgets/new_commitment_modal.dart';
import 'package:gestor_lds/features/commitments/models/commitment_model.dart';
import 'package:gestor_lds/features/commitments/services/commitment_service.dart';
import 'package:gestor_lds/features/communications/services/citation_service.dart';

class MeetingDetailScreen extends StatelessWidget {
  final MeetingModel meeting;

  const MeetingDetailScreen({super.key, required this.meeting});

  @override
  Widget build(BuildContext context) {
    final String formattedDate = DateFormat('EEEE, d MMMM yyyy', 'es').format(
        meeting.date);
    final bool hasAgendaItems = meeting.agendaItems != null &&
        meeting.agendaItems!.isNotEmpty;

    final CitationService citationService = CitationService();

    return Scaffold(
      appBar: AppBar(
        title: Text(meeting.type.displayName),
        actions: [
          // 1. NUEVO: AGREGAR A CALENDARIO
          IconButton(
            icon: const Icon(Icons.event_available),
            tooltip: 'Agendar en mi celular',
            onPressed: () => _addToDeviceCalendar(context),
          ),

          // 2. COPIAR WHATSAPP
          IconButton(
            icon: const Icon(Icons.copy_all),
            tooltip: 'Copiar para WhatsApp',
            onPressed: () => _copyAgendaForWhatsApp(context),
          ),

          // 3. IMPRIMIR ACTA
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Imprimir Agenda',
            onPressed: () async {
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Generando PDF...')));
              try {
                final pdfBytes = await PdfService().generateAgendaPdf(meeting);

                // --- LÓGICA DE NOMBRE ---
                // Formato: Agenda_Consejo_Barrio_20231025.pdf
                final safeTypeName = meeting.type.displayName.replaceAll(
                    ' ', '_');
                final dateStr = DateFormat('yyyyMMdd').format(meeting.date);
                final fileName = 'Agenda_${safeTypeName}_$dateStr.pdf';
                // -----------------------

                await Printing.sharePdf(bytes: pdfBytes, filename: fileName);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Error: $e'), backgroundColor: Colors.red));
                }
              }
            },
          ),

          // MENÚ DE EDICIÓN / ELIMINACIÓN
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'edit') {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) =>
                      MeetingFormScreen(meetingToEdit: meeting)),
                );
              } else if (value == 'delete') {
                _confirmAndDelete(context);
              }
            },
            itemBuilder: (context) =>
            [
              const PopupMenuItem(value: 'edit',
                  child: Row(children: [
                    Icon(Icons.edit, color: Colors.blue),
                    SizedBox(width: 8),
                    Text("Editar")
                  ])),
              const PopupMenuItem(value: 'delete',
                  child: Row(children: [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 8),
                    Text("Eliminar")
                  ])),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(meeting.type.displayName, formattedDate, meeting.time,
                meeting.organization),
            const Divider(height: 30),

            _buildDetailRow(Icons.person, 'Preside', meeting.presidedBy),
            _buildDetailRow(Icons.group, 'Dirige', meeting.directedBy),

            const SizedBox(height: 30),
            const Text('Agenda de Reunión', style: TextStyle(fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.indigo)),
            const Divider(),

            if (meeting.type == MeetingType.sacramental &&
                meeting.sacramentAgenda != null)
              _buildSacramentAgendaView(
                  context, meeting.sacramentAgenda!, citationService,
                  meeting.date)
            else
              if (hasAgendaItems)
                _buildLeadershipAgendaView(context),

            if (!hasAgendaItems && meeting.sacramentAgenda == null)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Text('Esta reunión no tiene agenda detallada.',
                    style: TextStyle(fontStyle: FontStyle.italic)),
              ),
          ],
        ),
      ),
    );
  }

  // --- FUNCIÓN PARA AGREGAR AL CALENDARIO ---
  void _addToDeviceCalendar(BuildContext context) {
    // 1. Intentar parsear la hora del string (ej: "10:30 AM")
    DateTime startDate = meeting.date;
    try {
      // Asumiendo que meeting.time viene en formato "10:30 AM" o similar
      // Si tu app usa otro formato, ajusta el patrón aquí.
      // Usamos DateFormat.jm() para "10:30 AM"
      // Usamos DateFormat.Hm() para "14:30"
      final timeParts = DateFormat.jm().parse(meeting.time);

      startDate = DateTime(
        meeting.date.year,
        meeting.date.month,
        meeting.date.day,
        timeParts.hour,
        timeParts.minute,
      );
    } catch (e) {
      // Si falla el parseo de hora (ej: texto libre), usamos la fecha base a las 8 AM
      startDate = DateTime(
          meeting.date.year, meeting.date.month, meeting.date.day, 8, 0);
      print("Error parseando hora: $e");
    }

    final DateTime endDate = startDate.add(
        const Duration(hours: 1)); // Duración por defecto: 1 hora

    final Event event = Event(
      title: meeting.type.displayName,
      description: 'Preside: ${meeting.presidedBy}\nDirige: ${meeting
          .directedBy}\nOrganización: ${meeting.organization ?? "General"}',
      location: 'Capilla Nuevo Trujillo',
      startDate: startDate,
      endDate: endDate,
      allDay: false,
    );

    Add2Calendar.addEvent2Cal(event);
  }

  // --- RESTO DE WIDGETS (Mantenidos igual que antes) ---

  Widget _buildLeadershipAgendaView(BuildContext context) {
    return StreamBuilder<List<CommitmentModel>>(
      stream: CommitmentService().getCommitmentsByMeeting(meeting.id),
      builder: (context, snapshot) {
        final allCommitments = snapshot.data ?? [];
        return Column(
          children: meeting.agendaItems!.map((agendaItem) {
            final relatedCommitments = allCommitments.where((c) =>
            c.agendaItemId == agendaItem.id).toList();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.label_important, color: Theme
                                .of(context)
                                .primaryColor, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(agendaItem.topic, style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16)),
                                  Text('Presentado por: ${agendaItem
                                      .assignedTo}', style: TextStyle(
                                      fontSize: 13, color: Colors.grey[700])),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                  Icons.add_task, color: Colors.blue),
                              onPressed: () =>
                                  _showAddCommitmentDialog(context, agendaItem),
                            ),
                          ],
                        ),
                        if (relatedCommitments.isNotEmpty) ...[
                          const Divider(),
                          ...relatedCommitments.map((c) =>
                              Text(
                              "• ${c.description}", style: TextStyle(
                              fontSize: 12, color: Colors.grey[800]))),
                        ]
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildSacramentAgendaView(BuildContext context,
      SacramentAgendaModel agenda, CitationService service, DateTime date) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Protocolo y Música',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        _buildSimpleItem(
            'Anuncios', agenda.announcements, icon: Icons.campaign),

        // --- CORRECCIÓN 1: AGREGAR PIANISTA Y DIRECTOR ---
        // Usamos un layout de fila para ahorrar espacio si ambos existen
        if (agenda.chorister.isNotEmpty || agenda.pianist.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              children: [
                if (agenda.chorister.isNotEmpty)
                  Expanded(child: _buildSimpleItem(
                      'Director(a) de Música', agenda.chorister,
                      icon: Icons.music_note, compact: true)),
                if (agenda.pianist.isNotEmpty)
                  Expanded(child: _buildSimpleItem(
                      'Pianista', agenda.pianist, icon: Icons.piano,
                      compact: true)),
                // Si Icons.piano da error, usa Icons.keyboard
              ],
            ),
          ),

        // --- CORRECCIÓN 2: CAMBIO DE NOMBRES ---
        _buildSimpleItem(
            'Primer Himno', agenda.openingHymn, icon: Icons.music_note),
        _buildPrintableItem(
            context, service, 'Primera Oración', agenda.openingPrayer,
            'PRIMERA ORACIÓN', date, icon: Icons.person_outline),

        // --- CORRECCIÓN 3: ASUNTOS DEL BARRIO CON LLAMAMIENTO ---
        if (agenda.wardBusiness.isNotEmpty) ...[
          const SizedBox(height: 15),
          const Text('Asuntos del Barrio', style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.w600, color: Colors.indigo)),
          const Divider(),
          ...agenda.wardBusiness.map((b) {
            // Mostramos "Sostenimiento: Juan Perez (Secretario)"
            final callingText = (b.calling != null && b.calling!.isNotEmpty)
                ? " (${b.calling})"
                : "";
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2.0),
              child: Text("• ${b.type}: ${b.personName}$callingText",
                  style: const TextStyle(fontSize: 14)),
            );
          }),
          const SizedBox(height: 15),
        ],

        _buildSimpleItem(
            'Himno Sacramental', agenda.sacramentHymn, icon: Icons.music_note),

        const Divider(),

        if (agenda.isFastAndTestimony)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text("✨ Domingo de Ayuno y Testimonio",
                style: TextStyle(fontWeight: FontWeight.bold)),
          )
        else
          Column(
            children: [
              _buildPrintableItem(context, service, '1er Discurso',
                  agenda.firstSpeakerName ?? '', 'PRIMER DISCURSO', date,
                  topic: agenda.firstSpeakerTopic,
                  icon: Icons.mic,
                  duration: "5"),
              _buildSimpleItem('Himno Especial', agenda.intermediateHymn ?? '',
                  icon: Icons.music_video),
              _buildPrintableItem(context, service, '2do Discurso',
                  agenda.secondSpeakerName ?? '', 'ULTIMO DISCURSO', date,
                  topic: agenda.secondSpeakerTopic,
                  icon: Icons.mic,
                  duration: "10"),
            ],
          ),

        const Divider(),

        // --- CORRECCIÓN 2: CAMBIO DE NOMBRES (CIERRE) ---
        _buildSimpleItem(
            'Último Himno', agenda.closingHymn, icon: Icons.music_note),
        _buildPrintableItem(
            context, service, 'Última Oración', agenda.closingPrayer,
            'ULTIMA ORACIÓN', date, icon: Icons.person_outline),
      ],
    );
  }

  // Helper actualizado para soportar modo compacto (opcional)
  Widget _buildSimpleItem(String title, String subtitle,
      {required IconData icon, bool compact = false}) {
    if (subtitle.isEmpty) return const SizedBox.shrink();
    return ListTile(
      contentPadding: EdgeInsets.zero,
      visualDensity: compact ? VisualDensity.compact : null,
      leading: Icon(icon, color: Colors.indigo.shade300),
      title: Text(title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 14)),
    );
  }

  Widget _buildPrintableItem(BuildContext context, CitationService service,
      String title, String personName, String type, DateTime date,
      {required IconData icon, String? topic, String? duration}) {
    if (personName.isEmpty) return const SizedBox.shrink();
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: Colors.indigo.shade300),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text('$personName ${topic != null ? "($topic)" : ""}'),
      trailing: IconButton(
        icon: const Icon(Icons.print, color: Colors.blueGrey),
        onPressed: () =>
            _printAssignment(
            context, service, personName, type, date, topic: topic,
            duration: duration),
      ),
    );
  }

  Future<void> _printAssignment(BuildContext context, CitationService service,
      String name, String type, DateTime date,
      {String? topic, String? duration}) async {
    bool? isMale = await showDialog<bool>(
      context: context,
      builder: (ctx) =>
          AlertDialog(
            title: Text('Esquela para $name'),
            content: const Text('¿Es Hermano o Hermana?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('HERMANA')),
              ElevatedButton(onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('HERMANO')),
            ],
          ),
    );
    if (isMale != null) {
      await service.generateSacramentAssignment(name: name,
          isMale: isMale,
          assignmentType: type,
          assignmentDate: date,
          time: '10:30 de la mañana',
          topic: topic,
          duration: duration ?? "8");
    }
  }

  Widget _buildHeader(String title, String date, String time,
      String? organization) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
        if(organization != null) Chip(label: Text(organization)),
        Text("$date - $time",
            style: const TextStyle(fontSize: 16, color: Colors.grey)),
      ],
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(children: [
      Icon(icon),
      const SizedBox(width: 8),
      Text("$label: $value")
    ]);
  }

  void _showAddCommitmentDialog(BuildContext context, AgendaItemModel item) {
    showDialog(context: context,
        builder: (_) =>
            NewCommitmentModal(meetingId: meeting.id,
            agendaItems: meeting.agendaItems,
            initialAgendaItem: item));
  }

  void _confirmAndDelete(BuildContext context) {
    showDialog(context: context, builder: (ctx) =>
        AlertDialog(
            title: const Text("Eliminar"), content: const Text("¿Seguro?"),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx),
                  child: const Text("Cancelar")),
              ElevatedButton(onPressed: () async {
                await MeetingService().deleteMeeting(meeting.id);
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  Navigator.pop(ctx);
                }
              }, child: const Text("Eliminar"))
            ]
        ));
  }

// --- FUNCIÓN MEJORADA: COPIAR DETALLE COMPLETO A WHATSAPP ---
  Future<void> _copyAgendaForWhatsApp(BuildContext context) async {
    final buffer = StringBuffer();

    // CABECERA
    buffer.writeln('📅 *${meeting.type.displayName.toUpperCase()}*');
    buffer.writeln('🗓 ${DateFormat('EEEE d MMMM', 'es').format(meeting.date)}');
    buffer.writeln('⏰ ${meeting.time}');
    if (meeting.organization != null) buffer.writeln(
        '🏛 ${meeting.organization}');
    buffer.writeln('-------------------------');
    buffer.writeln('👤 *Preside:* ${meeting.presidedBy}');
    buffer.writeln('🎤 *Dirige:* ${meeting.directedBy}');

    // LÓGICA SACRAMENTAL
    if (meeting.type == MeetingType.sacramental &&
        meeting.sacramentAgenda != null) {
      final agenda = meeting.sacramentAgenda!;

      // Música y Anuncios
      if (agenda.chorister.isNotEmpty) buffer.writeln(
          '🎶 *Director(a):* ${agenda.chorister}');
      if (agenda.pianist.isNotEmpty) buffer.writeln(
          '🎹 *Pianista:* ${agenda.pianist}');
      buffer.writeln('');

      if (agenda.announcements.isNotEmpty) {
        buffer.writeln('📣 *Anuncios:* ${agenda.announcements}');
        buffer.writeln('');
      }

      buffer.writeln('🎵 *Primer Himno:* ${agenda.openingHymn}');
      buffer.writeln('🙏 *Primera Oración:* ${agenda.openingPrayer}');
      buffer.writeln('');

      // Asuntos del Barrio
      if (agenda.wardBusiness.isNotEmpty) {
        buffer.writeln('📋 *Asuntos del Barrio:*');
        for (var item in agenda.wardBusiness) {
          final callingStr = (item.calling != null && item.calling!.isNotEmpty)
              ? " (${item.calling})"
              : "";
          buffer.writeln('  • ${item.type}: ${item.personName}$callingStr');
        }
        buffer.writeln('');
      }

      buffer.writeln('🍞 *Himno Sacramental:* ${agenda.sacramentHymn}');
      buffer.writeln('');

      if (agenda.isFastAndTestimony) {
        buffer.writeln('✨ *Domingo de Ayuno y Testimonios*');
      } else {
        // --- AQUÍ ESTÁ LA CORRECCIÓN DE LOS TEMAS ---

        // 1er Discurso
        if (agenda.firstSpeakerName != null &&
            agenda.firstSpeakerName!.isNotEmpty) {
          buffer.writeln('🗣 *1er Discurso:* ${agenda.firstSpeakerName}');
          if (agenda.firstSpeakerTopic != null &&
              agenda.firstSpeakerTopic!.isNotEmpty) {
            buffer.writeln('   _Tema: ${agenda.firstSpeakerTopic}_');
          }
        }

        // Himno Intermedio
        if (agenda.intermediateHymn != null &&
            agenda.intermediateHymn!.isNotEmpty) {
          buffer.writeln('');
          buffer.writeln('🎵 *Himno Especial:* ${agenda.intermediateHymn}');
          buffer.writeln('');
        }

        // 2do Discurso
        if (agenda.secondSpeakerName != null &&
            agenda.secondSpeakerName!.isNotEmpty) {
          buffer.writeln('🗣 *2do Discurso:* ${agenda.secondSpeakerName}');
          if (agenda.secondSpeakerTopic != null &&
              agenda.secondSpeakerTopic!.isNotEmpty) {
            buffer.writeln('   _Tema: ${agenda.secondSpeakerTopic}_');
          }
        }
      }

      buffer.writeln('');
      buffer.writeln('🎵 *Último Himno:* ${agenda.closingHymn}');
      buffer.writeln('🙏 *Última Oración:* ${agenda.closingPrayer}');
    }
    // LÓGICA OTRAS REUNIONES
    else if (meeting.agendaItems != null && meeting.agendaItems!.isNotEmpty) {
      buffer.writeln('📋 *AGENDA A TRATAR:*');
      for (var i = 0; i < meeting.agendaItems!.length; i++) {
        final item = meeting.agendaItems![i];
        buffer.writeln('${i + 1}. *${item.topic}*');
        if (item.assignedTo.isNotEmpty) buffer.writeln(
            '   _Presenta: ${item.assignedTo}_');
      }
    }

    buffer.writeln('');
    buffer.writeln('_Generado con GestorLDS_');

    await Clipboard.setData(ClipboardData(text: buffer.toString()));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('¡Agenda copiada con temas! 📋')));
    }
  }
}