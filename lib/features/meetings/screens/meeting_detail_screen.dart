import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import '../../../core/utils/alert_utils.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';

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

          // --- NUEVO: BOTÓN COPIAR PARA WHATSAPP ---
          IconButton(
            icon: const Icon(Icons.copy_all),
            tooltip: 'Copiar para WhatsApp',
            onPressed: () => _copyAgendaForWhatsApp(context),
          ),

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
                if (context.mounted) {
                  showErrorDialog(
                      context,
                      'Error de Impresión',
                      'No se pudo generar el PDF. Detalle: ${e.toString()}'
                  );
                }
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
            _buildHeader(
                meeting.type.displayName,
                formattedDate,
                meeting.time,
                meeting.organization // <--- Nuevo argumento
            ),
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
            // B. AGENDA LIDERAZGO (DINAMICA)
            else if (hasAgendaItems)
            // Envolvemos la lista en un StreamBuilder para escuchar cambios en los compromisos
              StreamBuilder<List<CommitmentModel>>(
                stream: CommitmentService().getCommitmentsByMeeting(meeting.id),
                builder: (context, snapshot) {

                  // Obtenemos la lista completa de compromisos de esta reunión
                  final allCommitments = snapshot.data ?? [];

                  return Column(
                    children: meeting.agendaItems!.map((agendaItem) {

                      // 🧠 FILTRO INTELIGENTE:
                      // Buscamos solo los compromisos que pertenecen a ESTE punto de agenda
                      final relatedCommitments = allCommitments
                          .where((c) => c.agendaItemId == agendaItem.id)
                          .toList();

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. EL PADRE (Punto de Agenda)
                          Card(
                            elevation: 2,
                            margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // CABECERA DEL ITEM
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Icon(Icons.label_important, color: Theme.of(context).primaryColor, size: 20),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              agendaItem.topic,
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Presentado por: ${agendaItem.assignedTo}',
                                              style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                                            ),
                                          ],
                                        ),
                                      ),

                                      // BOTONES DE ACCIÓN (Agregar / Menú)
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.add_task, color: Colors.blue),
                                            tooltip: 'Agregar Compromiso',
                                            onPressed: () => _showAddCommitmentDialog(context, agendaItem),
                                          ),
                                          PopupMenuButton<String>(
                                            icon: const Icon(Icons.more_vert, color: Colors.grey),
                                            onSelected: (value) {
                                              if (value == 'edit') {
                                                _editAgendaItem(context, agendaItem);
                                              } else if (value == 'delete') {
                                                _deleteAgendaItem(context, agendaItem);
                                              }
                                            },
                                            itemBuilder: (context) => [
                                              const PopupMenuItem(
                                                value: 'edit',
                                                child: Row(children: [Icon(Icons.edit, size: 18), SizedBox(width: 8), Text('Editar Punto')]),
                                              ),
                                              const PopupMenuItem(
                                                value: 'delete',
                                                child: Row(children: [Icon(Icons.delete, size: 18, color: Colors.red), SizedBox(width: 8), Text('Eliminar Punto', style: TextStyle(color: Colors.red))]),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),

                                  // 2. LISTA DE COMPROMISOS (LOS HIJOS)
                                  if (relatedCommitments.isNotEmpty) ...[
                                    const Padding(
                                      padding: EdgeInsets.symmetric(vertical: 8.0),
                                      child: Divider(height: 1),
                                    ),
                                    const Text(
                                      'Compromisos:',
                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
                                    ),
                                    const SizedBox(height: 4),

                                    Column(
                                      children: relatedCommitments.map((commitment) {
                                        return Padding(
                                          padding: const EdgeInsets.only(left: 8.0, top: 4.0, bottom: 4.0),
                                          child: Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              // Checkbox funcional
                                              SizedBox(
                                                width: 20,
                                                height: 20,
                                                child: Checkbox(
                                                  value: commitment.isCompleted,
                                                  onChanged: (val) {
                                                    if (val != null) {
                                                      CommitmentService().toggleCompletion(commitment.id, val);
                                                    }
                                                  },
                                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                ),
                                              ),
                                              const SizedBox(width: 8),

                                              // Texto del compromiso
                                              Expanded(
                                                child: RichText(
                                                  text: TextSpan(
                                                    style: TextStyle(
                                                      color: commitment.isCompleted ? Colors.grey : Colors.black87,
                                                      fontSize: 13,
                                                      decoration: commitment.isCompleted ? TextDecoration.lineThrough : null,
                                                    ),
                                                    children: [
                                                      TextSpan(text: commitment.description),
                                                      TextSpan(
                                                        text: ' (Resp: ${commitment.responsibleName ?? 'Asignado'})',
                                                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),

                                              // Menú del Compromiso (Editar/Borrar)
                                              PopupMenuButton<String>(
                                                icon: const Icon(Icons.more_vert, size: 16, color: Colors.grey),
                                                padding: EdgeInsets.zero,
                                                constraints: const BoxConstraints(minWidth: 20, maxWidth: 150),
                                                onSelected: (value) {
                                                  if (value == 'edit') {
                                                    showDialog(
                                                      context: context,
                                                      builder: (context) => NewCommitmentModal(
                                                        meetingId: meeting.id,
                                                        agendaItems: meeting.agendaItems,
                                                        commitmentToEdit: commitment,
                                                      ),
                                                    );
                                                  } else if (value == 'delete') {
                                                    CommitmentService().deleteCommitment(commitment.id);
                                                  }
                                                },
                                                itemBuilder: (context) => [
                                                  const PopupMenuItem(value: 'edit', height: 30, child: Text('Editar', style: TextStyle(fontSize: 12))),
                                                  const PopupMenuItem(value: 'delete', height: 30, child: Text('Eliminar', style: TextStyle(fontSize: 12, color: Colors.red))),
                                                ],
                                              ),
                                            ],
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ]
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 10), // Espacio entre tarjetas
                        ],
                      );
                    }).toList(),
                  );
                },
              ),

            if (!hasAgendaItems && meeting.sacramentAgenda == null)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Text('Esta reunión no tiene agenda detallada.', style: TextStyle(fontStyle: FontStyle.italic)),
              ),
          ],
        ),
      ),
    );
  }

  // --- MÉTODOS AUXILIARES ---

  // Método para abrir el modal de Nuevo Compromiso
  void _showAddCommitmentDialog(BuildContext context, AgendaItemModel item) {
    showDialog(
      context: context,
      builder: (context) => NewCommitmentModal(
        meetingId: meeting.id,
        agendaItems: meeting.agendaItems,
        initialAgendaItem: item, // Pre-selecciona este ítem
      ),
    );
  }

  Widget _buildSacramentAgendaView(SacramentAgendaModel agenda) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Protocolo y Música', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        _buildSimpleItem('Anuncios', agenda.announcements, icon: Icons.campaign),
        _buildSimpleItem('Himno Apertura', agenda.openingHymn, icon: Icons.music_note),
        _buildSimpleItem('Oración Apertura', agenda.openingPrayer, icon: Icons.person_outline),
        _buildSimpleItem('Himno Sacramental', agenda.sacramentHymn, icon: Icons.music_note),
        if (agenda.wardBusiness.isNotEmpty) ...[
          const SizedBox(height: 15),
          const Text('Asuntos del Barrio', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.indigo)),
          const Divider(),
          ...agenda.wardBusiness.map((business) {
            IconData icon;
            Color color;
            switch (business.type) {
              case 'Sostenimiento': icon = Icons.thumb_up; color = Colors.green; break;
              case 'Relevo': icon = Icons.handshake; color = Colors.orange; break;
              case 'Ordenación al Sacerdocio': icon = Icons.arrow_upward; color = Colors.blue; break;
              case 'Confirmación': icon = Icons.water_drop; color = Colors.cyan; break;
              case 'Bendición de niño' : icon = Icons.boy; color = Colors.blueGrey; break;
              default: icon = Icons.info_outline; color = Colors.grey;
            }
            return ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Icon(icon, color: color, size: 20),
              title: Text('${business.type}: ${business.personName}', style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: business.calling != null ? Text(business.calling!) : null,
            );
          }).toList(),
          const SizedBox(height: 15),
        ],

        const Divider(height: 30),

        if (agenda.isFastAndTestimony)
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.yellow.shade100, borderRadius: BorderRadius.circular(8)),
            child: const Text('¡Domingo de Ayuno y Testimonio! No hay discursos asignados.', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
          )
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Discursos Asignados', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              _buildSimpleItem('1er Discurso', '${agenda.firstSpeakerName}: ${agenda.firstSpeakerTopic}', icon: Icons.mic),
              _buildSimpleItem('Himno Especial', agenda.intermediateHymn ?? 'No asignado', icon: Icons.music_video),
              _buildSimpleItem('2do Discurso', '${agenda.secondSpeakerName}: ${agenda.secondSpeakerTopic}', icon: Icons.mic),
            ],
          ),

        const Divider(height: 30),
        _buildSimpleItem('Himno Cierre', agenda.closingHymn, icon: Icons.music_note),
        _buildSimpleItem('Oración Cierre', agenda.closingPrayer, icon: Icons.person_outline),
      ],
    );
  }

  // Widget simple para ítems sacramentales (sin editar/borrar)
  Widget _buildSimpleItem(String title, String subtitle, {required IconData icon}) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: Colors.indigo.shade300),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle),
    );
  }

  Widget _buildHeader(String title, String date, String time, String? organization) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
        if (organization != null)
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Text(
                  organization,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue.shade800)
              ),
            ),
          ),
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
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                await MeetingService().deleteMeeting(meeting.id);
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteAgendaItem(BuildContext context, AgendaItemModel itemToDelete) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar Punto de Agenda'),
        content: const Text('¿Estás seguro? Los compromisos asociados quedarán desvinculados visualmente.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Eliminar', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      final updatedList = List<AgendaItemModel>.from(meeting.agendaItems!);
      updatedList.removeWhere((item) => item.id == itemToDelete.id);

      await MeetingService().updateMeeting(
        id: meeting.id,
        type: meeting.type,
        date: meeting.date,
        time: meeting.time,
        presidedBy: meeting.presidedBy,
        directedBy: meeting.directedBy,
        organization: meeting.organization,
        sacramentAgenda: meeting.sacramentAgenda,
        agendaItems: updatedList,
        commitments: meeting.commitments,
      );
    }
  }

  Future<void> _editAgendaItem(BuildContext context, AgendaItemModel itemToEdit) async {
    final topicCtrl = TextEditingController(text: itemToEdit.topic);
    final assignedCtrl = TextEditingController(text: itemToEdit.assignedTo);

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Editar Punto'),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 10),
                  TextField(
                    controller: topicCtrl,
                    maxLines: null,
                    minLines: 1,
                    keyboardType: TextInputType.multiline,
                    decoration: const InputDecoration(labelText: 'Asunto', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: assignedCtrl,
                    maxLines: null,
                    minLines: 1,
                    keyboardType: TextInputType.multiline,
                    decoration: const InputDecoration(labelText: 'Responsable', border: OutlineInputBorder()),
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              final updatedItem = AgendaItemModel(
                id: itemToEdit.id,
                topic: topicCtrl.text,
                assignedTo: assignedCtrl.text,
                isCompleted: itemToEdit.isCompleted,
              );

              final updatedList = List<AgendaItemModel>.from(meeting.agendaItems!);
              final index = updatedList.indexWhere((i) => i.id == itemToEdit.id);
              if (index != -1) {
                updatedList[index] = updatedItem;
              }

              await MeetingService().updateMeeting(
                id: meeting.id,
                type: meeting.type,
                date: meeting.date,
                time: meeting.time,
                presidedBy: meeting.presidedBy,
                directedBy: meeting.directedBy,
                organization: meeting.organization,
                sacramentAgenda: meeting.sacramentAgenda,
                agendaItems: updatedList,
                commitments: meeting.commitments,
              );

              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  // FUNCIÓN PARA COPIAR AGENDA A WHATSAPP
  Future<void> _copyAgendaForWhatsApp(BuildContext context) async {

    final String formattedDate = DateFormat('EEEE, d MMMM yyyy', 'es').format(meeting.date);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Generando resumen...')),
    );

    try {
      // 1. Recuperar compromisos (Consulta rápida)
      List<CommitmentModel> fetchedCommitments = [];
      if (meeting.type != MeetingType.sacramental) {
        final snapshot = await FirebaseFirestore.instance
            .collection('commitments')
            .where('meetingId', isEqualTo: meeting.id)
            .get();
        fetchedCommitments = snapshot.docs
            .map((doc) => CommitmentModel.fromMap(doc.data(), doc.id))
            .toList();
      }

      // 2. Construir el Texto
      final buffer = StringBuffer();

      // Encabezado
      buffer.writeln('*AGENDA DE REUNIÓN*');
      buffer.writeln('*${meeting.type.displayName}*');
      if (meeting.organization != null) buffer.writeln('_${meeting.organization}_');
      buffer.writeln('');
      buffer.writeln('📅 *Fecha:* $formattedDate'); // Asegúrate que 'formattedDate' esté accesible o usa DateFormat aquí
      buffer.writeln('⏰ *Hora:* ${meeting.time}');
      buffer.writeln('👤 *Preside:* ${meeting.presidedBy}');
      buffer.writeln('🗣️ *Dirige:* ${meeting.directedBy}');
      buffer.writeln('');
      buffer.writeln('--- *PUNTOS DE AGENDA* ---');

      // Puntos de Agenda
      if (meeting.agendaItems != null && meeting.agendaItems!.isNotEmpty) {
        for (var item in meeting.agendaItems!) {
          buffer.writeln('');
          buffer.writeln('🔹 *${item.topic}*');
          buffer.writeln('   _Presenta: ${item.assignedTo}_');

          // Filtrar compromisos de este punto
          final itemCommitments = fetchedCommitments
              .where((c) => c.agendaItemId == item.id)
              .toList();

          if (itemCommitments.isNotEmpty) {
            buffer.writeln('   📝 *Asignaciones:*');
            for (var c in itemCommitments) {
              final status = c.isCompleted ? '✅' : '⬜';
              buffer.writeln('   $status ${c.description} (Resp: ${c.responsibleName})');
            }
          }
        }
      } else {
        buffer.writeln('No hay puntos registrados.');
      }

      // 3. Copiar al Portapapeles
      await Clipboard.setData(ClipboardData(text: buffer.toString()));

      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Copiado! Listo para pegar en WhatsApp.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }

    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al copiar: $e'), backgroundColor: Colors.red)
        );
      }
    }
  }

}