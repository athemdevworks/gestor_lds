import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:gestor_lds/features/auth/models/user_model.dart';
import 'package:gestor_lds/core/constants/wards_list.dart';
import 'package:gestor_lds/core/constants/organizations_list.dart';

class FamilyHistorySosScreen extends StatefulWidget {
  // 🚀 RECIBIMOS LOS MANDOS DIRECTOS DESDE EL HUB
  final bool isStakeMode;
  final UserModel currentUser;

  const FamilyHistorySosScreen({
    super.key,
    required this.isStakeMode,
    required this.currentUser,
  });

  @override
  State<FamilyHistorySosScreen> createState() => _FamilyHistorySosScreenState();
}

class _FamilyHistorySosScreenState extends State<FamilyHistorySosScreen> {
  static const Color _brandBlue = Color(0xFF22539A);

  // Filtros de visualización del panel de control
  String _barrioFiltro = 'Todos';
  String _estadoFiltro = 'Pendiente';

  @override
  void initState() {
    super.initState();
    // 🚀 INICIALIZACIÓN LOGÍSTICA EN VIVO SEGÚN EL SOMBRERO SELECCIONADO
    _barrioFiltro = widget.isStakeMode ? 'Todos' : widget.currentUser.ward;
  }

  @override
  Widget build(BuildContext context) {
    // Vinculamos el comportamiento de administración al interruptor superior de la app
    final bool esAdminEstaca = widget.isStakeMode;

    // =========================================================================
    // 🛡️ DEFENSA ESTRICTA: Filtros Cruzados (Barrio y Estaca)
    // =========================================================================

    // Convertimos el rol a texto puro para evitar el choque con los Enums
    final String miRol = widget.currentUser.role.toString();

    // 1. Escáner para Líderes de Barrio (Escanea TODA la matriz, no solo el 1ro)
    final bool sirveEnOrgClaveBarrio = widget.currentUser.callingOrganizations?.contains('Cuórum de Élderes') == true ||
        widget.currentUser.callingOrganizations?.contains('Sociedad de Socorro') == true ||
        widget.currentUser.callingOrganizations?.contains('Templo e Historia Familiar') == true;

    final bool esLiderBarrioAutorizado = (miRol == 'lider_barrio' || miRol == 'UserRole.lider_barrio') && sirveEnOrgClaveBarrio;

    // 2. Escáner para Líderes de Estaca (El Nuevo Candado)
    final bool sirveEnOrgClaveEstaca = widget.currentUser.callingOrganizations?.contains('Sumo consejo') == true ||
        widget.currentUser.callingOrganizations?.contains('Sumo Consejo') == true ||
        widget.currentUser.callingOrganizations?.contains('Templo e historia familiar de estaca') == true ||
        widget.currentUser.callingOrganizations?.contains('Templo e Historia Familiar de estaca') == true;

    final bool esLiderEstacaAutorizado = (miRol == 'lider_estaca' || miRol == 'UserRole.lider_estaca') && sirveEnOrgClaveEstaca;

    // 3. Pases VIP Absolutos (Capitanes Generales)
    final bool tienePaseVip = miRol == 'admin' || miRol == 'UserRole.admin' ||
        miRol == 'presidencia_estaca' || miRol == 'UserRole.presidencia_estaca' ||
        miRol == 'obispado' || miRol == 'UserRole.obispado';

    // 4. Permiso Total Final
    final bool tienePermisoGestion = tienePaseVip || esLiderEstacaAutorizado || esLiderBarrioAutorizado;
    // =========================================================================

    return DefaultTabController(
      length: tienePermisoGestion ? 2 : 1,
      child: Scaffold(
        backgroundColor: const Color(0xFFEEF2F6),
        appBar: AppBar(
          title: const Text('Bandeja SOS de Historia Familiar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          backgroundColor: _brandBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          bottom: TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            tabs: [
              const Tab(icon: Icon(Icons.assignment_late_outlined), text: 'Mis Tareas Asignadas'),
              if (tienePermisoGestion) const Tab(icon: Icon(Icons.analytics_outlined), text: 'Control de Casos'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildMisTareasTab(),
            if (tienePermisoGestion) _buildControlCasosTab(esAdminEstaca),
          ],
        ),
        floatingActionButton: tienePermisoGestion
            ? FloatingActionButton.extended(
          backgroundColor: _brandBlue,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add_moderator),
          label: const Text('Asignar SOS', style: TextStyle(fontWeight: FontWeight.bold)),
          onPressed: () => _showCreateAssignmentDialog(context, esAdminEstaca),
        )
            : null,
      ),
    );
  }

