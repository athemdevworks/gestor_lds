import 'package:flutter/material.dart';
import 'package:gestor_lds/features/auth/models/user_model.dart';
import 'package:gestor_lds/features/auth/services/user_service.dart';
import 'package:gestor_lds/features/commitments/services/commitment_service.dart';
import 'package:gestor_lds/features/meetings/models/agenda_item_model.dart';
import 'package:intl/intl.dart';

class NewCommitmentModal extends StatefulWidget {
  final String meetingId;
  final List<AgendaItemModel>? agendaItems; // Lista completa de la agenda
  final AgendaItemModel? initialAgendaItem; // Ítem pre-seleccionado (si venimos del botón lateral)

  const NewCommitmentModal({
    super.key,
    required this.meetingId,
    this.agendaItems,
    this.initialAgendaItem,
  });

  @override
  State<NewCommitmentModal> createState() => _NewCommitmentModalState();
}

class _NewCommitmentModalState extends State<NewCommitmentModal> {
  final _formKey = GlobalKey<FormState>();

  // Controladores de Texto
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _dueDateController = TextEditingController();

  // Servicios
  final UserService _userService = UserService();
  final CommitmentService _commitmentService = CommitmentService();

  // ESTADO - Usamos IDs para los Dropdowns (Más seguro que usar Objetos)
  DateTime? _selectedDueDate;
  bool _isLoading = false;

  // 1. Estado para el USUARIO (Líder)
  String? _selectedUserId;
  UserModel? _selectedUserObject; // Guardamos el objeto para sacar el nombre luego

  // 2. Estado para el PUNTO DE AGENDA
  String? _selectedAgendaItemId;
  AgendaItemModel? _selectedAgendaItemObject; // Guardamos el objeto para sacar el tema luego

  @override
  void initState() {
    super.initState();

    // Si nos pasaron un punto de agenda inicial (desde el botón lateral), lo pre-seleccionamos
    if (widget.initialAgendaItem != null) {
      _selectedAgendaItemId = widget.initialAgendaItem!.id;
      _selectedAgendaItemObject = widget.initialAgendaItem;
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        _selectedDueDate = picked;
        _dueDateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _saveCommitment() async {
    if (_formKey.currentState!.validate() && _selectedUserId != null && _selectedDueDate != null) {
      setState(() { _isLoading = true; });
      try {
        await _commitmentService.addCommitment(
          meetingId: widget.meetingId,
          description: _descriptionController.text,

          // Usamos los datos guardados en el estado
          assignedToUid: _selectedUserId!,
          assignedToName: "${_selectedUserObject!.nombres} ${_selectedUserObject!.apellidos}",
          dueDate: _selectedDueDate!,

          // Datos opcionales de la agenda
          agendaItemId: _selectedAgendaItemId,
          agendaItemTopic: _selectedAgendaItemObject?.topic,
        );

        if (mounted) Navigator.of(context).pop(); // Cerrar modal

      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      } finally {
        if (mounted) setState(() { _isLoading = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Verificamos si hay puntos de agenda para mostrar el dropdown
    final bool hasAgendaItems = widget.agendaItems != null && widget.agendaItems!.isNotEmpty;

    return AlertDialog(
      title: const Text('Asignar Nuevo Compromiso'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // CAMPO 1: DESCRIPCIÓN
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Descripción del Compromiso'),
                maxLines: 3,
                validator: (v) => v!.isEmpty ? 'Ingrese la descripción' : null,
              ),
              const SizedBox(height: 15),

              // CAMPO 2: PUNTO DE AGENDA (Opcional)
              if (hasAgendaItems)
                Padding(
                  padding: const EdgeInsets.only(bottom: 15.0),
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Asociar a Punto de Agenda'),
                    value: _selectedAgendaItemId, // Usamos el ID
                    items: widget.agendaItems!.map((item) {
                      return DropdownMenuItem(
                        value: item.id, // El valor es el ID (String)
                        child: Text(
                          item.topic.length > 30
                              ? '${item.topic.substring(0, 30)}...'
                              : item.topic,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (String? newId) {
                      if (newId != null) {
                        setState(() {
                          _selectedAgendaItemId = newId;
                          // Buscamos el objeto completo para guardar el tema (topic) luego
                          _selectedAgendaItemObject = widget.agendaItems!
                              .firstWhere((item) => item.id == newId);
                        });
                      }
                    },
                  ),
                ),

              // CAMPO 3: FECHA
              TextFormField(
                controller: _dueDateController,
                readOnly: true,
                decoration: const InputDecoration(labelText: 'Fecha de Vencimiento', suffixIcon: Icon(Icons.calendar_today)),
                onTap: _selectDate,
                validator: (v) => v!.isEmpty ? 'Seleccione la fecha' : null,
              ),
              const SizedBox(height: 15),

              // CAMPO 4: ASIGNAR A LÍDER (Dropdown por ID)
              StreamBuilder<List<UserModel>>(
                stream: _userService.streamActiveUsers(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Text('No hay líderes activos.', style: TextStyle(color: Colors.red));
                  }

                  final users = snapshot.data!;
                  return DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Asignar a Líder'),
                    value: _selectedUserId, // Usamos el ID
                    items: users.map((user) {
                      return DropdownMenuItem(
                        value: user.uid, // El valor es el UID (String)
                        child: Text('${user.nombres} ${user.apellidos} (${user.calling})'),
                      );
                    }).toList(),
                    onChanged: (String? newId) {
                      if (newId != null) {
                        setState(() {
                          _selectedUserId = newId;
                          // Buscamos el objeto completo para guardar el nombre luego
                          _selectedUserObject = users.firstWhere((u) => u.uid == newId);
                        });
                      }
                    },
                    validator: (v) => v == null ? 'Seleccione un responsable' : null,
                  );
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
        _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ElevatedButton(onPressed: _saveCommitment, child: const Text('Guardar')),
      ],
    );
  }
}