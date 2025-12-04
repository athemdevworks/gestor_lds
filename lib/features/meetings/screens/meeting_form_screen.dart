import 'package:flutter/material.dart';
import 'package:gestor_lds/features/meetings/utils/meeting_types.dart';
import 'package:gestor_lds/features/meetings/services/meeting_service.dart';
import 'package:gestor_lds/features/meetings/models/meeting_model.dart';
import 'package:intl/intl.dart'; // Importación necesaria para DateFormat
import 'package:gestor_lds/features/meetings/models/agenda_item_model.dart';
import 'package:gestor_lds/features/meetings/widgets/agenda_list_editor.dart';
import 'package:gestor_lds/features/meetings/models/sacrament_agenda_model.dart';

class MeetingFormScreen extends StatefulWidget {
  // 1. VARIABLE DE INSTANCIA (Debe estar aquí)
  final MeetingModel? meetingToEdit;

  // 2. CONSTRUCTOR (Debe estar aquí)
  const MeetingFormScreen({super.key, this.meetingToEdit});

  @override
  State<MeetingFormScreen> createState() => _MeetingFormScreenState();
}

class _MeetingFormScreenState extends State<MeetingFormScreen> {
  final _formKey = GlobalKey<FormState>();

  // SERVICIOS Y ESTADO INTERNO
  final MeetingService _meetingService = MeetingService(); // <-- CORREGIDO: Está en State
  MeetingType _selectedType = MeetingType.sacramental;
  List<AgendaItemModel> _currentAgendaItems = [
  ]; // <-- CORREGIDO: Está en State

  // CONTROLADORES
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _directedByController = TextEditingController();
  final TextEditingController _presidedByController = TextEditingController();
  final TextEditingController _agendaTopicController = TextEditingController(); // Ya no se usa directamente para la agenda, pero se mantiene por si acaso.

  // Nuevo metodo para guardar el estado del formulario sacramental
  final _sacramentAgendaFormKey = GlobalKey<FormState>();

  // Controladores para la Agenda Sacramental
  final TextEditingController _announcementsController = TextEditingController();
  final TextEditingController _openingHymnController = TextEditingController();
  final TextEditingController _openingPrayerController = TextEditingController();
  final TextEditingController _choristerController = TextEditingController();
  final TextEditingController _pianistController = TextEditingController();
  final TextEditingController _sacramentHymnController = TextEditingController();
  final TextEditingController _firstSpeakerNameController = TextEditingController();
  final TextEditingController _firstSpeakerTopicController = TextEditingController();
  final TextEditingController _intermediateHymnController = TextEditingController();
  final TextEditingController _secondSpeakerNameController = TextEditingController();
  final TextEditingController _secondSpeakerTopicController = TextEditingController();
  final TextEditingController _closingHymnController = TextEditingController();
  final TextEditingController _closingPrayerController = TextEditingController();

  // Estado de la Regla del Primer Domingo
  bool _isFastAndTestimony = false;

  // --- NUEVAS VARIABLES PARA PRESIDENCIA ---
  final List<String> _organizations = [
    'Cuórum de Élderes',
    'Sociedad de Socorro',
    'Mujeres Jóvenes',
    'Primaria',
    'Escuela Dominical',
    'Hombres Jóvenes (Aarónico)',
  ];
  String? _selectedOrganization;
  //