  // =========================================================================
  // 📋 TAB 1: CASOS ASIGNADOS A MÍ PARA QUE YO RESUELVA (Para Todos)
  // =========================================================================
  Widget _buildMisTareasTab() {
    final String currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('family_history_sos')
          .where('consultantId', isEqualTo: currentUid)
          .where('status', isEqualTo: 'Pendiente')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.assignment_turned_in_outlined, size: 80, color: Colors.blue.shade200),
                const SizedBox(height: 12),
                const Text('No tienes asignaciones de rescate pendientes.', style: TextStyle(color: Colors.black54, fontSize: 14, fontStyle: FontStyle.italic)),
              ],
            ),
          );
        }

        final tareas = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: tareas.length,
          itemBuilder: (context, index) {
            var doc = tareas[index];
            var data = doc.data() as Map<String, dynamic>;

            return Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(data['memberName'] ?? 'Miembro', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: Colors.amber.shade100, borderRadius: BorderRadius.circular(8)),
                          child: Text(data['memberWard'] ?? '', style: TextStyle(color: Colors.amber.shade900, fontSize: 11, fontWeight: FontWeight.bold)),
                        )
                      ],
                    ),
                    const Divider(height: 20),
                    const Text('Necesidad reportada:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54)),
                    const SizedBox(height: 4),
                    Text(data['note'] ?? '', style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.3)),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Asignado por: ${data['assignedByName']}', style: const TextStyle(fontSize: 11, color: Colors.grey, fontStyle: FontStyle.italic)),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.check_circle_outline, size: 18),
                          label: const Text('Marcar Resuelto', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                          onPressed: () => _resolverCaso(doc.id),
                        )
                      ],
                    )
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // =========================================================================
  // 📊 TAB 2: PANEL GLOBAL DE CONTROL DE CASOS (SÓLO LÍDERES AUTORIZADOS)
  // =========================================================================
  Widget _buildControlCasosTab(bool esAdminEstaca) {
    Query querySOS = FirebaseFirestore.instance.collection('family_history_sos').where('status', isEqualTo: _estadoFiltro);

    if (_barrioFiltro != 'Todos') {
      querySOS = querySOS.where('memberWard', isEqualTo: _barrioFiltro);
    }

    return Column(
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  // 🚀 CONTROL ANTi-CRASH: Evita desajustes al cambiar el interruptor principal
                  value: esAdminEstaca ? _barrioFiltro : widget.currentUser.ward,
                  decoration: InputDecoration(labelText: 'Barrio', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), isDense: true, fillColor: esAdminEstaca ? Colors.white : Colors.grey.shade100, filled: !esAdminEstaca),
                  items: esAdminEstaca
                      ? ['Todos', ...kWardsList].map((b) => DropdownMenuItem(value: b, child: Text(b, style: const TextStyle(fontSize: 13)))).toList()
                      : [widget.currentUser.ward].map((b) => DropdownMenuItem(value: b, child: Text(b, style: const TextStyle(fontSize: 13)))).toList(),
                  onChanged: esAdminEstaca ? (val) => setState(() => _barrioFiltro = val!) : null,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _estadoFiltro,
                  decoration: InputDecoration(labelText: 'Estado', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), isDense: true),
                  items: ['Pendiente', 'Resuelto'].map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 13)))).toList(),
                  onChanged: (val) => setState(() => _estadoFiltro = val!),
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: querySOS.snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(child: Text('No hay registros SOS con estos filtros.', style: TextStyle(color: Colors.grey.shade600, fontStyle: FontStyle.italic)));
              }

              final listaCasos = snapshot.data!.docs;

              return ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: listaCasos.length,
                itemBuilder: (context, index) {
                  var doc = listaCasos[index];
                  var data = doc.data() as Map<String, dynamic>;
                  bool isPending = data['status'] == 'Pendiente';

                  return Card(
                    color: Colors.white,
                    elevation: 1,
                    margin: const EdgeInsets.only(bottom: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isPending ? Colors.red.shade50 : Colors.green.shade50,
                        child: Icon(isPending ? Icons.gpp_maybe : Icons.check_circle, color: isPending ? Colors.red : Colors.green),
                      ),
                      title: Text(data['memberName'] ?? 'Miembro', style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('Consultor: ${data['consultantName']}\nNota: ${data['note']}', style: const TextStyle(fontSize: 12)),
                      trailing: isPending
                          ? IconButton(
                        icon: const Icon(Icons.check_circle_outline, color: Colors.green),
                        tooltip: 'Resolver Caso',
                        onPressed: () => _resolverCaso(doc.id),
                      )
                          : Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                        child: const Text('OK', style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                      isThreeLine: true,
                    ),
                  );
                },
              );
            },
          ),
        )
      ],
    );
  }

  Future<void> _resolverCaso(String docId) async {
    await FirebaseFirestore.instance.collection('family_history_sos').doc(docId).update({
      'status': 'Resuelto',
      'resolvedAt': FieldValue.serverTimestamp(),
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ ¡Caso SOS marcado como Resuelto con éxito!'), backgroundColor: Colors.green));
    }
  }

  // =========================================================================
  // 🚀 DIÁLOGO DE ASIGNACIÓN (CON AUTOSUGERENCIA DEL UNIVERSO DEL BARRIO)
  // =========================================================================
  void _showCreateAssignmentDialog(BuildContext context, bool esAdminEstaca) {
    // 🚀 ESCUDO ANTICRASH: Si el filtro superior dice 'Todos', seleccionamos el primer barrio disponible por defecto
    String selectedWard = esAdminEstaca
        ? (_barrioFiltro == 'Todos' ? kWardsList.first : _barrioFiltro)
        : widget.currentUser.ward;

    String? selectedMemberId;
    String? selectedMemberName;
    String? selectedConsultantId;
    String? selectedConsultantName;

    final noteController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.add_moderator, color: _brandBlue),
            const SizedBox(width: 8),
            const Text('Asignar Caso SOS', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {

            var fetchUsersFuture = FirebaseFirestore.instance
                .collection('users')
                .where('ward', isEqualTo: selectedWard)
                .get();

            return SingleChildScrollView(
              child: SizedBox(
                width: 450,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DropdownButtonFormField<String>(
                      value: selectedWard,
                      decoration: const InputDecoration(labelText: 'Barrio de Atención', border: OutlineInputBorder(), isDense: true),
                      items: esAdminEstaca
                          ? kWardsList.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList()
                          : [selectedWard].map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
                      onChanged: esAdminEstaca ? (val) {
                        setModalState(() {
                          selectedWard = val!;
                          selectedMemberId = null;
                          selectedConsultantId = null;
                        });
                      } : null,
                    ),
                    const SizedBox(height: 16),

                    FutureBuilder<QuerySnapshot>(
                      future: fetchUsersFuture,
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return const Center(child: LinearProgressIndicator());

                        var users = snapshot.data!.docs;

                        return Column(
                          children: [
                            Autocomplete<QueryDocumentSnapshot>(
                              displayStringForOption: (option) {
                                var d = option.data() as Map<String, dynamic>;
                                return '${d['lastName']}, ${d['firstName']}';
                              },
                              optionsBuilder: (TextEditingValue textEditingValue) {
                                if (textEditingValue.text.isEmpty) {
                                  return const Iterable<QueryDocumentSnapshot>.empty();
                                }
                                final String query = textEditingValue.text.toLowerCase();
                                return users.where((u) {
                                  var d = u.data() as Map<String, dynamic>;
                                  String fullName = '${d['firstName']} ${d['lastName']}'.toLowerCase();
                                  String reverseName = '${d['lastName']}, ${d['firstName']}'.toLowerCase();
                                  return fullName.contains(query) || reverseName.contains(query);
                                });
                              },
                              onSelected: (QueryDocumentSnapshot selection) {
                                var d = selection.data() as Map<String, dynamic>;
                                selectedMemberId = selection.id;
                                selectedMemberName = '${d['firstName']} ${d['lastName']}';
                              },
                              fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                                return TextField(
                                  controller: controller,
                                  focusNode: focusNode,
                                  decoration: const InputDecoration(
                                    labelText: 'Miembro que necesita Ayuda (Buscar)',
                                    hintText: 'Ej: Perez, Juan...',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.search),
                                    isDense: true,
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 16),

                            Autocomplete<QueryDocumentSnapshot>(
                              displayStringForOption: (option) {
                                var d = option.data() as Map<String, dynamic>;
                                return '${d['lastName']}, ${d['firstName']}';
                              },
                              optionsBuilder: (TextEditingValue textEditingValue) {
                                if (textEditingValue.text.isEmpty) {
                                  return const Iterable<QueryDocumentSnapshot>.empty();
                                }
                                final String query = textEditingValue.text.toLowerCase();
                                return users.where((u) {
                                  var d = u.data() as Map<String, dynamic>;
                                  String fullName = '${d['firstName']} ${d['lastName']}'.toLowerCase();
                                  String reverseName = '${d['lastName']}, ${d['firstName']}'.toLowerCase();
                                  return fullName.contains(query) || reverseName.contains(query);
                                });
                              },
                              onSelected: (QueryDocumentSnapshot selection) {
                                var d = selection.data() as Map<String, dynamic>;
                                selectedConsultantId = selection.id;
                                selectedConsultantName = '${d['firstName']} ${d['lastName']}';
                              },
                              fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                                return TextField(
                                  controller: controller,
                                  focusNode: focusNode,
                                  decoration: const InputDecoration(
                                    labelText: 'Consultor Responsable (Buscar)',
                                    hintText: 'Ej: Mendoza, Robert...',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.person_search),
                                    isDense: true,
                                  ),
                                );
                              },
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 16),

                    TextField(
                      controller: noteController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: '¿Cuál es la necesidad?',
                        border: OutlineInputBorder(),
                        hintText: 'Detalla el problema (Ej: Olvidó su clave o árbol bloqueado)...',
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _brandBlue, foregroundColor: Colors.white),
            onPressed: () async {
              if (selectedMemberId == null || selectedConsultantId == null) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('⚠️ Por favor, busca y selecciona a las personas de la lista de sugerencias.'),
                  backgroundColor: Colors.orange,
                ));
                return;
              }

              if (noteController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('⚠️ Por favor, escribe el detalle de la necesidad.'),
                  backgroundColor: Colors.orange,
                ));
                return;
              }

              await FirebaseFirestore.instance.collection('family_history_sos').add({
                'memberId': selectedMemberId,
                'memberName': selectedMemberName,
                'memberWard': selectedWard,
                'consultantId': selectedConsultantId,
                'consultantName': selectedConsultantName,
                'note': noteController.text.trim(),
                'status': 'Pendiente',
                'createdAt': FieldValue.serverTimestamp(),
                'assignedById': FirebaseAuth.instance.currentUser?.uid,
                'assignedByName': '${widget.currentUser.firstName} ${widget.currentUser.lastName}',
              });

              if (context.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('🚀 ¡Ticket SOS asignado y registrado con éxito!'), backgroundColor: Colors.green));
              }
            },
            child: const Text('Crear Asignación'),
          ),
        ],
      ),
    );
  }
}