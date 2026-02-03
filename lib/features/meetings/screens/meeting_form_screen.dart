import 'package:flutter/material.dart';
import 'package:gestor_lds/features/meetings/utils/meeting_types.dart';
import 'package:gestor_lds/features/meetings/services/meeting_service.dart';
import 'package:gestor_lds/features/meetings/models/meeting_model.dart';
import 'package:intl/intl.dart';
import 'package:gestor_lds/features/meetings/models/agenda_item_model.dart';
import 'package:gestor_lds/features/meetings/widgets/agenda_list_editor.dart';
import 'package:gestor_lds/features/meetings/models/sacrament_agenda_model.dart';
import 'package:gestor_lds/features/meetings/models/ward_business_model.dart';
import 'package:gestor_lds/features/communications/services/citation_service.dart';
import 'package:gestor_lds/features/members/widgets/member_autocomplete_field.dart';

import '../../../core/widgets/hymn_autocomplete.dart';

class MeetingFormScreen extends StatefulWidget {
  final MeetingModel? meetingToEdit;

  const MeetingFormScreen({super.key, this.meetingToEdit});

  @override
  State<MeetingFormScreen> createState() => _MeetingFormScreenState();
}

class _MeetingFormScreenState extends State<MeetingFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final MeetingService _meetingService = MeetingService();
  final CitationService _citationService = CitationService();

  MeetingType _selectedType = MeetingType.sacramental;
  List<AgendaItemModel> _currentAgendaItems = [];
  List<WardBusinessModel> _wardBusinessList = [];

  // CONTROLADORES GENERALES
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _directedByController = TextEditingController();
  final TextEditingController _presidedByController = TextEditingController();

  // CONTROLADORES AGENDA SACRAMENTAL
  final TextEditingController _welcomeController = TextEditingController();
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

  bool _isFastAndTestimony = false;

  final List<String> _organizations = [
    'Cuórum de Élderes', 'Sociedad de Socorro', 'Mujeres Jóvenes',
    'Primaria', 'Escuela Dominical', 'Hombres Jóvenes (Aarónico)',
  ];
  String? _selectedOrganization;

  @override
  void initState() {
    super.initState();
    final meeting = widget.meetingToEdit;

    if (meeting != null) {
      _selectedType = meeting.type;
      _timeController.text = meeting.time;
      _presidedByController.text = meeting.presidedBy;
      _directedByController.text = meeting.directedBy;
      _selectedOrganization = meeting.organization;
      _dateController.text = meeting.date.toLocal().toString().split(' ')[0];

      _currentAgendaItems = meeting.agendaItems ?? [];

      if (meeting.sacramentAgenda != null) {
        final ag = meeting.sacramentAgenda!;

        _welcomeController.text = ag.welcome ?? '';
        _openingHymnController.text = ag.openingHymn;
        _openingPrayerController.text = ag.openingPrayer;
        _announcementsController.text = ag.announcements;

        _choristerController.text = ag.chorister ?? '';
        _pianistController.text = ag.pianist ?? '';

        _sacramentHymnController.text = ag.sacramentHymn;
        _closingHymnController.text = ag.closingHymn;
        _closingPrayerController.text = ag.closingPrayer;
        _isFastAndTestimony = ag.isFastAndTestimony;

        if (!_isFastAndTestimony) {
          _firstSpeakerNameController.text = ag.firstSpeakerName ?? '';
          _firstSpeakerTopicController.text = ag.firstSpeakerTopic ?? '';
          _intermediateHymnController.text = ag.intermediateHymn ?? '';
          _secondSpeakerNameController.text = ag.secondSpeakerName ?? '';
          _secondSpeakerTopicController.text = ag.secondSpeakerTopic ?? '';
        }

        _wardBusinessList = List.from(ag.wardBusiness);
      }
    }
  }

  @override
  void dispose() {
    _dateController.dispose();
    _timeController.dispose();
    _directedByController.dispose();
    _presidedByController.dispose();
    _welcomeController.dispose();
    _announcementsController.dispose();
    _openingHymnController.dispose();
    _openingPrayerController.dispose();
    _choristerController.dispose();
    _pianistController.dispose();
    _sacramentHymnController.dispose();
    _firstSpeakerNameController.dispose();
    _firstSpeakerTopicController.dispose();
    _intermediateHymnController.dispose();
    _secondSpeakerNameController.dispose();
    _secondSpeakerTopicController.dispose();
    _closingHymnController.dispose();
    _closingPrayerController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2023),
      lastDate: DateTime(2030),
    );
    if (pickedDate != null) {
      _dateController.text = pickedDate.toLocal().toString().split(' ')[0];
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (picked != null) {
      setState(() {
        // Formateamos la hora a texto y la guardamos en el controlador DIRECTAMENTE
        final localizations = MaterialLocalizations.of(context);
        _timeController.text = localizations.formatTimeOfDay(picked, alwaysUse24HourFormat: false);
      });
    }
  }

  void _showBusinessDialog({WardBusinessModel? itemToEdit, int? index}) {
    String type = itemToEdit?.type ?? 'Sostenimiento';
    final nameCtrl = TextEditingController(text: itemToEdit?.personName ?? '');
    final callingCtrl = TextEditingController(text: itemToEdit?.calling ?? '');

    final isEditing = itemToEdit != null;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEditing ? 'Editar Asunto' : 'Agregar Asunto'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: type,
              items: ['Sostenimiento', 'Relevo', 'Ordenación al Sacerdocio', 'Confirmación', 'Bendición de niño']
                  .map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
              onChanged: (v) => type = v!,
              decoration: const InputDecoration(labelText: 'Tipo', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 15),

            TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Persona', border: OutlineInputBorder())
            ),
            const SizedBox(height: 15),

            TextField(
                controller: callingCtrl,
                decoration: const InputDecoration(labelText: 'Llamamiento (Opcional)', border: OutlineInputBorder())
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.isNotEmpty) {
                setState(() {
                  final newItem = WardBusinessModel(
                    type: type,
                    personName: nameCtrl.text,
                    calling: callingCtrl.text.isEmpty ? null : callingCtrl.text,
                  );

                  if (isEditing && index != null) {
                    _wardBusinessList[index] = newItem;
                  } else {
                    _wardBusinessList.add(newItem);
                  }
                });
                Navigator.pop(ctx);
              }
            },
            child: Text(isEditing ? 'Guardar' : 'Agregar'),
          ),
        ],
      ),
    );
  }

  void _saveMeeting() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final DateTime selectedDate = DateTime.parse(_dateController.text);
      final isEditing = widget.meetingToEdit != null;
      final meetingId = isEditing ? widget.meetingToEdit!.id : null;
      final bool isSacramental = _selectedType == MeetingType.sacramental;
      SacramentAgendaModel? sacramentAgenda;

      try {
        if (isSacramental) {
          sacramentAgenda = SacramentAgendaModel(
            welcome: _welcomeController.text,
            openingHymn: _openingHymnController.text,
            openingPrayer: _openingPrayerController.text,
            announcements: _announcementsController.text,
            chorister: _choristerController.text,
            pianist: _pianistController.text,
            sacramentHymn: _sacramentHymnController.text,
            closingHymn: _closingHymnController.text,
            closingPrayer: _closingPrayerController.text,
            isFastAndTestimony: _isFastAndTestimony,
            wardBusiness: _wardBusinessList,
            firstSpeakerName: _isFastAndTestimony ? null : _firstSpeakerNameController.text,
            firstSpeakerTopic: _isFastAndTestimony ? null : _firstSpeakerTopicController.text,
            intermediateHymn: _isFastAndTestimony ? null : _intermediateHymnController.text,
            secondSpeakerName: _isFastAndTestimony ? null : _secondSpeakerNameController.text,
            secondSpeakerTopic: _isFastAndTestimony ? null : _secondSpeakerTopicController.text,
          );
        }

        if (isEditing) {
          await _meetingService.updateMeeting(
            id: meetingId!,
            type: _selectedType,
            organization: _selectedType == MeetingType.presidency ? _selectedOrganization : null,
            date: selectedDate,
            time: _timeController.text,
            presidedBy: _presidedByController.text,
            directedBy: _directedByController.text,
            sacramentAgenda: sacramentAgenda,
            agendaItems: isSacramental ? null : _currentAgendaItems,
            commitments: _selectedType != MeetingType.sacramental ? [] : null,
          );
        } else {
          await _meetingService.saveMeeting(
            type: _selectedType,
            organization: _selectedType == MeetingType.presidency ? _selectedOrganization : null,
            date: selectedDate,
            time: _timeController.text,
            presidedBy: _presidedByController.text,
            directedBy: _directedByController.text,
            sacramentAgenda: sacramentAgenda,
            agendaItems: isSacramental ? null : _currentAgendaItems,
            commitments: _selectedType != MeetingType.sacramental ? [] : null,
          );
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reunión guardada con éxito.')));
          Navigator.of(context).pop();
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al guardar: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isLeadershipMeeting = _selectedType != MeetingType.sacramental;
    final bool isSacramentalMeeting = _selectedType == MeetingType.sacramental;
    final isEditing = widget.meetingToEdit != null;
    final buttonText = isEditing ? 'Guardar Cambios' : 'Crear Reunión';

    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Editar Reunión' : 'Crear Nueva Reunión')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Tipo de Reunión', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<MeetingType>(
                    decoration: const InputDecoration(border: OutlineInputBorder()),
                    value: _selectedType,
                    items: MeetingType.values.map((MeetingType type) {
                      return DropdownMenuItem<MeetingType>(value: type, child: Text(type.displayName));
                    }).toList(),
                    onChanged: (v) { if (v != null) setState(() { _selectedType = v; }); },
                  ),
                  const SizedBox(height: 20),

                  if (_selectedType == MeetingType.presidency)
                    Padding(
                      padding: const EdgeInsets.only(top: 12.0, bottom: 20.0),
                      child: DropdownButtonFormField<String>(
                        decoration: const InputDecoration(labelText: 'Organización', border: OutlineInputBorder()),
                        value: _selectedOrganization,
                        items: _organizations.map((org) => DropdownMenuItem(value: org, child: Text(org))).toList(),
                        onChanged: (val) => setState(() => _selectedOrganization = val),
                      ),
                    ),

                  const Text('Detalles Básicos', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const Divider(height: 20),
                  TextFormField(
                    controller: _dateController,
                    decoration: const InputDecoration(labelText: 'Fecha', border: OutlineInputBorder(), suffixIcon: Icon(Icons.calendar_today)),
                    readOnly: true, onTap: _selectDate, validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _timeController,
                    decoration: const InputDecoration(labelText: 'Hora', border: OutlineInputBorder(), suffixIcon: Icon(Icons.access_time)),
                    readOnly: true, onTap: _selectTime, validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 12),
                  MemberAutocompleteField( label: 'Preside', controller: _presidedByController, icon: Icons.person_outline, ),
                  const SizedBox(height: 12),
                  MemberAutocompleteField( label: 'Dirige', controller: _directedByController, icon: Icons.person_outline, ),
                  const SizedBox(height: 30),

                  if (isSacramentalMeeting)
                    _buildSacramentAgendaForm()
                  else if (isLeadershipMeeting)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Agenda y Puntos de Revisión', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.secondary)),
                        const Divider(height: 20, color: Colors.black45),
                        AgendaListEditor(
                          initialItems: _currentAgendaItems,
                          onAgendaChanged: (newAgenda) => _currentAgendaItems = newAgenda,
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),

                  const SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: _saveMeeting,
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 15)),
                    child: Text(buttonText, style: const TextStyle(fontSize: 18)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // === AQUÍ ESTÁ EL CAMBIO IMPORTANTE: NOMBRES CORREGIDOS ===
  Widget _buildSacramentAgendaForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Agenda Sacramental', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0089D3))),
        const Divider(height: 20),

        SwitchListTile(
          title: const Text('Primer Domingo (Ayuno y Testimonio)'),
          value: _isFastAndTestimony,
          onChanged: (v) => setState(() => _isFastAndTestimony = v),
        ),
        const SizedBox(height: 15),

        TextFormField(
            controller: _welcomeController,
            maxLines: 2,
            decoration: const InputDecoration(labelText: 'Bienvenida y Reconocimientos', alignLabelWithHint: true)
        ),
        const SizedBox(height: 12),

        TextFormField(
            controller: _announcementsController,
            maxLines: 2,
            decoration: const InputDecoration(labelText: 'Anuncios del Barrio', alignLabelWithHint: true)
        ),
        const SizedBox(height: 12),

        // 1. PRIMER HIMNO
        HymnAutocomplete(
          label: 'Primer Himno',
          controller: _openingHymnController,
          icon: Icons.music_note,
        ),
        const SizedBox(height: 12),


        // 2. DIRECTOR DE MÚSICA Y PIANISTA
        Row(children: [
          Expanded(child: MemberAutocompleteField( label: 'Director(a) de Música', controller: _choristerController, icon: Icons.person_outline, ),
          ),
          const SizedBox(width: 10),
          Expanded(child: MemberAutocompleteField( label: 'Pianista', controller: _pianistController, icon: Icons.person_outline, ),
          ),
        ]),
        const SizedBox(height: 12),

        // 3. PRIMERA ORACIÓN
        Row(
          children: [
            Expanded(child: MemberAutocompleteField( label: 'Primera Oración', controller: _openingPrayerController, icon: Icons.person_outline, ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.print, color: Colors.blueGrey),
              tooltip: 'Imprimir Esquela',
              onPressed: () => _printAssignment(
                name: _openingPrayerController.text,
                type: 'PRIMERA ORACIÓN',
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Sección de Asuntos
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade300)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Asuntos del Barrio', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  TextButton.icon(
                    onPressed: () => _showBusinessDialog(),
                    icon: const Icon(Icons.add), label: const Text('Agregar'),
                  ),
                ],
              ),
              const Divider(),
              if (_wardBusinessList.isEmpty)
                const Text('No hay asuntos pendientes.', style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey))
              else
                ..._wardBusinessList.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;

                  return ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.circle, size: 10, color: Theme.of(context).primaryColor),
                    title: Text('${item.type}: ${item.personName}'),
                    subtitle: item.calling != null ? Text(item.calling!) : null,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, size: 18, color: Colors.blue),
                          onPressed: () => _showBusinessDialog(itemToEdit: item, index: index),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                          onPressed: () => setState(() => _wardBusinessList.removeAt(index)),
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ),
        ),

        const SizedBox(height: 20),

        HymnAutocomplete(
          label: 'Himno Sacramental',
          controller: _sacramentHymnController,
          icon: Icons.music_note,
        ),

        const SizedBox(height: 25),

        // DISCURSANTES
        if (_isFastAndTestimony)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.orange.shade200)),
            child: const Row(children: [Icon(Icons.info_outline, color: Colors.orange), SizedBox(width: 10), Expanded(child: Text('Tiempo de Testimonios', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)))]),
          )
        else
          Column(
            children: [
              // 2. PRIMER DISCURSANTE CON BOTÓN
              Row(
                children: [
                  Expanded(child: MemberAutocompleteField( label: '1er Discursante', controller: _firstSpeakerNameController, icon: Icons.person_outline, ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.print, color: Colors.blueGrey),
                    onPressed: () => _printAssignment(
                      name: _firstSpeakerNameController.text,
                      type: 'PRIMER DISCURSO',
                      topic: _firstSpeakerTopicController.text,
                      duration: '8',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              TextFormField(controller: _firstSpeakerTopicController, decoration: const InputDecoration(labelText: 'Tema 1')),
              const Divider(),
              HymnAutocomplete(
                label: 'Himno Especial (Opcional)',
                controller: _intermediateHymnController,
                icon: Icons.music_note,
              ),
              const Divider(),

              // 3. SEGUNDO DISCURSANTE CON BOTÓN
              Row(
                children: [
                  Expanded(child: MemberAutocompleteField( label: '2do Discursante', controller: _secondSpeakerNameController, icon: Icons.person_outline, ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.print, color: Colors.blueGrey),
                    onPressed: () => _printAssignment(
                      name: _secondSpeakerNameController.text,
                      type: 'ULTIMO DISCURSO',
                      topic: _secondSpeakerTopicController.text,
                      duration: '8',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              TextFormField(controller: _secondSpeakerTopicController, decoration: const InputDecoration(labelText: 'Tema 2')),
            ],
          ),

        const SizedBox(height: 12),
        // 4. ÚLTIMO HIMNO
        HymnAutocomplete(
          label: 'Himno Final',
          controller: _closingHymnController,
          icon: Icons.music_note,
        ),
        const SizedBox(height: 12),

        // 5. ÚLTIMA ORACIÓN
        Row(
          children: [
            Expanded(child: MemberAutocompleteField( label: 'Última Oración', controller: _closingPrayerController, icon: Icons.person_outline, ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.print, color: Colors.blueGrey),
              onPressed: () => _printAssignment(
                name: _closingPrayerController.text,
                type: 'ULTIMA ORACIÓN',
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  // --- FUNCIÓN AUXILIAR PARA IMPRIMIR ASIGNACIONES ---
  Future<void> _printAssignment({
    required String name,
    required String type, // Ej: "TERCER DISCURSO"
    String? topic,
    String duration = "8",
  }) async {
    // VALIDACIÓN IMPORTANTE: Si no hay fecha, no podemos imprimir
    if (_dateController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Por favor, selecciona primero la fecha de la reunión.')));
      return;
    }

    if (name.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ingrese el nombre primero.')));
      return;
    }

    // Preguntar Género
    bool? isMale = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Generar Esquela para $name'),
        content: const Text('¿Es Hermano o Hermana?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('HERMANA')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('HERMANO')),
        ],
      ),
    );

    if (isMale != null && mounted) {
      // Llamar al servicio
      await _citationService.generateSacramentAssignment(
        name: name,
        isMale: isMale,
        assignmentType: type,
        assignmentDate: DateTime.parse(_dateController.text),
        // Botón de imprimir
        time: _timeController.text.isNotEmpty ? _timeController.text : "10:00 AM",
        topic: topic,
        duration: duration,
      );
    }
  }

}