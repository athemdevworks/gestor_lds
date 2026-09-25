import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:gestor_lds/features/activities/models/activity_model.dart';
import 'package:gestor_lds/features/activities/services/activity_service.dart';
import 'package:gestor_lds/features/auth/models/user_model.dart';

class ActivityFormScreen extends StatefulWidget {
  final ActivityModel? activityToEdit;
  final UserModel? currentUser;

  const ActivityFormScreen({
    super.key,
    this.activityToEdit,
    this.currentUser,
  });

  @override
  State<ActivityFormScreen> createState() => _ActivityFormScreenState();
}

class _ActivityFormScreenState extends State<ActivityFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final ActivityService _service = ActivityService();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  DateTime? _selectedDate;

  String _selectedOrg = 'Barrio';
  String _selectedVisibility = 'ward'; // 🚀 'ward', 'stake', 'leadership'

  final List<String> _organizations = [
    'Barrio',
    'Estaca',
    'Presidencia de Estaca',
    'JAS (Jóvenes Adultos Solteros)',
    'Cuórum de Élderes',
    'Sociedad de Socorro',
    'Hombres Jóvenes',
    'Mujeres Jóvenes',
    'Primaria',
    'Escuela Dominical',
    'Templo e Historia Familiar',
    'Obra Misional',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.activityToEdit != null) {
      final a = widget.activityToEdit!;
      _titleController.text = a.title;
      _descController.text = a.description;
      _selectedDate = a.date;
      _dateController.text = DateFormat('EEEE d MMMM, yyyy', 'es').format(a.date);
      _timeController.text = a.time;
      _locationController.text = a.location;
      _selectedOrg = _organizations.contains(a.organization) ? a.organization : 'Barrio';

      // Mapeo seguro de visibilidad para actividades existentes
      _selectedVisibility = ['ward', 'stake', 'leadership'].contains(a.visibility)
          ? a.visibility
          : (a.ward.toLowerCase() == 'estaca' ? 'stake' : 'ward');
    } else {
      if (widget.currentUser?.role == UserRole.presidencia_estaca ||
          widget.currentUser?.role == UserRole.lider_estaca) {
        _selectedOrg = 'Estaca';
        _selectedVisibility = 'stake';
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime initial = _selectedDate ?? DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(DateTime(2020)) ? DateTime.now() : initial,
      firstDate: DateTime(2020), // 🚀 Previene fallo en actividades pasadas
      lastDate: DateTime(2030),
      locale: const Locale('es', 'ES'),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = DateFormat('EEEE d MMMM, yyyy', 'es').format(picked);
      });
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      final now = DateTime.now();
      final dt = DateTime(now.year, now.month, now.day, picked.hour, picked.minute);
      _timeController.text = DateFormat.jm().format(dt);
    }
  }

  void _save() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Por favor selecciona una fecha')),
        );
        return;
      }

      // Si es organizada por la Estaca, se fija 'Estaca'; de lo contrario conserva el barrio anfitrión
      String targetWard = widget.activityToEdit?.ward ?? widget.currentUser?.ward ?? '';
      if (widget.currentUser?.role == UserRole.presidencia_estaca ||
          widget.currentUser?.role == UserRole.lider_estaca ||
          _selectedOrg == 'Estaca' ||
          _selectedOrg == 'Presidencia de Estaca') {
        targetWard = 'Estaca';
      }

      final activity = ActivityModel(
        id: widget.activityToEdit?.id ?? '',
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        date: _selectedDate!,
        time: _timeController.text.trim(),
        location: _locationController.text.trim(),
        organization: _selectedOrg,
        ward: targetWard,
        visibility: _selectedVisibility,
      );

      try {
        if (widget.activityToEdit == null) {
          await _service.saveActivity(activity);
        } else {
          await _service.updateActivity(activity);
        }
        if (mounted) Navigator.pop(context);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const brandBlue = Color(0xFF22539A);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.activityToEdit == null ? 'Nueva Actividad' : 'Editar Actividad'),
        backgroundColor: brandBlue,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Título de la Actividad',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.title),
                    ),
                    validator: (v) => v!.isEmpty ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 15),

                  DropdownButtonFormField<String>(
                    value: _selectedOrg,
                    decoration: const InputDecoration(
                      labelText: 'Organización',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.groups),
                    ),
                    items: _organizations.map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
                    onChanged: (v) => setState(() => _selectedOrg = v!),
                  ),
                  const SizedBox(height: 15),

                  // 🚀 Selector de Alcance y Privacidad
                  DropdownButtonFormField<String>(
                    value: _selectedVisibility,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Alcance / Visibilidad',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.visibility_outlined),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'ward',
                        child: Text('Solo mi Barrio (Actividad Local)'),
                      ),
                      DropdownMenuItem(
                        value: 'stake',
                        child: Text('Toda la Estaca (Conferencias, JAS, etc.)'),
                      ),
                      DropdownMenuItem(
                        value: 'leadership',
                        child: Text('Privado: Solo Liderazgo / Sumo Consejo'),
                      ),
                    ],
                    onChanged: (v) => setState(() => _selectedVisibility = v!),
                  ),
                  const SizedBox(height: 15),

                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _dateController,
                          decoration: const InputDecoration(
                            labelText: 'Fecha',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.calendar_today),
                          ),
                          readOnly: true,
                          onTap: _selectDate,
                          validator: (v) => v!.isEmpty ? 'Requerido' : null,
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: TextFormField(
                          controller: _timeController,
                          decoration: const InputDecoration(
                            labelText: 'Hora',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.access_time),
                          ),
                          readOnly: true,
                          onTap: _selectTime,
                          validator: (v) => v!.isEmpty ? 'Requerido' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),

                  TextFormField(
                    controller: _locationController,
                    decoration: const InputDecoration(
                      labelText: 'Lugar',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.location_on),
                    ),
                    validator: (v) => v!.isEmpty ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 15),

                  TextFormField(
                    controller: _descController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Detalles / Asignaciones',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.description),
                    ),
                  ),
                  const SizedBox(height: 30),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _save,
                      icon: const Icon(Icons.save),
                      label: const Text('Guardar Actividad'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: brandBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}