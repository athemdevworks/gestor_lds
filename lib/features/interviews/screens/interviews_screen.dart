import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:gestor_lds/features/auth/models/user_model.dart';
import 'package:gestor_lds/features/interviews/models/interview_model.dart';
import 'package:gestor_lds/features/interviews/services/interview_service.dart';

class InterviewsScreen extends StatefulWidget {
  final UserModel currentUser;

  const InterviewsScreen({super.key, required this.currentUser});

  @override
  State<InterviewsScreen> createState() => _InterviewsScreenState();
}

class _InterviewsScreenState extends State<InterviewsScreen> {
  final InterviewService _service = InterviewService();
  final Color _brandBlue = const Color(0xFF164772);

  bool get _isAdmin => widget.currentUser.role == UserRole.obispado;

  // Filtro seleccionado por el miembro (Por defecto "Todos")
  String _selectedFilterRole = 'Todos';

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFEEF2F6),
        appBar: AppBar(
          title: const Text('Entrevistas y Citas'),
          backgroundColor: _isAdmin ? _brandBlue : Colors.white,
          foregroundColor: _isAdmin ? Colors.white : Colors.black,
          elevation: 0,
          bottom: TabBar(
            labelColor: _isAdmin ? Colors.white : _brandBlue,
            unselectedLabelColor: Colors.grey,
            indicatorColor: _isAdmin ? Colors.white : _brandBlue,
            tabs: const [
              Tab(text: 'DISPONIBLES', icon: Icon(Icons.calendar_today)),
              Tab(text: 'MIS CITAS', icon: Icon(Icons.bookmark_added)),
            ],
          ),
        ),

        floatingActionButton: _isAdmin
            ? FloatingActionButton.extended(
          backgroundColor: _brandBlue,
          icon: const Icon(Icons.add_alarm, color: Colors.white),
          label: const Text('Crear Horarios', style: TextStyle(color: Colors.white)),
          onPressed: () => _showCreateSlotsDialog(context),
        )
            : null,

        body: TabBarView(
          children: [
            // PESTAÑA 1: DISPONIBLES (Con Filtro)
            Column(
              children: [
                // --- BARRA DE FILTROS ---
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                  color: Colors.white,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        const Text('Filtrar por:  ', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                        _buildFilterChip('Todos'),
                        const SizedBox(width: 8),
                        _buildFilterChip('Obispo'),
                        const SizedBox(width: 8),
                        _buildFilterChip('1er Consejero'),
                        const SizedBox(width: 8),
                        _buildFilterChip('2do Consejero'),
                      ],
                    ),
                  ),
                ),

                // --- LISTA FILTRADA ---
                Expanded(
                  child: _buildSlotsList(
                    stream: _isAdmin ? _service.getAllSlots() : _service.getAvailableSlots(),
                    emptyMessage: _isAdmin
                        ? 'No hay horarios creados.'
                        : 'No hay citas disponibles para este líder.',
                    isMyAppointmentTab: false,
                    filterRole: _selectedFilterRole, // Pasamos el filtro
                  ),
                ),
              ],
            ),

            // PESTAÑA 2: MIS CITAS (Sin filtro de rol, muestra todas las mías)
            _buildSlotsList(
              stream: _service.getMyAppointments(widget.currentUser.uid),
              emptyMessage: 'No tienes ninguna cita agendada.',
              isMyAppointmentTab: true,
              filterRole: 'Todos',
            ),
          ],
        ),
      ),
    );
  }

  // Widget para el Chip de Filtro
  Widget _buildFilterChip(String label) {
    final isSelected = _selectedFilterRole == label;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) setState(() => _selectedFilterRole = label);
      },
      selectedColor: _brandBlue.withOpacity(0.2),
      labelStyle: TextStyle(
        color: isSelected ? _brandBlue : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      backgroundColor: Colors.grey.shade100,
    );
  }

  Widget _buildSlotsList({
    required Stream<List<InterviewModel>> stream,
    required String emptyMessage,
    required bool isMyAppointmentTab,
    required String filterRole,
  }) {
    return StreamBuilder<List<InterviewModel>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState(emptyMessage);
        }

        // --- APLICAMOS EL FILTRO EN MEMORIA ---
        // Si el filtro es "Todos", pasamos todo. Si no, filtramos por rol exacto.
        var slots = snapshot.data!;
        if (filterRole != 'Todos') {
          slots = slots.where((s) => s.interviewerRole == filterRole).toList();
        }

        if (slots.isEmpty) {
          return _buildEmptyState(emptyMessage);
        }
        // --------------------------------------

        return ListView.builder(
          padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: _isAdmin ? 80 : 16),
          itemCount: slots.length,
          itemBuilder: (context, index) {
            final slot = slots[index];
            return _buildSlotCard(slot, isMyAppointmentTab);
          },
        );
      },
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_busy, size: 60, color: Colors.grey[300]),
          const SizedBox(height: 10),
          Text(message, style: TextStyle(color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildSlotCard(InterviewModel slot, bool isMyAppointmentTab) {
    final dateStr = DateFormat("EEEE d 'de' MMMM", 'es_ES').format(slot.startTime);
    final timeStr = "${DateFormat('h:mm a').format(slot.startTime)} - ${DateFormat('h:mm a').format(slot.endTime)}";
    final isReserved = slot.isReserved;

    // Colores e Iconos según disponibilidad
    Color statusColor = isReserved ? Colors.orange.shade100 : Colors.green.shade100;
    Color statusText = isReserved ? Colors.orange.shade800 : Colors.green.shade800;

    // Si es MI cita
    if (isReserved && slot.memberId == widget.currentUser.uid) {
      statusColor = Colors.purple.shade100;
      statusText = Colors.purple.shade800;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: ListTile(
          // Icono lateral
          leading: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: statusColor, borderRadius: BorderRadius.circular(8)),
                child: Icon(Icons.access_time, color: statusText, size: 20),
              ),
            ],
          ),

          title: Row(
            children: [
              // Etiqueta del ROL (Ej: Obispo)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.grey.shade300)
                ),
                child: Text(
                  slot.interviewerRole,
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
                ),
              ),
              const SizedBox(width: 8),
              // Estado
              Text(
                isReserved && _isAdmin
                    ? (slot.memberName ?? 'Reservado')
                    : (isMyAppointmentTab ? 'Confirmada' : 'Disponible'),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),

          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(dateStr.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                Text(timeStr, style: const TextStyle(fontSize: 13, color: Colors.black87)),
                if (isReserved && slot.note != null && (_isAdmin || isMyAppointmentTab))
                  Text("Nota: ${slot.note}", style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic)),
              ],
            ),
          ),

          trailing: _buildActionButtons(slot, isMyAppointmentTab),
        ),
      ),
    );
  }

  Widget? _buildActionButtons(InterviewModel slot, bool isMyTab) {
    if (_isAdmin) {
      return IconButton(
        icon: const Icon(Icons.delete_outline, color: Colors.red),
        onPressed: () => _service.deleteSlot(slot.id),
      );
    }
    if (isMyTab) {
      return ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 10)),
        onPressed: () => _cancelAppointment(slot),
        child: const Text('Cancelar', style: TextStyle(fontSize: 12)),
      );
    }
    if (!slot.isReserved) {
      return ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: _brandBlue, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 10)),
        onPressed: () => _showReservationDialog(context, slot),
        child: const Text('Reservar', style: TextStyle(fontSize: 12)),
      );
    }
    return null;
  }

  // --- DIÁLOGOS DE ACCIÓN ---

  void _showReservationDialog(BuildContext context, InterviewModel slot) {
    final noteController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Cita con: ${slot.interviewerRole}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Confirma que deseas reservar este horario.'),
            const SizedBox(height: 15),
            TextField(
              controller: noteController,
              decoration: const InputDecoration(labelText: 'Motivo (Opcional)', hintText: 'Ej: Renovación', border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _service.reserveSlot(
                slotId: slot.id,
                userId: widget.currentUser.uid,
                userName: "${widget.currentUser.nombres} ${widget.currentUser.apellidos}",
                reason: noteController.text.trim().isEmpty ? 'Entrevista Personal' : noteController.text.trim(),
              );
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('¡Cita reservada!')));
            },
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelAppointment(InterviewModel slot) async {
    bool confirm = await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Cancelar Cita'),
          content: const Text('¿Seguro que deseas cancelar? El horario quedará libre.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('No')),
            TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Sí, Cancelar')),
          ],
        )
    ) ?? false;

    if (confirm) {
      await _service.cancelReservation(slot.id);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cita cancelada.')));
    }
  }

  // --- NUEVO: DIÁLOGO DE CREACIÓN CON SELECCIÓN DE LÍDER ---
  void _showCreateSlotsDialog(BuildContext context) {
    DateTime selectedDate = DateTime.now();
    TimeOfDay startTime = const TimeOfDay(hour: 9, minute: 0);
    TimeOfDay endTime = const TimeOfDay(hour: 11, minute: 0);
    int duration = 15;

    // ROL SELECCIONADO PARA CREAR
    String targetRole = 'Obispo';
    final List<String> roles = ['Obispo', '1er Consejero', '2do Consejero'];

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Generar Bloque'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // --- SELECTOR DE LÍDER ---
                    DropdownButtonFormField<String>(
                      value: targetRole,
                      decoration: const InputDecoration(labelText: '¿Para quién son las citas?', border: OutlineInputBorder()),
                      items: roles.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                      onChanged: (v) => setState(() => targetRole = v!),
                    ),
                    const SizedBox(height: 15),
                    // -------------------------

                    ListTile(
                      title: const Text('Fecha'),
                      subtitle: Text(DateFormat('EEEE d MMMM', 'es_ES').format(selectedDate)),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 60)),
                          locale: const Locale('es', 'ES'),
                        );
                        if (picked != null) setState(() => selectedDate = picked);
                      },
                    ),
                    ListTile(
                      title: const Text('Hora Inicio'),
                      subtitle: Text(startTime.format(context)),
                      trailing: const Icon(Icons.access_time),
                      onTap: () async {
                        final picked = await showTimePicker(context: context, initialTime: startTime);
                        if (picked != null) setState(() => startTime = picked);
                      },
                    ),
                    ListTile(
                      title: const Text('Hora Fin'),
                      subtitle: Text(endTime.format(context)),
                      trailing: const Icon(Icons.access_time_filled),
                      onTap: () async {
                        final picked = await showTimePicker(context: context, initialTime: endTime);
                        if (picked != null) setState(() => endTime = picked);
                      },
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<int>(
                      value: duration,
                      decoration: const InputDecoration(labelText: 'Duración (min)', border: OutlineInputBorder()),
                      items: const [
                        DropdownMenuItem(value: 10, child: Text('10 min')),
                        DropdownMenuItem(value: 15, child: Text('15 min')),
                        DropdownMenuItem(value: 20, child: Text('20 min')),
                        DropdownMenuItem(value: 30, child: Text('30 min')),
                      ],
                      onChanged: (v) => setState(() => duration = v!),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: _brandBlue, foregroundColor: Colors.white),
                  onPressed: () async {
                    Navigator.pop(ctx);
                    await _generateSlots(selectedDate, startTime, endTime, duration, targetRole);
                  },
                  child: const Text('Generar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Generador actualizado con ROL
  Future<void> _generateSlots(DateTime date, TimeOfDay start, TimeOfDay end, int durationMinutes, String role) async {
    DateTime startDT = DateTime(date.year, date.month, date.day, start.hour, start.minute);
    DateTime endDT = DateTime(date.year, date.month, date.day, end.hour, end.minute);

    if (endDT.isBefore(startDT)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error: Hora fin inválida')));
      return;
    }

    int count = 0;
    while (startDT.add(Duration(minutes: durationMinutes)).isBefore(endDT) ||
        startDT.add(Duration(minutes: durationMinutes)).isAtSameMomentAs(endDT)) {

      await _service.createSlot(
          start: startDT,
          durationMinutes: durationMinutes,
          adminId: widget.currentUser.uid,
          role: role // <--- PASAMOS EL ROL
      );

      startDT = startDT.add(Duration(minutes: durationMinutes));
      count++;
    }
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Se crearon $count espacios para $role.')));
  }
}