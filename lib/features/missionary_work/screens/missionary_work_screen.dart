import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:gestor_lds/core/constants/wards_list.dart';
import 'package:gestor_lds/features/auth/models/user_model.dart';

class MissionaryWorkScreen extends StatefulWidget {
  final bool isStakeMode;
  final UserModel currentUser;

  const MissionaryWorkScreen({
    super.key,
    required this.isStakeMode,
    required this.currentUser,
  });

  @override
  State<MissionaryWorkScreen> createState() => _MissionaryWorkScreenState();
}

class _MissionaryWorkScreenState extends State<MissionaryWorkScreen>
    with SingleTickerProviderStateMixin {
  static const Color _brandBlue = Color(0xFF22539A);

  late TabController _tabController;
  late String _targetWard;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _targetWard = widget.isStakeMode ? 'Todos' : widget.currentUser.ward;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  bool get _canManage {
    if (widget.currentUser.role == UserRole.admin ||
        widget.currentUser.role == UserRole.presidencia_estaca ||
        widget.currentUser.role == UserRole.obispado) {
      return true;
    }
    final callings = widget.currentUser.callings.map((c) => c.toLowerCase()).toList();
    return callings.any((c) =>
    c.contains('misional') ||
        c.contains('misión') ||
        c.contains('élderes') ||
        c.contains('socorro'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEF2F6),
      appBar: AppBar(
        title: Text(
          widget.isStakeMode ? 'Obra Misional (Estaca)' : 'Obra Misional',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: _brandBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.amber.shade600,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          tabs: const [
            Tab(icon: Icon(Icons.forum_outlined, size: 20), text: 'COORDINACIÓN'),
            Tab(icon: Icon(Icons.handshake_outlined, size: 20), text: 'ACOMPAÑAMIENTOS'),
            Tab(icon: Icon(Icons.water_drop_outlined, size: 20), text: 'BAUTISMOS'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Selector de barrio para líderes de estaca
          if (widget.isStakeMode)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.white,
              child: DropdownButtonFormField<String>(
                value: _targetWard,
                decoration: InputDecoration(
                  labelText: 'Filtrar por Barrio',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  isDense: true,
                  prefixIcon: const Icon(Icons.location_city),
                ),
                items: ['Todos', ...kWardsList]
                    .map((b) => DropdownMenuItem(value: b, child: Text(b, style: const TextStyle(fontSize: 14))))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _targetWard = val);
                },
              ),
            ),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildCoordinacionTab(),
                _buildAcompanamientoTab(),
                _buildBautismosTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 1. PESTAÑA: COORDINACIÓN MISIONAL SEMANAL
  // ===========================================================================
  Widget _buildCoordinacionTab() {
    Query query = FirebaseFirestore.instance.collection('missionary_coordinations').orderBy('meetingDate', descending: true);
    if (_targetWard != 'Todos') {
      query = query.where('ward', isEqualTo: _targetWard);
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: _canManage
          ? FloatingActionButton.extended(
        backgroundColor: _brandBlue,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Nueva Coordinación', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: () => _showAddCoordinationModal(context),
      )
          : null,
      body: StreamBuilder<QuerySnapshot>(
        stream: query.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState(
              icon: Icons.forum_outlined,
              message: 'No hay reuniones de coordinación misional registradas.',
            );
          }

          final docs = snapshot.data!.docs;
          return ListView.builder(
            padding: const EdgeInsets.all(14),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final String id = doc.id;
              final DateTime date = (data['meetingDate'] as Timestamp).toDate();
              final String formattedDate = DateFormat("EEEE d 'de' MMMM", 'es_ES').format(date);
              final List<dynamic> focusFriends = data['focusFriends'] ?? [];
              final List<dynamic> commitments = data['commitments'] ?? [];
              final String ward = data['ward'] ?? '';

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: _brandBlue.withOpacity(0.1),
                                child: const Icon(Icons.calendar_today, color: _brandBlue, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    formattedDate[0].toUpperCase() + formattedDate.substring(1),
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                  ),
                                  Text('Barrio $ward', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                                ],
                              ),
                            ],
                          ),
                          if (_canManage)
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                              onPressed: () => _confirmDelete(context, 'missionary_coordinations', id, 'esta reunión'),
                            ),
                        ],
                      ),
                      const Divider(height: 24),

                      // Amigos en foco
                      const Text('Amigos en Enseñanza Activa:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87)),
                      const SizedBox(height: 6),
                      if (focusFriends.isEmpty)
                        const Text('Ninguno especificado.', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic, fontSize: 12))
                      else
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: focusFriends.map((f) => Chip(
                            backgroundColor: Colors.blue.shade50,
                            side: BorderSide.none,
                            avatar: const Icon(Icons.person, size: 16, color: _brandBlue),
                            label: Text(f.toString(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _brandBlue)),
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          )).toList(),
                        ),
                      const SizedBox(height: 14),

                      // Compromisos de la semana
                      const Text('Compromisos Acordados:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87)),
                      const SizedBox(height: 6),
                      if (commitments.isEmpty)
                        const Text('Sin compromisos pendientes.', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic, fontSize: 12))
                      else
                        ...commitments.asMap().entries.map((entry) {
                          final int idx = entry.key;
                          final Map<String, dynamic> c = Map<String, dynamic>.from(entry.value);
                          final bool isDone = c['done'] == true;

                          return CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                            visualDensity: VisualDensity.compact,
                            activeColor: Colors.green.shade700,
                            title: Text(
                              c['task'] ?? '',
                              style: TextStyle(
                                fontSize: 13,
                                decoration: isDone ? TextDecoration.lineThrough : null,
                                color: isDone ? Colors.grey : Colors.black87,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            subtitle: Text('Resp: ${c['responsible'] ?? 'Sin asignar'}', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                            value: isDone,
                            onChanged: _canManage
                                ? (val) {
                              commitments[idx]['done'] = val;
                              FirebaseFirestore.instance
                                  .collection('missionary_coordinations')
                                  .doc(id)
                                  .update({'commitments': commitments});
                            }
                                : null,
                          );
                        }),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // ===========================================================================
  // 2. PESTAÑA: BOLSA DE ACOMPAÑAMIENTO (SALIDAS CON MIEMBROS)
  // ===========================================================================
  Widget _buildAcompanamientoTab() {
    Query query = FirebaseFirestore.instance.collection('missionary_appointments').orderBy('dateTime', descending: false);
    if (_targetWard != 'Todos') {
      query = query.where('ward', isEqualTo: _targetWard);
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: _canManage
          ? FloatingActionButton.extended(
        backgroundColor: _brandBlue,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_location_alt),
        label: const Text('Publicar Salida', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: () => _showAddAppointmentModal(context),
      )
          : null,
      body: StreamBuilder<QuerySnapshot>(
        stream: query.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState(
              icon: Icons.handshake_outlined,
              message: 'No hay salidas o citas que requieran acompañante por ahora.',
            );
          }

          final docs = snapshot.data!.docs;
          return ListView.builder(
            padding: const EdgeInsets.all(14),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final String id = doc.id;
              final DateTime dateTime = (data['dateTime'] as Timestamp).toDate();
              final String formattedTime = DateFormat("EEEE d/MM 'a las' h:mm a", 'es_ES').format(dateTime);
              final String place = data['place'] ?? 'Ubicación acordada';
              final String friendName = data['contactName'] ?? 'Amigo de la Iglesia';
              final String missionaries = data['missionaries'] ?? 'Élderes / Hermanas';
              final String? assignedMember = data['assignedMember'];
              final String? phone = data['phone'];
              final bool isCovered = assignedMember != null && assignedMember.isNotEmpty;

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: isCovered
                      ? BorderSide.none
                      : BorderSide(color: Colors.orange.shade700, width: 1.5),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isCovered ? Colors.green.shade50 : Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isCovered ? Colors.green.shade600 : Colors.orange.shade700,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  isCovered ? Icons.check_circle : Icons.warning_amber_rounded,
                                  size: 14,
                                  color: isCovered ? Colors.green.shade700 : Colors.orange.shade800,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  isCovered ? 'CUBIERTO' : '¡SE BUSCA ACOMPAÑANTE!',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: isCovered ? Colors.green.shade700 : Colors.orange.shade900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (_canManage)
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                              onPressed: () => _confirmDelete(context, 'missionary_appointments', id, 'esta salida'),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      Text(
                        'Visita con: $friendName',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.access_time, size: 16, color: Colors.grey.shade600),
                          const SizedBox(width: 6),
                          Text(formattedTime, style: TextStyle(color: Colors.grey.shade800, fontSize: 13, fontWeight: FontWeight.w500)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.location_on_outlined, size: 16, color: Colors.grey.shade600),
                          const SizedBox(width: 6),
                          Expanded(child: Text(place, style: TextStyle(color: Colors.grey.shade700, fontSize: 13))),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.group_outlined, size: 16, color: Colors.grey.shade600),
                          const SizedBox(width: 6),
                          Expanded(child: Text('Misioneros: $missionaries', style: TextStyle(color: Colors.grey.shade700, fontSize: 13))),
                        ],
                      ),
                      const Divider(height: 24),

                      // Estado de cobertura y botón de acción
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              isCovered
                                  ? 'Acompañante: $assignedMember'
                                  : 'Disponible para cualquier hermano(a)',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isCovered ? Colors.green.shade800 : Colors.orange.shade900,
                              ),
                            ),
                          ),
                          if (!isCovered)
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _brandBlue,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              icon: const Icon(Icons.how_to_reg, size: 18),
                              label: const Text('Acompañar'),
                              onPressed: () {
                                final memberName = '${widget.currentUser.firstName} ${widget.currentUser.lastName}'.trim();
                                FirebaseFirestore.instance.collection('missionary_appointments').doc(id).update({
                                  'assignedMember': memberName,
                                  'memberUid': widget.currentUser.uid,
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('🎉 ¡Gracias por apoyar! Quedaste registrado como acompañante.'), backgroundColor: Colors.green),
                                );
                              },
                            )
                          else if (data['memberUid'] == widget.currentUser.uid || _canManage)
                            TextButton(
                              child: const Text('Cancelar apoyo', style: TextStyle(color: Colors.red, fontSize: 12)),
                              onPressed: () {
                                FirebaseFirestore.instance.collection('missionary_appointments').doc(id).update({
                                  'assignedMember': null,
                                  'memberUid': null,
                                });
                              },
                            ),
                          if (phone != null && phone.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.message, color: Color(0xFF25D366)),
                              tooltip: 'Coordinar por WhatsApp',
                              onPressed: () => _launchWhatsApp(phone, 'Hola Élderes/Hermanas, sobre la cita con $friendName...'),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // ===========================================================================
  // 3. PESTAÑA: SERVICIOS BAUTISMALES (PROGRAMA Y LOGÍSTICA)
  // ===========================================================================
  Widget _buildBautismosTab() {
    Query query = FirebaseFirestore.instance.collection('baptismal_services').orderBy('dateTime', descending: true);
    if (_targetWard != 'Todos') {
      query = query.where('ward', isEqualTo: _targetWard);
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: _canManage
          ? FloatingActionButton.extended(
        backgroundColor: _brandBlue,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Programar Bautismo', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: () => _showAddBaptismModal(context),
      )
          : null,
      body: StreamBuilder<QuerySnapshot>(
        stream: query.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState(
              icon: Icons.water_drop_outlined,
              message: 'No hay servicios bautismales registrados recientemente.',
            );
          }

          final docs = snapshot.data!.docs;
          return ListView.builder(
            padding: const EdgeInsets.all(14),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final String id = doc.id;
              final String candidateName = data['candidateName'] ?? 'Hermano(a)';
              final DateTime dateTime = (data['dateTime'] as Timestamp).toDate();
              final String formattedDate = DateFormat("EEEE d 'de' MMMM, h:mm a", 'es_ES').format(dateTime);
              final Map<String, dynamic> checklist = data['checklist'] is Map
                  ? Map<String, dynamic>.from(data['checklist'])
                  : {'pila': false, 'ropa': false, 'toallas': false};

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: Colors.cyan.shade100,
                                child: Icon(Icons.water_drop, color: Colors.cyan.shade800),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    candidateName,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  Text(
                                    formattedDate[0].toUpperCase() + formattedDate.substring(1),
                                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          PopupMenuButton<String>(
                            onSelected: (val) {
                              if (val == 'copy') {
                                _copyBaptismProgram(data);
                              } else if (val == 'delete') {
                                _confirmDelete(context, 'baptismal_services', id, 'el servicio bautismal');
                              }
                            },
                            itemBuilder: (_) => [
                              const PopupMenuItem(
                                value: 'copy',
                                child: Row(children: [Icon(Icons.copy, size: 18), SizedBox(width: 8), Text('Copiar Programa WA')]),
                              ),
                              if (_canManage)
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Row(children: [Icon(Icons.delete, color: Colors.red, size: 18), SizedBox(width: 8), Text('Eliminar', style: TextStyle(color: Colors.red))]),
                                ),
                            ],
                          ),
                        ],
                      ),
                      const Divider(height: 22),

                      // Programa Resumido
                      _buildDetailRow(Icons.person_pin_circle_outlined, 'Dirige', data['conducting'] ?? 'Por definir'),
                      _buildDetailRow(Icons.waves, 'Bautiza', data['baptismBy'] ?? 'Por definir'),
                      _buildDetailRow(Icons.people_outline, 'Testigos', data['witnesses'] ?? 'Por definir'),
                      const SizedBox(height: 10),

                      // Checklist Logístico de Capilla
                      const Text('Checklist Logístico:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          _buildCheckChip('Pila Llena', checklist['pila'] == true, (val) {
                            if (_canManage) {
                              checklist['pila'] = val;
                              FirebaseFirestore.instance.collection('baptismal_services').doc(id).update({'checklist': checklist});
                            }
                          }),
                          const SizedBox(width: 8),
                          _buildCheckChip('Ropa Blanca', checklist['ropa'] == true, (val) {
                            if (_canManage) {
                              checklist['ropa'] = val;
                              FirebaseFirestore.instance.collection('baptismal_services').doc(id).update({'checklist': checklist});
                            }
                          }),
                          const SizedBox(width: 8),
                          _buildCheckChip('Toallas', checklist['toallas'] == true, (val) {
                            if (_canManage) {
                              checklist['toallas'] = val;
                              FirebaseFirestore.instance.collection('baptismal_services').doc(id).update({'checklist': checklist});
                            }
                          }),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // ===========================================================================
  // MODALES Y FORMULARIOS DE REGISTRO
  // ===========================================================================

  void _showAddCoordinationModal(BuildContext context) {
    DateTime selectedDate = DateTime.now();
    final friendsCtrl = TextEditingController();
    final taskCtrl = TextEditingController();
    final respCtrl = TextEditingController();
    List<Map<String, dynamic>> tempCommitments = [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20, right: 20, top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Nueva Minuta de Coordinación Misional', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                const SizedBox(height: 14),

                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.calendar_month, color: _brandBlue),
                  title: Text('Fecha: ${DateFormat('d/MM/yyyy').format(selectedDate)}'),
                  trailing: TextButton(
                    child: const Text('Cambiar'),
                    onPressed: () async {
                      final p = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2025),
                        lastDate: DateTime(2030),
                      );
                      if (p != null) setModalState(() => selectedDate = p);
                    },
                  ),
                ),

                TextField(
                  controller: friendsCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Amigos en Foco (separados por coma)',
                    hintText: 'Juan Pérez, Familia Gómez',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 16),

                const Text('Compromisos Acordados:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: taskCtrl,
                        decoration: const InputDecoration(labelText: 'Tarea', border: OutlineInputBorder(), isDense: true),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: respCtrl,
                        decoration: const InputDecoration(labelText: 'Responsable', border: OutlineInputBorder(), isDense: true),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle, color: _brandBlue),
                      onPressed: () {
                        if (taskCtrl.text.isNotEmpty) {
                          setModalState(() {
                            tempCommitments.add({
                              'task': taskCtrl.text.trim(),
                              'responsible': respCtrl.text.trim().isEmpty ? 'Misioneros' : respCtrl.text.trim(),
                              'done': false,
                            });
                            taskCtrl.clear();
                            respCtrl.clear();
                          });
                        }
                      },
                    ),
                  ],
                ),
                if (tempCommitments.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  ...tempCommitments.map((c) => ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(c['task']),
                    subtitle: Text('Resp: ${c['responsible']}'),
                  )),
                ],
                const SizedBox(height: 20),

                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: _brandBlue, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)),
                  child: const Text('GUARDAR COORDINACIÓN', style: TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: () async {
                    final friends = friendsCtrl.text
                        .split(',')
                        .map((s) => s.trim())
                        .where((s) => s.isNotEmpty)
                        .toList();

                    await FirebaseFirestore.instance.collection('missionary_coordinations').add({
                      'meetingDate': Timestamp.fromDate(selectedDate),
                      'ward': widget.isStakeMode ? kWardsList.first : widget.currentUser.ward,
                      'focusFriends': friends,
                      'commitments': tempCommitments,
                      'createdAt': FieldValue.serverTimestamp(),
                    });

                    if (context.mounted) Navigator.pop(ctx);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAddAppointmentModal(BuildContext context) {
    DateTime selectedDate = DateTime.now();
    TimeOfDay selectedTime = const TimeOfDay(hour: 18, minute: 0);
    final contactCtrl = TextEditingController();
    final placeCtrl = TextEditingController();
    final missionariesCtrl = TextEditingController(text: 'Élderes');
    final phoneCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20, right: 20, top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Publicar Salida / Necesidad de Acompañante', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                const SizedBox(height: 14),

                TextField(
                  controller: contactCtrl,
                  decoration: const InputDecoration(labelText: 'Nombre del Amigo / Familia a Visitar', border: OutlineInputBorder(), isDense: true),
                ),
                const SizedBox(height: 10),

                TextField(
                  controller: placeCtrl,
                  decoration: const InputDecoration(labelText: 'Lugar / Dirección pactada', border: OutlineInputBorder(), isDense: true),
                ),
                const SizedBox(height: 10),

                Row(
                  children: [
                    Expanded(
                      child: ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Fecha', style: TextStyle(fontSize: 12)),
                        subtitle: Text(DateFormat('d/MM/yyyy').format(selectedDate), style: const TextStyle(fontWeight: FontWeight.bold)),
                        onTap: () async {
                          final p = await showDatePicker(context: context, initialDate: selectedDate, firstDate: DateTime.now(), lastDate: DateTime(2030));
                          if (p != null) setModalState(() => selectedDate = p);
                        },
                      ),
                    ),
                    Expanded(
                      child: ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Hora', style: TextStyle(fontSize: 12)),
                        subtitle: Text(selectedTime.format(context), style: const TextStyle(fontWeight: FontWeight.bold)),
                        onTap: () async {
                          final t = await showTimePicker(context: context, initialTime: selectedTime);
                          if (t != null) setModalState(() => selectedTime = t);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                TextField(
                  controller: missionariesCtrl,
                  decoration: const InputDecoration(labelText: 'Misioneros Responsables', border: OutlineInputBorder(), isDense: true),
                ),
                const SizedBox(height: 10),

                TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Teléfono WhatsApp de Misioneros', border: OutlineInputBorder(), isDense: true),
                ),
                const SizedBox(height: 20),

                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: _brandBlue, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)),
                  child: const Text('PUBLICAR SALIDA', style: TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: () async {
                    if (contactCtrl.text.isEmpty) return;

                    final fullDate = DateTime(
                      selectedDate.year, selectedDate.month, selectedDate.day,
                      selectedTime.hour, selectedTime.minute,
                    );

                    await FirebaseFirestore.instance.collection('missionary_appointments').add({
                      'dateTime': Timestamp.fromDate(fullDate),
                      'contactName': contactCtrl.text.trim(),
                      'place': placeCtrl.text.trim(),
                      'missionaries': missionariesCtrl.text.trim(),
                      'phone': phoneCtrl.text.trim(),
                      'ward': widget.isStakeMode ? kWardsList.first : widget.currentUser.ward,
                      'assignedMember': null,
                      'memberUid': null,
                      'createdAt': FieldValue.serverTimestamp(),
                    });

                    if (context.mounted) Navigator.pop(ctx);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAddBaptismModal(BuildContext context) {
    DateTime selectedDate = DateTime.now();
    TimeOfDay selectedTime = const TimeOfDay(hour: 17, minute: 0);

    final candidateCtrl = TextEditingController();
    final conductingCtrl = TextEditingController(text: 'Líder Misional de Barrio');
    final baptismByCtrl = TextEditingController();
    final witnessesCtrl = TextEditingController();
    final firstSpeakerCtrl = TextEditingController();
    final secondSpeakerCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20, right: 20, top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Planificar Servicio Bautismal', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                const SizedBox(height: 14),

                TextField(
                  controller: candidateCtrl,
                  decoration: const InputDecoration(labelText: 'Nombre del Candidato(a)', border: OutlineInputBorder(), isDense: true),
                ),
                const SizedBox(height: 10),

                Row(
                  children: [
                    Expanded(
                      child: ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Fecha', style: TextStyle(fontSize: 12)),
                        subtitle: Text(DateFormat('d/MM/yyyy').format(selectedDate), style: const TextStyle(fontWeight: FontWeight.bold)),
                        onTap: () async {
                          final p = await showDatePicker(context: context, initialDate: selectedDate, firstDate: DateTime.now().subtract(const Duration(days: 30)), lastDate: DateTime(2030));
                          if (p != null) setModalState(() => selectedDate = p);
                        },
                      ),
                    ),
                    Expanded(
                      child: ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Hora', style: TextStyle(fontSize: 12)),
                        subtitle: Text(selectedTime.format(context), style: const TextStyle(fontWeight: FontWeight.bold)),
                        onTap: () async {
                          final t = await showTimePicker(context: context, initialTime: selectedTime);
                          if (t != null) setModalState(() => selectedTime = t);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                TextField(controller: conductingCtrl, decoration: const InputDecoration(labelText: 'Quién Dirige la Reunión', border: OutlineInputBorder(), isDense: true)),
                const SizedBox(height: 10),
                TextField(controller: baptismByCtrl, decoration: const InputDecoration(labelText: 'Quién Efectúa el Bautismo', border: OutlineInputBorder(), isDense: true)),
                const SizedBox(height: 10),
                TextField(controller: witnessesCtrl, decoration: const InputDecoration(labelText: 'Dos Testigos del Sacerdocio', border: OutlineInputBorder(), isDense: true)),
                const SizedBox(height: 10),
                TextField(controller: firstSpeakerCtrl, decoration: const InputDecoration(labelText: 'Discurso de Bautismo', border: OutlineInputBorder(), isDense: true)),
                const SizedBox(height: 10),
                TextField(controller: secondSpeakerCtrl, decoration: const InputDecoration(labelText: 'Discurso del Espíritu Santo', border: OutlineInputBorder(), isDense: true)),
                const SizedBox(height: 20),

                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: _brandBlue, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)),
                  child: const Text('GUARDAR BAUTISMO', style: TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: () async {
                    if (candidateCtrl.text.isEmpty) return;

                    final fullDate = DateTime(
                      selectedDate.year, selectedDate.month, selectedDate.day,
                      selectedTime.hour, selectedTime.minute,
                    );

                    await FirebaseFirestore.instance.collection('baptismal_services').add({
                      'dateTime': Timestamp.fromDate(fullDate),
                      'candidateName': candidateCtrl.text.trim(),
                      'conducting': conductingCtrl.text.trim(),
                      'baptismBy': baptismByCtrl.text.trim(),
                      'witnesses': witnessesCtrl.text.trim(),
                      'firstSpeaker': firstSpeakerCtrl.text.trim(),
                      'secondSpeaker': secondSpeakerCtrl.text.trim(),
                      'ward': widget.isStakeMode ? kWardsList.first : widget.currentUser.ward,
                      'checklist': {'pila': false, 'ropa': false, 'toallas': false},
                      'createdAt': FieldValue.serverTimestamp(),
                    });

                    if (context.mounted) Navigator.pop(ctx);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // MÉTODOS AUXILIARES
  // ===========================================================================

  Widget _buildEmptyState({required IconData icon, required String message}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(message, style: TextStyle(color: Colors.grey.shade600, fontSize: 14), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Text('$label: ', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87)),
          Expanded(child: Text(value, style: TextStyle(fontSize: 12, color: Colors.grey.shade800), overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }

  Widget _buildCheckChip(String title, bool isChecked, Function(bool) onChanged) {
    return InkWell(
      onTap: () => onChanged(!isChecked),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isChecked ? Colors.green.shade50 : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isChecked ? Colors.green.shade700 : Colors.grey.shade300),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(isChecked ? Icons.check_circle : Icons.circle_outlined, size: 14, color: isChecked ? Colors.green.shade700 : Colors.grey),
            const SizedBox(width: 4),
            Text(title, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isChecked ? Colors.green.shade900 : Colors.grey.shade700)),
          ],
        ),
      ),
    );
  }

  void _copyBaptismProgram(Map<String, dynamic> data) {
    final DateTime dt = (data['dateTime'] as Timestamp).toDate();
    final dateStr = DateFormat("EEEE d 'de' MMMM, h:mm a", 'es_ES').format(dt);

    final msg = "*PROGRAMA DE SERVICIO BAUTISMAL*\n\n"
        "🌊 *Candidato(a):* ${data['candidateName']}\n"
        "📅 *Fecha y Hora:* ${dateStr[0].toUpperCase()}${dateStr.substring(1)}\n"
        "🏛️ *Lugar:* Capilla del Barrio ${data['ward']}\n\n"
        "• *Dirige:* ${data['conducting'] ?? 'Por definir'}\n"
        "• *Discurso sobre el Bautismo:* ${data['firstSpeaker'] ?? 'Por definir'}\n"
        "• *Ordenanza Bautismal:* ${data['baptismBy'] ?? 'Por definir'}\n"
        "• *Testigos:* ${data['witnesses'] ?? 'Por definir'}\n"
        "• *Discurso sobre el Don del Espíritu Santo:* ${data['secondSpeaker'] ?? 'Por definir'}\n\n"
        "_«De cierto, de cierto te digo, que el que no naciere de agua y del Espíritu, no puede entrar en el reino de Dios» (Juan 3:5)_";

    Clipboard.setData(ClipboardData(text: msg));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✅ Programa copiado al portapapeles para WhatsApp'), backgroundColor: Colors.green),
    );
  }

  void _launchWhatsApp(String phone, String text) async {
    String clean = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (!clean.startsWith('51') && clean.length == 9) clean = '51$clean';
    final uri = Uri.parse('https://wa.me/$clean?text=${Uri.encodeComponent(text)}');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  void _confirmDelete(BuildContext context, String collection, String docId, String title) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar Eliminación'),
        content: Text('¿Deseas eliminar $title?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              await FirebaseFirestore.instance.collection(collection).doc(docId).delete();
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}