  @override
  void initState() {
    super.initState();
    final meeting = widget.meetingToEdit; // Accedemos al widget padre

    if (meeting != null) {
      // LÓGICA DE CARGA DE DATOS PARA EDICIÓN
      _selectedType = meeting.type;
      _timeController.text = meeting.time;
      _presidedByController.text = meeting.presidedBy;
      _directedByController.text = meeting.directedBy;
      _selectedOrganization = meeting.organization;

      // Formatear la fecha para el controlador de texto (YYYY-MM-DD)
      _dateController.text = meeting.date.toLocal().toString().split(' ')[0];

      _timeController.text = meeting.time;

      // Cargar agenda dinámica (¡importante!)
      _currentAgendaItems = meeting.agendaItems ?? [];
    }
  }

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
    // 1. Obtener la hora del TimePicker
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),

      // Configuración para FORZAR el formato de 12 horas
      builder: (BuildContext context, Widget? child) {
        // ⚠️ El TimePicker usa el MediaQuery más cercano para decidir el formato.
        // Creamos un nuevo contexto que fuerza el formato de 12 horas
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
          child: child!,
        );
      },
    );

    // 2. Formatear y Guardar la hora (esto ya estaba correcto)
    if (pickedTime != null) {
      // Creamos un objeto DateTime temporal para el formateo con intl
      final now = DateTime.now();
      final dt = DateTime(
          now.year, now.month, now.day, pickedTime.hour, pickedTime.minute);

      // Usamos DateFormat.jm() para el formato 12 horas con AM/PM (ej: 3:43 PM)
      final formattedTime = DateFormat.jm().format(dt);

      _timeController.text = formattedTime;
    }
  }

  void _saveMeeting() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final DateTime selectedDate = DateTime.parse(_dateController.text);
      final isEditing = widget.meetingToEdit != null; // Acceso al widget
      final meetingId = isEditing ? widget.meetingToEdit!.id : null;
      final bool isSacramental = _selectedType == MeetingType.sacramental;
      SacramentAgendaModel? sacramentAgenda;

      try {

        if (isSacramental) {
          // 1. Crear el objeto de Agenda Sacramental
          sacramentAgenda = SacramentAgendaModel(
            openingHymn: _openingHymnController.text,
            openingPrayer: _openingPrayerController.text,
            announcements: _announcementsController.text,
            chorister: _choristerController.text,
            pianist: _pianistController.text,
            sacramentHymn: _sacramentHymnController.text,
            closingHymn: _closingHymnController.text,
            closingPrayer: _closingPrayerController.text,
            isFastAndTestimony: _isFastAndTestimony,

            // Asignar discursantes SOLO si NO es domingo de ayuno
            firstSpeakerName: _isFastAndTestimony ? null : _firstSpeakerNameController.text,
            firstSpeakerTopic: _isFastAndTestimony ? null : _firstSpeakerTopicController.text,
            intermediateHymn: _isFastAndTestimony ? null : _intermediateHymnController.text,
            secondSpeakerName: _isFastAndTestimony ? null : _secondSpeakerNameController.text,
            secondSpeakerTopic: _isFastAndTestimony ? null : _secondSpeakerTopicController.text,
          );
        }

        if (isEditing) {
          // --- LÓGICA DE MODIFICAR (UPDATE) ---
          await _meetingService.updateMeeting(
            id: meetingId!,
            type: _selectedType,
            organization: _selectedType == MeetingType.presidency ? _selectedOrganization : null,
            date: selectedDate,
            time: _timeController.text,
            presidedBy: _presidedByController.text,
            directedBy: _directedByController.text,
            sacramentAgenda: sacramentAgenda, // <-- AÑADIDO
            agendaItems: isSacramental ? null : _currentAgendaItems,
            commitments: _selectedType != MeetingType.sacramental ? [] : null,
          );
        } else {
          // --- LÓGICA DE CREAR (CREATE) ---
          await _meetingService.saveMeeting(
            type: _selectedType,
            organization: _selectedType == MeetingType.presidency ? _selectedOrganization : null,
            date: selectedDate,
            time: _timeController.text,
            presidedBy: _presidedByController.text,
            directedBy: _directedByController.text,
            sacramentAgenda: sacramentAgenda, // <-- AÑADIDO
            agendaItems: isSacramental ? null : _currentAgendaItems,
            commitments: _selectedType != MeetingType.sacramental ? [] : null,
          );
        }

        // Muestra mensaje de éxito y regresa a la pantalla de listado
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(
                'Reunión de ${_selectedType.displayName} guardada con éxito.')),
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

  // Reemplaza todo el método build(BuildContext context) con esto:

  @override
  Widget build(BuildContext context) {
    final bool isLeadershipMeeting = _selectedType != MeetingType.sacramental;
    final bool isSacramentalMeeting = _selectedType == MeetingType.sacramental;

    // DETERMINA EL TEXTO DEL BOTÓN Y TÍTULO
    final isEditing = widget.meetingToEdit != null;
    final buttonText = isEditing ? 'Guardar Cambios' : 'Crear Reunión';
    final screenTitle = isEditing ? 'Editar Reunión' : 'Crear Nueva Reunión';

    return Scaffold(
        appBar: AppBar(
          title: Text(screenTitle),
        ),
      // 1. CENTRAMOS EL CONTENIDO
        body: Center(
          child: ConstrainedBox(
            // 2. LIMITAMOS EL ANCHO (Para que en PC se vea como una hoja)
            constraints: const BoxConstraints(maxWidth: 700),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0), // Un poco más de espacio
            child: Form(
                key: _formKey,
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                    // 1. SELECTOR DE TIPO DE REUNIÓN
                    const Text('Tipo de Reunión', style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold)),
                     const SizedBox(height: 8),
                    DropdownButtonFormField<MeetingType>(
                    decoration: const InputDecoration(
                      border: OutlineInputBorder()),
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

                // NUEVO SELECTOR CONDICIONAL
                if (_selectedType == MeetingType.presidency)
                  Padding(
                    padding: const EdgeInsets.only(top: 12.0, bottom: 20.0),
                    child: DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Organización',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.people_outline), // Icono opcional
                      ),
                      value: _selectedOrganization,
                      items: _organizations.map((org) {
                        return DropdownMenuItem(value: org, child: Text(org));
                      }).toList(),
                      onChanged: (val) => setState(() => _selectedOrganization = val),
                      validator: (val) => val == null ? 'Seleccione una organización' : null,
                    ),
                  ),

                // 2. CAMPOS COMUNES (Detalles Básicos)
                const Text('Detalles Básicos', style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold)),
                const Divider(height: 20),

                // Fecha, Hora, Preside, Dirige
                TextFormField(
                  controller: _dateController,
                  decoration: const InputDecoration(labelText: 'Fecha', border: OutlineInputBorder(), suffixIcon: Icon(Icons.calendar_today)),
                  readOnly: true,
                  onTap: _selectDate,
                  validator: (value) => value == null || value.isEmpty ? 'Seleccione la fecha' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _timeController,
                  decoration: const InputDecoration(labelText: 'Hora', border: OutlineInputBorder(), suffixIcon: Icon(Icons.access_time)),
                  readOnly: true,
                  onTap: _selectTime,
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

                // 3. SECCIÓN DINÁMICA: Agenda Fija o Dinámica

                if (isSacramentalMeeting)
                // A. AGENDA SACRAMENTAL (FIJA)
                _buildSacramentAgendaForm()

                else if (isLeadershipMeeting)
                // B. AGENDA DE LIDERAZGO (DINÁMICA)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Agenda y Puntos de Revisión',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.secondary)),
                    const Divider(height: 20, color: Colors.black45),

                    AgendaListEditor(
                      initialItems: _currentAgendaItems,
                      onAgendaChanged: (newAgenda) {
                        _currentAgendaItems = newAgenda;
                      },
                    ),
                    const SizedBox(height: 12),
                    // TODO: Aquí se integrará el sub-módulo de Compromisos
                  ],
                ),

                const SizedBox(height: 30), // <-- Este SizedBox debe estar aquí

                // 4. BOTÓN DE GUARDAR (Debe estar en la columna principal)
                ElevatedButton(
                  onPressed: _saveMeeting,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                child: Text(
                buttonText,
                style: const TextStyle(fontSize: 18)
                 ),
              ),
            ],
         ),),),
       ),
      ),

    );
  }

  // Incluye el método _buildSacramentAgendaForm() aquí mismo, después de build
  Widget _buildSacramentAgendaForm() {
    final bool hideSpeakers = _isFastAndTestimony;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Agenda Sacramental (Fija)',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0089D3)),
        ),
        const Divider(height: 20),

        SwitchListTile(
          title: const Text('Primer Domingo (Ayuno y Testimonio)'),
          subtitle: const Text('Oculta discursantes y habilita el tiempo de testimonios.'),
          value: _isFastAndTestimony,
          onChanged: (bool value) {
            setState(() {
              _isFastAndTestimony = value;
            });
          },
        ),
        const SizedBox(height: 15),

        // 1. APERTURA (Con espacios añadidos)
        TextFormField(controller: _openingHymnController, decoration: const InputDecoration(labelText: 'Himno de Apertura')),
        const SizedBox(height: 12), // <--- ESPACIO AÑADIDO

        TextFormField(controller: _openingPrayerController, decoration: const InputDecoration(labelText: 'Oración de Apertura')),
        const SizedBox(height: 12), // <--- ESPACIO AÑADIDO

        TextFormField(
          controller: _announcementsController,
          maxLines: 2,
          decoration: const InputDecoration(labelText: 'Anuncios del Barrio', alignLabelWithHint: true),
        ),
        const SizedBox(height: 12), // <--- ESPACIO AÑADIDO

        TextFormField(controller: _choristerController, decoration: const InputDecoration(labelText: 'Director de Himnos')),
        const SizedBox(height: 12), // <--- ESPACIO AÑADIDO

        TextFormField(controller: _pianistController, decoration: const InputDecoration(labelText: 'Pianista')),
        const SizedBox(height: 15), // Separación de sección

        // 2. LA SANTA CENA
        TextFormField(controller: _sacramentHymnController, decoration: const InputDecoration(labelText: 'Himno Sacramental')),
        const SizedBox(height: 25),

        // 3. SECCIÓN DE DISCURSOS
        if (hideSpeakers)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.orange.shade800),
                const SizedBox(width: 10),
                const Expanded(child: Text('Tiempo de Testimonios (Sin discursantes)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange))),
              ],
            ),
          )
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Discursos', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),

              // PRIMER DISCURSO
              TextFormField(controller: _firstSpeakerNameController, decoration: const InputDecoration(labelText: '1er Discursante (Nombre)')),
              const SizedBox(height: 12), // <--- ESPACIO AÑADIDO
              TextFormField(controller: _firstSpeakerTopicController, decoration: const InputDecoration(labelText: '1er Discursante (Tema)')),

              const Divider(height: 30),

              // HIMNO ESPECIAL
              TextFormField(controller: _intermediateHymnController, decoration: const InputDecoration(labelText: 'Himno Especial/Intermedio')),

              const Divider(height: 30),

              // SEGUNDO DISCURSO
              TextFormField(controller: _secondSpeakerNameController, decoration: const InputDecoration(labelText: '2do Discursante (Nombre)')),
              const SizedBox(height: 12), // <--- ESPACIO AÑADIDO
              TextFormField(controller: _secondSpeakerTopicController, decoration: const InputDecoration(labelText: '2do Discursante (Tema)')),
            ],
          ),

        const SizedBox(height: 25),

        // 4. CIERRE
        TextFormField(controller: _closingHymnController, decoration: const InputDecoration(labelText: 'Himno de Cierre')),
        const SizedBox(height: 12), // <--- ESPACIO AÑADIDO
        TextFormField(controller: _closingPrayerController, decoration: const InputDecoration(labelText: 'Oración de Cierre')),

        const SizedBox(height: 20),
      ],
    );
  }
// ... (asegúrate de que las llaves de _MeetingFormScreenState cierren aquí)

}