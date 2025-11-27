import 'package:flutter/material.dart';
import 'package:gestor_lds/features/meetings/utils/meeting_types.dart';
import 'package:gestor_lds/features/meetings/services/meeting_service.dart';
import 'package:intl/intl.dart'; // Importación necesaria para DateFormat

class MeetingFormScreen extends StatefulWidget {
  const MeetingFormScreen({super.key});

  @override
  State<MeetingFormScreen> createState() => _MeetingFormScreenState();
}

class _MeetingFormScreenState extends State<MeetingFormScreen> {
  final _formKey = GlobalKey<FormState>();

  // Estado para el tipo de reunión seleccionada
  MeetingType _selectedType = MeetingType.sacramental;

  // Controladores de texto para campos comunes
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _directedByController = TextEditingController();
  final TextEditingController _presidedByController = TextEditingController();

  // Controladores para la agenda de liderazgo (dinámica)
  final TextEditingController _agendaTopicController = TextEditingController();

  final MeetingService _meetingService = MeetingService();

  @override
  void dispose() {
    _dateController.dispose();
    _timeController.dispose();
    _directedByController.dispose();
    _presidedByController.dispose();
    _agendaTopicController.dispose();
    super.dispose();
  }

  // FUNCIÓN RESTAURADA: Seleccionar FECHA
  Future<void> _selectDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2023),
      lastDate: DateTime(2030),
    );
    if (pickedDate != null) {
      // Formatea la fecha seleccionada (Ej: 2025-11-27)
      _dateController.text = pickedDate.toLocal().toString().split(' ')[0];
    }
  }

  // FUNCIÓN RESTAURADA: Seleccionar HORA (Formato 12h AM/PM)
  Future<void> _selectTime() async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (BuildContext context, Widget? child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
          child: child!,
        );
      },
    );

    if (pickedTime != null) {
      // Usamos DateFormat.jm() para el formato de 12h con AM/PM
      final now = DateTime.now();
      final dt = DateTime(now.year, now.month, now.day, pickedTime.hour, pickedTime.minute);
      final formattedTime = DateFormat.jm().format(dt);

      _timeController.text = formattedTime;
    }
  }

  void _saveMeeting() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      // Para el guardado, necesitamos convertir la fecha de String a DateTime
      final DateTime selectedDate = DateTime.parse(_dateController.text);

      try {
        await _meetingService.saveMeeting(
          type: _selectedType,
          date: selectedDate,
          time: _timeController.text,
          presidedBy: _presidedByController.text,
          directedBy: _directedByController.text,

          // Solo si es reunión de liderazgo, guardamos el propósito
          agendaTopics: _selectedType != MeetingType.sacramental ? _agendaTopicController.text : null,
          commitments: _selectedType != MeetingType.sacramental ? [] : null, // Por ahora lista vacía
        );

        // Muestra mensaje de éxito y regresa a la pantalla de listado
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Reunión de ${_selectedType.displayName} guardada con éxito.')),
          );
          Navigator.of(context).pop();
        }

      } catch (e) {
        // Muestra cualquier error de guardado
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Es true si se selecciona Obispado, Consejo o Otra Reunión
    final bool isLeadershipMeeting = _selectedType != MeetingType.sacramental;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Nueva Reunión'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. SELECTOR DE TIPO DE REUNIÓN (Dropdown)
              const Text('Tipo de Reunión', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<MeetingType>(
                decoration: const InputDecoration(border: OutlineInputBorder()),
                value: _selectedType,
                items: MeetingType.values.map((MeetingType type) {
                  return DropdownMenuItem<MeetingType>(
                    value: type,
                    child: Text(type.displayName),
                  );
                }).toList(),
                onChanged: (MeetingType? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedType = newValue;
                    });
                  }
                },
              ),
              const SizedBox(height: 20),

              // 2. CAMPOS COMUNES
              const Text('Detalles Básicos', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const Divider(height: 20),

              // Campo de Fecha
              TextFormField(
                controller: _dateController,
                decoration: const InputDecoration(
                  labelText: 'Fecha',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                readOnly: true,
                onTap: _selectDate, // Llama a la función de selección de FECHA
                validator: (value) => value == null || value.isEmpty ? 'Seleccione la fecha' : null,
              ),
              const SizedBox(height: 12),

              // Campo de Hora
              TextFormField(
                controller: _timeController,
                decoration: const InputDecoration(
                  labelText: 'Hora',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.access_time),
                ),
                readOnly: true,
                onTap: _selectTime, // Llama a la función de selección de HORA (12h)
                validator: (value) => value == null || value.isEmpty ? 'Seleccione la hora' : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _presidedByController,
                decoration: const InputDecoration(labelText: 'Preside (Ej: Obispo)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _directedByController,
                decoration: const InputDecoration(labelText: 'Dirige (Ej: 1er Consejero)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 30),

              // 3. SECCIÓN DINÁMICA: Agenda de Liderazgo
              if (isLeadershipMeeting)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Agenda y Puntos de Revisión',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.secondary)),
                    const Divider(height: 20, color: Colors.black45),

                    // Nota: Aquí irían los campos de Agendas y Compromisos
                    TextFormField(
                      controller: _agendaTopicController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Propósito o Temas a Tratar',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // TODO: Aquí se integrará el sub-módulo de Compromisos y Asuntos a Revisar
                  ],
                ),

              const SizedBox(height: 30),

              // Botón de Guardar
              ElevatedButton(
                onPressed: _saveMeeting,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                child: const Text('Guardar Reunión', style: TextStyle(fontSize: 18)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}