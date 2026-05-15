import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:gestor_lds/features/activities/models/activity_model.dart';
import 'package:gestor_lds/features/activities/services/activity_service.dart';

class ActivityFormScreen extends StatefulWidget {
  final ActivityModel? activityToEdit;

  const ActivityFormScreen({super.key, this.activityToEdit});

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

  // Variable para manejar la fecha real (más seguro que parsear texto)
  DateTime? _selectedDate;

  String _selectedOrg = 'Barrio';
  final List<String> _organizations = [
    'Barrio', 'Obispado', 'Cuórum de Élderes', 'Sociedad de Socorro',
    'Hombres Jóvenes', 'Mujeres Jóvenes', 'Primaria', 'Escuela Dominical'
  ];

  @override
  void initState() {
    super.initState();
    if (widget.activityToEdit != null) {
      final a = widget.activityToEdit!;
      _titleController.text = a.title;
      _descController.text = a.description;

      // Asignamos fecha al controlador y a la variable de estado
      _selectedDate = a.date;
      _dateController.text = DateFormat('yyyy-MM-dd').format(a.date);

      _timeController.text = a.time;
      _locationController.text = a.location;

      // Validación segura por si la organización antigua ya no existe en la lista
      _selectedOrg = _organizations.contains(a.organization) ? a.organization : 'Barrio';
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
      locale: const Locale('es', 'ES'),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        // Formato visual amigable para el input
        _dateController.text = DateFormat('EEEE d MMMM, yyyy', 'es').format(picked);
      });
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now()
    );
    if (picked != null) {
      // Formato AM/PM
      final now = DateTime.now();
      final dt = DateTime(now.year, now.month, now.day, picked.hour, picked.minute);
      _timeController.text = DateFormat.jm().format(dt);
    }
  }

  void _save() async {
    if (_formKey.currentState!.validate()) {

      if (_selectedDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Por favor selecciona una fecha')));
        return;
      }

      final activity = ActivityModel(
        id: widget.activityToEdit?.id ?? '', // El servicio generará el ID si está vacío
        title: _titleController.text,
        description: _descController.text,
        date: _selectedDate!, // Usamos la variable DateTime directa
        time: _timeController.text,
        location: _locationController.text,
        organization: _selectedOrg,
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
                        prefixIcon: Icon(Icons.title)
                    ),
                    validator: (v) => v!.isEmpty ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 15),

                  DropdownButtonFormField<String>(
                    value: _selectedOrg,
                    decoration: const InputDecoration(labelText: 'Organización', border: OutlineInputBorder(), prefixIcon: Icon(Icons.groups)),
                    items: _organizations.map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
                    onChanged: (v) => setState(() => _selectedOrg = v!),
                  ),
                  const SizedBox(height: 15),

                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _dateController,
                          decoration: const InputDecoration(labelText: 'Fecha', border: OutlineInputBorder(), prefixIcon: Icon(Icons.calendar_today)),
                          readOnly: true, onTap: _selectDate,
                          validator: (v) => v!.isEmpty ? 'Requerido' : null,
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: TextFormField(
                          controller: _timeController,
                          decoration: const InputDecoration(labelText: 'Hora', border: OutlineInputBorder(), prefixIcon: Icon(Icons.access_time)),
                          readOnly: true, onTap: _selectTime,
                          validator: (v) => v!.isEmpty ? 'Requerido' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),

                  TextFormField(
                    controller: _locationController,
                    decoration: const InputDecoration(labelText: 'Lugar', border: OutlineInputBorder(), prefixIcon: Icon(Icons.location_on)),
                    validator: (v) => v!.isEmpty ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 15),

                  TextFormField(
                    controller: _descController,
                    maxLines: 3,
                    decoration: const InputDecoration(labelText: 'Detalles / Asignaciones', border: OutlineInputBorder(), prefixIcon: Icon(Icons.description)),
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
                          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
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