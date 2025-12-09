import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gestor_lds/features/meetings/models/meeting_model.dart';
import 'package:gestor_lds/features/commitments/models/commitment_model.dart';
import 'package:gestor_lds/features/activities/models/activity_model.dart';

import '../../meetings/utils/meeting_types.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  Map<DateTime, List<dynamic>> _events = {};
  bool _isLoading = true;

  // COLORES CORPORATIVOS (Definidos con HEX para evitar error de nulidad)
  final Color colorMeeting = const Color(0xFF164772);    // Azul LDS
  final Color colorActivity = const Color(0xFF43A047);   // Verde
  final Color colorCommitment = const Color(0xFFF57C00); // Naranja

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    setState(() => _isLoading = true);

    final Map<DateTime, List<dynamic>> newEvents = {};

    try {
      // 1. REUNIONES
      final meetingsSnap = await FirebaseFirestore.instance.collection('meetings').get();
      for (var doc in meetingsSnap.docs) {
        final meeting = MeetingModel.fromMap(doc.data(), doc.id);
        final dateKey = _normalizeDate(meeting.date);
        if (newEvents[dateKey] == null) newEvents[dateKey] = [];
        newEvents[dateKey]!.add(meeting);
      }

      // 2. COMPROMISOS
      final commitmentsSnap = await FirebaseFirestore.instance.collection('commitments').get();
      for (var doc in commitmentsSnap.docs) {
        final commitment = CommitmentModel.fromMap(doc.data(), doc.id);
        final dateKey = _normalizeDate(commitment.dueDate);
        if (newEvents[dateKey] == null) newEvents[dateKey] = [];
        newEvents[dateKey]!.add(commitment);
      }

      // 3. ACTIVIDADES
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
      appBar: AppBar(title: const Text('Calendario del Barrio')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Card(
            margin: const EdgeInsets.all(12.0),
            elevation: 3,
            // Quitamos bordes redondeados exagerados para que la grilla se vea cuadrada y profesional
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: TableCalendar(
                locale: 'es_ES',
                firstDay: DateTime.utc(2023, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: _focusedDay,

                // ESTILO DE CABECERA (Días de la semana)
                daysOfWeekStyle: const DaysOfWeekStyle(
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: Colors.grey, width: 0.5)),
                  ),
                ),

                // CONFIGURACIÓN DE ESTILO
                calendarStyle: const CalendarStyle(
                  markersAutoAligned: false,
                  // Ya no usamos decoration aquí, lo haremos manual en los builders
                  outsideDaysVisible: true,
                ),
                headerStyle: const HeaderStyle(formatButtonVisible: false, titleCentered: true),

                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                },

                eventLoader: _getEventsForDay,

                // --- AQUÍ ESTÁ LA MAGIA VISUAL ---
                calendarBuilders: CalendarBuilders(

                  // 1. Constructor para días normales (Y fines de semana)
                  defaultBuilder: (context, day, focusedDay) {
                    // Verificamos si es fin de semana (Sábado=6, Domingo=7)
                    if (day.weekday == DateTime.saturday || day.weekday == DateTime.sunday) {
                      // Estilo para Fin de Semana (Gris oscuro o Rojo suave si prefieres)
                      return _buildGridCell(day, textColor: Colors.grey.shade700);
                    }
                    // Estilo para Lunes a Viernes (Negro)
                    return _buildGridCell(day, textColor: Colors.black);
                  },

                  // 2. (El weekendBuilder YA NO EXISTE, lo borramos)

                  // 3. Constructor para días fuera del mes (gris suave)
                  outsideBuilder: (context, day, focusedDay) {
                    return _buildGridCell(day, textColor: Colors.grey.shade300);
                  },

                  // 4. Constructor para DÍA SELECCIONADO (Círculo Gris)
                  selectedBuilder: (context, day, focusedDay) {
                    return _buildGridCell(day,
                        backColor: Colors.grey.withOpacity(0.5),
                        textColor: Colors.white
                    );
                  },

                  // 5. Constructor para HOY (Círculo Azul)
                  todayBuilder: (context, day, focusedDay) {
                    return _buildGridCell(day,
                        backColor: Colors.blueAccent.withOpacity(0.3),
                        textColor: Colors.blue.shade900
                    );
                  },

                  // 6. Marcadores (Los puntitos/contadores)
                  markerBuilder: (context, date, events) {
                    if (events.isEmpty) return const SizedBox();
                    final meetingCount = events.whereType<MeetingModel>().length;
                    final activityCount = events.whereType<ActivityModel>().length;
                    final commitmentCount = events.whereType<CommitmentModel>().length;

                    return Positioned(
                      right: 2,
                      bottom: 2,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (meetingCount > 0) _buildCountMarker(meetingCount, colorMeeting),
                          if (activityCount > 0) _buildCountMarker(activityCount, colorActivity),
                          if (commitmentCount > 0) _buildCountMarker(commitmentCount, colorCommitment),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),

          // LEYENDA
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildLegendItem(colorMeeting, "Reuniones"),
                _buildLegendItem(colorActivity, "Actividades"),
                _buildLegendItem(colorCommitment, "Compromisos"),
              ],
            ),
          ),
          const Divider(),

          // LISTA DETALLADA
          Expanded(
            child: _selectedDay == null
                ? const Center(child: Text('Selecciona un día'))
                : Builder(
              builder: (context) {
                final events = _getEventsForDay(_selectedDay!);
                if (events.isEmpty) {
                  return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.event_available, size: 50, color: Colors.grey[300]),
                          const SizedBox(height: 10),
                          Text('Día libre para el ${DateFormat('dd/MM').format(_selectedDay!)}', style: const TextStyle(color: Colors.grey)),
                        ],
                      )
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: events.length,
                  itemBuilder: (context, index) {
                    final event = events[index];

                    if (event is MeetingModel) {
                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.only(bottom: 10),
                        shape: Border(left: BorderSide(color: colorMeeting, width: 5)),
                        child: ListTile(
                          leading: Icon(Icons.groups, color: colorMeeting),
                          title: Text(event.type.displayName, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('${event.time} - Preside: ${event.presidedBy}'),
                        ),
                      );
                    } else if (event is ActivityModel) {
                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.only(bottom: 10),
                        shape: Border(left: BorderSide(color: colorActivity, width: 5)),
                        child: ListTile(
                          leading: Icon(Icons.local_activity, color: colorActivity),
                          title: Text(event.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('${event.time} - ${event.location}\nOrg: ${event.organization}'),
                          isThreeLine: true,
                        ),
                      );
                    } else if (event is CommitmentModel) {
                      return Card(
                        elevation: 1,
                        margin: const EdgeInsets.only(bottom: 10),
                        shape: Border(left: BorderSide(color: colorCommitment, width: 5)),
                        child: ListTile(
                          leading: Icon(
                              event.isCompleted ? Icons.check_circle : Icons.warning_amber_rounded,
                              color: event.isCompleted ? Colors.green : colorCommitment
                          ),
                          title: Text(event.description),
                          subtitle: Text('Responsable: ${event.responsibleName ?? "Sin asignar"}'),
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

  // --- CÉLULA DE GRILLA (Esta función dibuja el cuadrado gris y el contenido) ---
  Widget _buildGridCell(DateTime day, {Color? backColor, Color? textColor}) {
    return Container(
      margin: const EdgeInsets.all(0), // Sin márgenes para que los bordes se toquen
      decoration: BoxDecoration(
        // Borde gris claro alrededor de toda la celda
        border: Border.all(color: Colors.grey.shade300, width: 0.5),
      ),
      alignment: Alignment.center, // Centramos el contenido
      child: backColor != null
          ? Container(
        // Si tiene color de fondo (Selected/Today), dibujamos el círculo
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: backColor,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Text('${day.day}', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
      )
          : Text('${day.day}', style: TextStyle(color: textColor)),
    );
  }

  Widget _buildCountMarker(int count, Color color) {
    return Container(
      margin: const EdgeInsets.only(left: 1.0),
      width: 14,
      height: 14,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Center(
        child: Text(
          count > 9 ? '9+' : count.toString(),
          style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String text) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 5),
        Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }
}