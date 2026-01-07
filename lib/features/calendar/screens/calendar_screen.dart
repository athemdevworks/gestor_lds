import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// MODELOS
import 'package:gestor_lds/features/meetings/models/meeting_model.dart';
import 'package:gestor_lds/features/commitments/models/commitment_model.dart';
import 'package:gestor_lds/features/activities/models/activity_model.dart';
import 'package:gestor_lds/features/auth/models/user_model.dart';
import 'package:gestor_lds/features/meetings/utils/meeting_types.dart';

// PANTALLAS DE MÓDULO
import 'package:gestor_lds/features/meetings/screens/meeting_detail_screen.dart';
import 'package:gestor_lds/features/activities/screens/activities_screen.dart';
import 'package:gestor_lds/features/commitments/screens/my_commitments_screen.dart';

import '../../activities/screens/activity_form_screen.dart';
import '../widgets/activity_detail_dialog.dart';

class CalendarScreen extends StatefulWidget {
  final UserModel currentUser;

  const CalendarScreen({super.key, required this.currentUser});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  Map<DateTime, List<dynamic>> _events = {};
  bool _isLoading = true;

  // COLORES CORPORATIVOS
  final Color colorMeeting = const Color(0xFF164772);
  final Color colorActivity = const Color(0xFF43A047);
  final Color colorCommitment = const Color(0xFFF57C00);

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    final Map<DateTime, List<dynamic>> newEvents = {};

    try {
      // 1. REUNIONES (CON FILTRO DE PRIVACIDAD)
      final meetingsSnap = await FirebaseFirestore.instance.collection('meetings').get();
      for (var doc in meetingsSnap.docs) {
        final meeting = MeetingModel.fromMap(doc.data(), doc.id);

        bool canView = false;
        // A. Obispado ve TODO
        if (widget.currentUser.role == UserRole.obispado) {
          canView = true;
        }
        // B. Líderes
        else if (widget.currentUser.role == UserRole.lider) {
          if (meeting.type == MeetingType.sacramental) {
            canView = false;
          } else if (meeting.type == MeetingType.wardCouncil || meeting.organization == widget.currentUser.organization) {
            canView = true;
          }
        }
        // C. Miembros (Si ocultamos sacramental, no ven nada aquí por ahora)

        if (canView) {
          final dateKey = _normalizeDate(meeting.date);
          if (newEvents[dateKey] == null) newEvents[dateKey] = [];
          newEvents[dateKey]!.add(meeting);
        }
      }

      // 2. COMPROMISOS (FILTRO PERSONAL)
      final commitmentsSnap = await FirebaseFirestore.instance.collection('commitments').get();
      for (var doc in commitmentsSnap.docs) {
        final commitment = CommitmentModel.fromMap(doc.data(), doc.id);

        // Solo mostrar mis compromisos o si soy obispado (opcional)
        if (commitment.assignedTo == widget.currentUser.uid) {
          final dateKey = _normalizeDate(commitment.dueDate);
          if (newEvents[dateKey] == null) newEvents[dateKey] = [];
          newEvents[dateKey]!.add(commitment);
        }
      }

      // 3. ACTIVIDADES (PÚBLICAS PARA TODOS)
      final activitiesSnap = await FirebaseFirestore.instance.collection('activities').get();
      for (var doc in activitiesSnap.docs) {
        final activity = ActivityModel.fromMap(doc.data(), doc.id);
        final dateKey = _normalizeDate(activity.date);
        if (newEvents[dateKey] == null) newEvents[dateKey] = [];
        newEvents[dateKey]!.add(activity);
      }

    } catch (e) {
      print("Error cargando calendario: $e");
    }

