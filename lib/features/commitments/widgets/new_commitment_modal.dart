import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:gestor_lds/features/auth/models/user_model.dart';
import 'package:gestor_lds/features/auth/services/user_service.dart';
import 'package:gestor_lds/features/commitments/services/commitment_service.dart';
import 'package:gestor_lds/features/commitments/models/commitment_model.dart'; // Importar modelo
import 'package:gestor_lds/features/meetings/models/agenda_item_model.dart';

class NewCommitmentModal extends StatefulWidget {
  final String meetingId;
  final List<AgendaItemModel>? agendaItems;
  final AgendaItemModel? initialAgendaItem;
  final CommitmentModel? commitmentToEdit; // <-- NUEVO: Para modo edición

  const NewCommitmentModal({
    super.key,
    required this.meetingId,
    this.agendaItems,
    this.initialAgendaItem,
    this.commitmentToEdit, // <-- Añadir al constructor
  });

  @override
  State<NewCommitmentModal> createState() => _NewCommitmentModalState();
}

class _NewCommitmentModalState extends State<NewCommitmentModal> {
  final _formKey = GlobalKey<FormState>();

  // Controladores y Servicios
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _dueDateController = TextEditingController();
  final UserService _userService = UserService();
  final CommitmentService _commitmentService = CommitmentService();

  // Estado
  DateTime? _selectedDueDate;
  bool _isLoading = false;
  String? _selectedUserId;
  UserModel? _selectedUserObject;
  String? _selectedAgendaItemId;
  AgendaItemModel? _selectedAgendaItemObject;

  // 1. VARIABLE PARA MANTENER LA CONEXIÓN ESTABLE
  late Stream<List<UserModel>> _usersStream;

