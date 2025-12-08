import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gestor_lds/features/meetings/models/meeting_model.dart';
import 'package:gestor_lds/features/commitments/models/commitment_model.dart';

import '../../meetings/utils/meeting_types.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  // Aquí guardaremos los eventos agrupados por fecha
  Map<DateTime, List<dynamic>> _events = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadEvents(); // Cargar datos al iniciar
  }

  // Carga Reuniones y Compromisos de Firestore
  Future<void> _loadEvents() async {
    setState(() => _isLoading = true);

    final Map<DateTime, List<dynamic>> newEvents = {};

    try {
      // 1. Cargar Reuniones
      final meetingsSnap = await FirebaseFirestore.instance.collection('meetings').get();
      for (var doc in meetingsSnap.docs) {
        final meeting = MeetingModel.fromMap(doc.data(), doc.id);

        // Normalizar fecha (quitar horas/minutos para que coincida con el calendario)
        final dateKey = DateTime(meeting.date.year, meeting.date.month, meeting.date.day);

        if (newEvents[dateKey] == null) newEvents[dateKey] = [];
        newEvents[dateKey]!.add(meeting);
      }

      // 2. Cargar Compromisos (Opcional: Si quieres ver vencimientos en el calendario)
      final commitmentsSnap = await FirebaseFirestore.instance.collection('commitments').get();
      for (var doc in commitmentsSnap.docs) {
        final commitment = CommitmentModel.fromMap(doc.data(), doc.id);

        final dateKey = DateTime(commitment.dueDate.year, commitment.dueDate.month, commitment.dueDate.day);

        if (newEvents[dateKey] == null) newEvents[dateKey] = [];
        newEvents[dateKey]!.add(commitment);
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

  // Helper para obtener eventos de un día específico
  List<dynamic> _getEventsForDay(DateTime day) {
    // Normalizar la fecha que pide el calendario
    final dateKey = DateTime(day.year, day.month, day.day);
    return _events[dateKey] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Calendario del Barrio')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          // 1. EL WIDGET DE CALENDARIO
          Card(
            margin: const EdgeInsets.all(8.0),
            elevation: 4,
            child: TableCalendar(
              locale: 'es_ES', // Español
              firstDay: DateTime.utc(2024, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,

              // Estilos
              calendarStyle: const CalendarStyle(
                todayDecoration: BoxDecoration(color: Colors.blueAccent, shape: BoxShape.circle),
                selectedDecoration: BoxDecoration(color: Color(0xFF164772), shape: BoxShape.circle), // Tu azul corporativo
                markerDecoration: BoxDecoration(color: Colors.red, shape: BoxShape.circle),
              ),
              headerStyle: const HeaderStyle(formatButtonVisible: false, titleCentered: true),

              // Lógica de Selección
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },

              // CARGAR PUNTITOS (EVENTOS)
              eventLoader: _getEventsForDay,
            ),
          ),

          const SizedBox(height: 10),

          // 2. LISTA DE EVENTOS DEL DÍA SELECCIONADO
          Expanded(
            child: _selectedDay == null
                ? const Center(child: Text('Selecciona un día'))
                : Builder(
              builder: (context) {
                final events = _getEventsForDay(_selectedDay!);
                if (events.isEmpty) {
                  return Center(child: Text('No hay actividades para el ${DateFormat('dd/MM').format(_selectedDay!)}', style: const TextStyle(color: Colors.grey)));
                }

                return ListView.builder(
                  itemCount: events.length,
                  itemBuilder: (context, index) {
                    final event = events[index];

                    // RENDERIZAR REUNIÓN
                    if (event is MeetingModel) {
                      return Card(
                        color: Colors.blue[50],
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: ListTile(
                          leading: const Icon(Icons.groups, color: Color(0xFF164772)),
                          title: Text(event.type.displayName, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('${event.time} - Preside: ${event.presidedBy}'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            // Aquí podríamos navegar al detalle de la reunión
                          },
                        ),
                      );
                    }
                    // RENDERIZAR COMPROMISO
                    else if (event is CommitmentModel) {
                      return Card(
                        color: Colors.orange[50],
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: ListTile(
                          leading: Icon(
                              event.isCompleted ? Icons.check_circle : Icons.warning_amber_rounded,
                              color: event.isCompleted ? Colors.green : Colors.orange
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
}