    if (mounted) {
      setState(() {
        _events = newEvents;
        _isLoading = false;
      });
    }
  }

  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  List<dynamic> _getEventsForDay(DateTime day) {
    return _events[_normalizeDate(day)] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendario del Barrio'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
            onPressed: _loadEvents,
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          // CALENDARIO
          Card(
            margin: const EdgeInsets.all(12.0),
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: TableCalendar(
                locale: 'es_ES',
                firstDay: DateTime.utc(2023, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: _focusedDay,
                daysOfWeekStyle: const DaysOfWeekStyle(decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey, width: 0.5)))),
                calendarStyle: const CalendarStyle(markersAutoAligned: false, outsideDaysVisible: true),
                headerStyle: const HeaderStyle(formatButtonVisible: false, titleCentered: true),
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                onDaySelected: (selectedDay, focusedDay) => setState(() { _selectedDay = selectedDay; _focusedDay = focusedDay; }),
                eventLoader: _getEventsForDay,

                calendarBuilders: CalendarBuilders(
                  defaultBuilder: (context, day, focusedDay) {
                    if (day.weekday == DateTime.saturday || day.weekday == DateTime.sunday) return _buildGridCell(day, textColor: Colors.grey.shade700);
                    return _buildGridCell(day, textColor: Colors.black);
                  },
                  outsideBuilder: (context, day, focusedDay) => _buildGridCell(day, textColor: Colors.grey.shade400),
                  selectedBuilder: (context, day, focusedDay) => _buildGridCell(day, backColor: Colors.grey.withOpacity(0.5), textColor: Colors.white),
                  todayBuilder: (context, day, focusedDay) => _buildGridCell(day, backColor: Colors.blueAccent.withOpacity(0.3), textColor: Colors.blue.shade900),
                  markerBuilder: (context, date, events) {
                    if (events.isEmpty) return const SizedBox();
                    final meetingCount = events.whereType<MeetingModel>().length;
                    final activityCount = events.whereType<ActivityModel>().length;
                    final commitmentCount = events.whereType<CommitmentModel>().length;
                    return Positioned(
                      right: 2, bottom: 2,
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        if (meetingCount > 0) _buildCountMarker(meetingCount, colorMeeting),
                        if (activityCount > 0) _buildCountMarker(activityCount, colorActivity),
                        if (commitmentCount > 0) _buildCountMarker(commitmentCount, colorCommitment),
                      ]),
                    );
                  },
                ),
              ),
            ),
          ),

          // LEYENDA
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
              _buildLegendItem(colorMeeting, "Reuniones"),
              _buildLegendItem(colorActivity, "Actividades"),
              _buildLegendItem(colorCommitment, "Compromisos"),
            ]),
          ),
          const Divider(),

          // LISTA DE DETALLES
          Expanded(
            child: _selectedDay == null
                ? const Center(child: Text('Selecciona un día'))
                : Builder(
              builder: (context) {
                final events = _getEventsForDay(_selectedDay!);
                if (events.isEmpty) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.event_available, size: 50, color: Colors.grey[300]), const SizedBox(height: 10), Text('Día libre', style: const TextStyle(color: Colors.grey))]));

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: events.length,
                  itemBuilder: (context, index) {
                    final event = events[index];

                    // A. REUNIÓN -> Va a Detalle
                    if (event is MeetingModel) {
                      return Card(
                        elevation: 2, margin: const EdgeInsets.only(bottom: 10), shape: Border(left: BorderSide(color: colorMeeting, width: 5)),
                        child: ListTile(
                          leading: Icon(Icons.groups, color: colorMeeting),
                          title: Text(event.type.displayName, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('${event.time} - Preside: ${event.presidedBy}'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () async {
                            await Navigator.push(context, MaterialPageRoute(builder: (context) => MeetingDetailScreen(meeting: event)));
                            _loadEvents(); // Recargar al volver
                          },
                        ),
                      );
                    }

// B. ACTIVIDAD
                    else if (event is ActivityModel) {
                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.only(bottom: 10),
                        shape: Border(left: BorderSide(color: colorActivity, width: 5)),
                        child: ListTile(
                          leading: Icon(Icons.local_activity, color: colorActivity),
                          title: Text(event.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('${event.time} - ${event.location}'),

                          // CAMBIO 1: Icono diferente según rol
                          trailing: widget.currentUser.role == UserRole.miembro
                              ? const Icon(Icons.visibility, color: Colors.grey) // Ojo para ver
                              : const Icon(Icons.edit, color: Colors.blue),      // Lápiz para editar

                          onTap: () async {
                            // CAMBIO 2: Lógica de Navegación por Rol

                            if (widget.currentUser.role == UserRole.miembro) {
                              // CASO A: MIEMBRO -> Solo ve detalles
                              showDialog(
                                  context: context,
                                  builder: (ctx) => ActivityDetailDialog(activity: event)
                              );
                            } else {
                              // CASO B: LÍDER/OBISPADO -> Puede Editar
                              // Navegamos directamente al formulario en modo edición
                              await Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => ActivityFormScreen(activityToEdit: event))
                              );
                              _loadEvents(); // Recargar al volver por si editó algo
                            }
                          },
                        ),
                      );
                    }

                    // C. COMPROMISO -> Va al Módulo de Mis Compromisos
                    else if (event is CommitmentModel) {
                      return Card(
                        elevation: 1, margin: const EdgeInsets.only(bottom: 10), shape: Border(left: BorderSide(color: colorCommitment, width: 5)),
                        child: ListTile(
                          leading: Icon(event.isCompleted ? Icons.check_circle : Icons.warning_amber_rounded, color: event.isCompleted ? Colors.green : colorCommitment),
                          title: Text(event.description),
                          subtitle: Text('Vence: ${DateFormat('dd/MM').format(event.dueDate)}'),
                          trailing: const Icon(Icons.open_in_new),
                          onTap: () async {
                            await Navigator.push(context, MaterialPageRoute(builder: (context) => MyCommitmentsScreen(currentUser: widget.currentUser)));
                            _loadEvents(); // Recargar al volver
                          },
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGETS AUXILIARES (Visuales) ---
  Widget _buildGridCell(DateTime day, {Color? backColor, Color? textColor}) {
    return Container(
      margin: const EdgeInsets.all(0), decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300, width: 0.5)),
      alignment: Alignment.center,
      child: backColor != null
          ? Container(width: 32, height: 32, decoration: BoxDecoration(color: backColor, shape: BoxShape.circle), alignment: Alignment.center, child: Text('${day.day}', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)))
          : Text('${day.day}', style: TextStyle(color: textColor)),
    );
  }

  Widget _buildCountMarker(int count, Color color) {
    return Container(margin: const EdgeInsets.only(left: 1.0), width: 14, height: 14, decoration: BoxDecoration(color: color, shape: BoxShape.circle), child: Center(child: Text(count > 9 ? '9+' : count.toString(), style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold))));
  }

  Widget _buildLegendItem(Color color, String text) {
    return Row(children: [Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)), const SizedBox(width: 5), Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))]);
  }
}