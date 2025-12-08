import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import '../../../core/utils/alert_utils.dart';
import 'meeting_form_screen.dart';
import 'package:intl/intl.dart';

import 'package:gestor_lds/features/meetings/models/meeting_model.dart';
import 'package:gestor_lds/features/meetings/models/sacrament_agenda_model.dart';
import 'package:gestor_lds/features/meetings/models/agenda_item_model.dart';
import 'package:gestor_lds/features/meetings/services/meeting_service.dart';
import 'package:gestor_lds/features/meetings/services/pdf_service.dart';
import 'package:gestor_lds/features/meetings/utils/meeting_types.dart';

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
            ),            const Divider(height: 30),

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
                                  ListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 0),
                                    leading: const Icon(Icons.label_important, color: Colors.indigo),
                                    title: Text(
                                      agendaItem.topic,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                    subtitle: Text('Presentado por: ${agendaItem.assignedTo}'),

                                    trailing:
                                      Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // 1. Botón de Agregar Tarea (Existente)
                                        IconButton(
                                          icon: const Icon(Icons.add_task, color: Colors.blue),
                                          tooltip: 'Agregar Compromiso a este tema',
                                          onPressed: () {
                                            showDialog(
                                              context: context,
                                              builder: (context) => NewCommitmentModal(
                                                meetingId: meeting.id,
                                                agendaItems: meeting.agendaItems,
                                                initialAgendaItem: agendaItem, // <-- Pasamos el ítem para pre-seleccionar
                                              ),
                                            );
                                          },
                                        ),
                                        // 2. NUEVO: Menú de Opciones (Editar / Eliminar)
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
                                  ),

                                  // 2. LOS HIJOS (Lista de Compromisos Anidados)
                                  if (relatedCommitments.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(left: 40.0, bottom: 10.0), // Sangría visual
                                      child: Column(
                                        children: relatedCommitments.map((commitment) {
                                          return Padding(
                                            padding: const EdgeInsets.symmetric(vertical: 2.0),
                                            child: Row(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                // Checkbox pequeño (visual o funcional)
                                                SizedBox(
                                                  width: 24,
                                                  height: 24,
                                                  child: Checkbox(
                                                    value: commitment.isCompleted,
                                                    onChanged: (val) {
                                                      // Permitimos marcar completado desde aquí también
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
                                                        fontSize: 14,
                                                        decoration: commitment.isCompleted ? TextDecoration.lineThrough : null,
                                                      ),
                                                      children: [
                                                        TextSpan(
                                                          text: "${commitment.responsibleName ?? 'Asignado'}: ",
                                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                                        ),
                                                        TextSpan(text: commitment.description),
                                                      ],
                                                    ),
                                                  ),
                                                ),

                                                // <---- MENÚ DE ACCIONES (Editar / Eliminar) ---->

                                                PopupMenuButton<String>(
                                                  icon: const Icon(Icons.more_vert, size: 18, color: Colors.grey),
                                                  padding: EdgeInsets.zero,
                                                  // Hacemos el menú más pequeño para que no estorbe
                                                  constraints: const BoxConstraints(minWidth: 20, maxWidth: 150),
                                                  onSelected: (value) {
                                                    if (value == 'edit') {
                                                      // ABRIR MODAL EN MODO EDICIÓN
                                                      showDialog(
                                                        context: context,
                                                        builder: (context) => NewCommitmentModal(
                                                          meetingId: meeting.id,
                                                          agendaItems: meeting.agendaItems,
                                                          commitmentToEdit: commitment, // Pasamos el compromiso a editar
                                                        ),
                                                      );
                                                    } else if (value == 'delete') {
                                                      // CONFIRMAR Y ELIMINAR
                                                      showDialog(
                                                        context: context,
                                                        builder: (ctx) => AlertDialog(
                                                          title: const Text('Eliminar Compromiso'),
                                                          content: const Text('¿Estás seguro de borrar esta asignación?'),
                                                          actions: [
                                                            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
                                                            TextButton(
                                                              onPressed: () {
                                                                CommitmentService().deleteCommitment(commitment.id);
                                                                Navigator.pop(ctx);
                                                              },
                                                              child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
                                                            ),
                                                          ],
                                                        ),
                                                      );
                                                    }
                                                  },
                                                  itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                                                    const PopupMenuItem<String>(
                                                      value: 'edit',
                                                      height: 30,
                                                      child: Row(children: [Icon(Icons.edit, size: 16), SizedBox(width: 8), Text('Editar', style: TextStyle(fontSize: 13))]),
                                                    ),
                                                    const PopupMenuItem<String>(
                                                      value: 'delete',
                                                      height: 30,
                                                      child: Row(children: [Icon(Icons.delete, size: 16, color: Colors.red), SizedBox(width: 8), Text('Eliminar', style: TextStyle(color: Colors.red, fontSize: 13))]),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ),

                                  const Divider(), // Separador entre temas
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
        _buildAgendaItem('Anuncios', agenda.announcements, icon: Icons.campaign),
        _buildAgendaItem('Himno Apertura', agenda.openingHymn, icon: Icons.music_note),
        _buildAgendaItem('Oración Apertura', agenda.openingPrayer, icon: Icons.person_outline),
        _buildAgendaItem('Himno Sacramental', agenda.sacramentHymn, icon: Icons.music_note),
        if (agenda.wardBusiness.isNotEmpty) ...[
          const SizedBox(height: 15),
          const Text('Asuntos del Barrio', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.indigo)),
          const Divider(),
          ...agenda.wardBusiness.map((business) {
            IconData icon;
            Color color;

            // Iconos dinámicos según el tipo
            switch (business.type) {
              case 'Sostenimiento': icon = Icons.thumb_up; color = Colors.green; break;
              case 'Relevo': icon = Icons.handshake; color = Colors.orange; break;
              case 'Adelanto Sacerdotal': icon = Icons.arrow_upward; color = Colors.blue; break;
              case 'Bautismo': icon = Icons.water_drop; color = Colors.cyan; break;
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

  Widget _buildHeader(String title, String date, String time, String? organization) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),

        // --- NUEVO: MOSTRAR ORGANIZACIÓN SI EXISTE ---
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
        // ---------------------------------------------

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

  // DENTRO DE class MeetingDetailScreen extends StatelessWidget

  // FUNCIÓN 1: BORRAR PUNTO DE AGENDA
  Future<void> _deleteAgendaItem(BuildContext context, AgendaItemModel itemToDelete) async {
    // 1. Confirmación
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
      // 2. Crear nueva lista sin el ítem
      final updatedList = List<AgendaItemModel>.from(meeting.agendaItems!);
      updatedList.removeWhere((item) => item.id == itemToDelete.id);

      // 3. Guardar en Firestore usando updateMeeting
      // Nota: Reutilizamos el método existente, enviando solo lo que cambia implícitamente
      await MeetingService().updateMeeting(
        id: meeting.id,
        type: meeting.type,
        date: meeting.date,
        time: meeting.time,
        presidedBy: meeting.presidedBy,
        directedBy: meeting.directedBy,
        organization: meeting.organization,
        sacramentAgenda: meeting.sacramentAgenda,

        // AQUÍ ESTÁ LA CLAVE: Enviamos la lista actualizada
        agendaItems: updatedList,

        commitments: meeting.commitments,
      );
    }
  }

  // FUNCIÓN 2: EDITAR PUNTO DE AGENDA

  Future<void> _editAgendaItem(BuildContext context, AgendaItemModel itemToEdit) async {
    final topicCtrl = TextEditingController(text: itemToEdit.topic);
    final assignedCtrl = TextEditingController(text: itemToEdit.assignedTo);

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Editar Punto'),
        // 1. LIMITAMOS EL ANCHO Y PERMITIMOS SCROLL
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: SizedBox(
            width: double.maxFinite, // Obliga a estirarse hasta el límite del padre (500px)
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 10),
                    TextField(
                      controller: topicCtrl,
                      // 2. CONFIGURACIÓN MULTILÍNEA
                      maxLines: null,
                      minLines: 1,
                      keyboardType: TextInputType.multiline,
                      decoration: const InputDecoration(
                        labelText: 'Asunto',
                        border: OutlineInputBorder(), // Añadimos borde para que se vea mejor
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: assignedCtrl,
                      // 2. CONFIGURACIÓN MULTILÍNEA
                      maxLines: null,
                      minLines: 1,
                      keyboardType: TextInputType.multiline,
                      decoration: const InputDecoration(
                        labelText: 'Responsable',
                        border: OutlineInputBorder(),
                      ),
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
              // ... (Lógica de guardado que ya tienes) ...
              // 1. Crear ítem actualizado
              final updatedItem = AgendaItemModel(
                id: itemToEdit.id,
                topic: topicCtrl.text,
                assignedTo: assignedCtrl.text,
                isCompleted: itemToEdit.isCompleted,
              );

              // 2. Actualizar lista local
              final updatedList = List<AgendaItemModel>.from(meeting.agendaItems!);
              final index = updatedList.indexWhere((i) => i.id == itemToEdit.id);
              if (index != -1) {
                updatedList[index] = updatedItem;
              }

              // 3. Guardar en Firestore
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


}