  @override
  void initState() {
    super.initState();

    // 2. INICIALIZAMOS EL STREAM UNA SOLA VEZ AL ABRIR
    // Esto evita que la lista se recargue y borre la selección al hacer clic
    _usersStream = _userService.streamActiveUsers();

      // 1. Lógica si estamos EDITANDO un compromiso existente
    if (widget.commitmentToEdit != null) {
      final c = widget.commitmentToEdit!;
      _descriptionController.text = c.description;
      _selectedDueDate = c.dueDate;
      _dueDateController.text = DateFormat('yyyy-MM-dd').format(c.dueDate);

      // Cargar IDs para los Dropdowns
      _selectedUserId = c.assignedToUid;
      // Nota: _selectedUserObject se quedará null hasta que se seleccione otro,
      // pero usaremos c.assignedToName como respaldo al guardar si no cambia.

      _selectedAgendaItemId = c.agendaItemId;
      // Lo mismo para el objeto de agenda item.
    }
      // 2. Lógica si estamos CREANDO desde un botón de agenda (Solo si no estamos editando)
    else if (widget.initialAgendaItem != null) {
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
    // Validación básica
    if (_formKey.currentState!.validate() && _selectedUserId != null && _selectedDueDate != null) {
      setState(() { _isLoading = true; });

      try {
        // Determinar el nombre del usuario (si cambió o se mantiene el original)
        String finalUserName;
        if (_selectedUserObject != null) {
          finalUserName = "${_selectedUserObject!.nombres} ${_selectedUserObject!.apellidos}";
        } else if (widget.commitmentToEdit != null) {
          finalUserName = widget.commitmentToEdit!.assignedToName;
        } else {
          // Caso raro de fallo
          finalUserName = "Usuario Desconocido";
        }

        // Determinar el tópico de agenda
        String? finalTopic;
        if (_selectedAgendaItemObject != null) {
          finalTopic = _selectedAgendaItemObject!.topic;
        } else if (widget.commitmentToEdit != null) {
          finalTopic = widget.commitmentToEdit!.agendaItemTopic;
        }

        if (widget.commitmentToEdit != null) {
          // --- MODO EDICIÓN ---
          final updatedCommitment = CommitmentModel(
            id: widget.commitmentToEdit!.id, // Mismo ID
            meetingId: widget.meetingId,
            description: _descriptionController.text,
            assignedToUid: _selectedUserId!,
            assignedToName: finalUserName,
            dueDate: _selectedDueDate!,
            isCompleted: widget.commitmentToEdit!.isCompleted, // Mantiene estado
            createdAt: widget.commitmentToEdit!.createdAt, // Mantiene fecha crea
            agendaItemId: _selectedAgendaItemId,
            agendaItemTopic: finalTopic,
          );

          await _commitmentService.updateCommitment(updatedCommitment);

        } else {
          // --- MODO CREACIÓN ---
          await _commitmentService.addCommitment(
            meetingId: widget.meetingId,
            description: _descriptionController.text,
            assignedToUid: _selectedUserId!,
            assignedToName: finalUserName,
            dueDate: _selectedDueDate!,
            agendaItemId: _selectedAgendaItemId,
            agendaItemTopic: finalTopic,
          );
        }

        if (mounted) Navigator.of(context).pop();

      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      } finally {
        if (mounted) setState(() { _isLoading = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool hasAgendaItems = widget.agendaItems != null && widget.agendaItems!.isNotEmpty;

    return AlertDialog(
      title: Text(widget.commitmentToEdit != null ? 'Editar Compromiso' : 'Asignar Nuevo Compromiso'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Descripción del Compromiso',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true, // Alinea la etiqueta arriba si el campo es alto
                ),
                maxLines: 3, // Altura visual inicial (3 líneas)
                minLines: 2, // Mínimo de líneas
                keyboardType: TextInputType.multiline, // Habilita el teclado con "Enter"                maxLines: 3,
                validator: (v) => v!.isEmpty ? 'Ingrese la descripción' : null,
              ),
              const SizedBox(height: 15),

              if (hasAgendaItems)
                Padding(
                  padding: const EdgeInsets.only(bottom: 15.0),
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Asociar a Punto de Agenda'),
                    value: _selectedAgendaItemId,
                    items: widget.agendaItems!.map((item) {
                      return DropdownMenuItem(
                        value: item.id,
                        child: Text(
                          item.topic.length > 30 ? '${item.topic.substring(0, 30)}...' : item.topic,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (String? newId) {
                      if (newId != null) {
                        setState(() {
                          _selectedAgendaItemId = newId;
                          _selectedAgendaItemObject = widget.agendaItems!.firstWhere((item) => item.id == newId);
                        });
                      }
                    },
                  ),
                ),

              TextFormField(
                controller: _dueDateController,
                readOnly: true,
                decoration: const InputDecoration(labelText: 'Fecha de Vencimiento', suffixIcon: Icon(Icons.calendar_today)),
                onTap: _selectDate,
                validator: (v) => v!.isEmpty ? 'Seleccione la fecha' : null,
              ),
              const SizedBox(height: 15),

              // USAMOS EL STREAM ESTABLE CREADO EN INITSTATE

              // CAMPO 4: ASIGNAR A LÍDER (Con Búsqueda)
              StreamBuilder<List<UserModel>>(
                stream: _usersStream,
                builder: (context, snapshot) {
                  // 1. Estados de Carga / Error
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Text('No hay líderes activos.', style: TextStyle(color: Colors.red));
                  }

                  // 2. Limpieza de datos (Evitar duplicados)
                  final rawUsers = snapshot.data!;
                  final uniqueUsers = <String, UserModel>{};
                  for (var user in rawUsers) {
                    uniqueUsers[user.uid] = user;
                  }
                  final users = uniqueUsers.values.toList();

                  // 3. NUEVO WIDGET: DropdownMenu (Searchable)
                  return DropdownMenu<String>(
                    // AGREGAMOS ESTO PARA QUE OCUPE TODO EL ANCHO:
                    expandedInsets: EdgeInsets.zero,

                    label: const Text('Asignar a Líder'),
                    hintText: 'Escribe para buscar...',
                    menuHeight: 300,
                    enableFilter: true,
                    requestFocusOnTap: true,

                    initialSelection: _selectedUserId,

                    dropdownMenuEntries: users.map((user) {
                      return DropdownMenuEntry<String>(
                        value: user.uid,
                        label: '${user.nombres} ${user.apellidos}',
                        leadingIcon: const Icon(Icons.person_outline, size: 18),
                      );
                    }).toList(),

                    onSelected: (String? newId) {
                      if (newId != null) {
                        setState(() {
                          _selectedUserId = newId;
                          _selectedUserObject = users.firstWhere((u) => u.uid == newId);
                        });
                      }
                    },

                    inputDecorationTheme: const InputDecorationTheme(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
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