import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:gestor_lds/core/constants/wards_list.dart';
import 'package:gestor_lds/features/auth/models/user_model.dart';

class MinisteringScreen extends StatefulWidget {
  final bool isStakeMode;
  final UserModel currentUser;

  const MinisteringScreen({
    super.key,
    required this.isStakeMode,
    required this.currentUser,
  });

  @override
  State<MinisteringScreen> createState() => _MinisteringScreenState();
}

class _MinisteringScreenState extends State<MinisteringScreen>
    with SingleTickerProviderStateMixin {
  static const Color _brandBlue = Color(0xFF22539A);

  late TabController _tabController;
  late String _targetWard;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _targetWard = widget.isStakeMode ? 'Todos' : widget.currentUser.ward;
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  bool _canManageOrg(String org) {
    if (widget.currentUser.role == UserRole.admin ||
        widget.currentUser.role == UserRole.presidencia_estaca ||
        widget.currentUser.role == UserRole.obispado) {
      return true;
    }

    final callings = widget.currentUser.callings.map((c) => c.toLowerCase()).toList();
    final userOrg = widget.currentUser.organization.toLowerCase();

    if (org == 'elders') {
      return userOrg.contains('élderes') ||
          userOrg.contains('elderes') ||
          callings.any((c) => c.contains('élderes') || c.contains('cuórum') || c.contains('sumo consejo'));
    } else {
      return userOrg.contains('socorro') ||
          callings.any((c) => c.contains('socorro'));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEF2F6),
      appBar: AppBar(
        title: Text(
          widget.isStakeMode ? 'Ministración (Estaca)' : 'Ministración',
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
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(icon: Icon(Icons.man_outlined, size: 22), text: 'CUÓRUM DE ÉLDERES'),
            Tab(icon: Icon(Icons.woman_outlined, size: 22), text: 'SOCIEDAD DE SOCORRO'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _brandBlue,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.group_add),
        label: const Text('Nuevo Compañerismo', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: () {
          final currentOrg = _tabController.index == 0 ? 'elders' : 'relief_society';
          if (_canManageOrg(currentOrg)) {
            _showCompanionshipFormModal(context, org: currentOrg);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('No tienes permisos de presidencia para modificar esta organización.')),
            );
          }
        },
      ),
      body: Column(
        children: [
          // Selector de unidad (Modo Estaca)
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

          // Buscador de ministradores o familias
          Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            color: Colors.white,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar por ministro, familia o necesidad...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.grey),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
                    : null,
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 15),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
            ),
          ),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildCompanionshipsList('elders'),
                _buildCompanionshipsList('relief_society'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // LISTA Y FILTRADO DE COMPAÑERISMOS
  // ===========================================================================
  Widget _buildCompanionshipsList(String org) {
    Query query = FirebaseFirestore.instance
        .collection('ministering_companionships')
        .where('organization', isEqualTo: org);

    if (_targetWard != 'Todos') {
      query = query.where('ward', isEqualTo: _targetWard);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
        }

        final docs = snapshot.data?.docs ?? [];
        final companionships = docs.map((d) {
          final data = d.data() as Map<String, dynamic>;
          data['id'] = d.id;
          return data;
        }).where((comp) {
          if (_searchQuery.isEmpty) return true;
          final m1 = (comp['minister1Name'] ?? '').toString().toLowerCase();
          final m2 = (comp['minister2Name'] ?? '').toString().toLowerCase();
          final notes = (comp['notes'] ?? '').toString().toLowerCase();
          final families = (comp['families'] as List<dynamic>? ?? [])
              .map((f) => (f['name'] ?? '').toString().toLowerCase())
              .join(' ');

          return m1.contains(_searchQuery) ||
              m2.contains(_searchQuery) ||
              notes.contains(_searchQuery) ||
              families.contains(_searchQuery);
        }).toList();

        if (companionships.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.handshake_outlined, size: 70, color: Colors.grey.shade300),
                const SizedBox(height: 12),
                Text(
                  _searchQuery.isNotEmpty
                      ? 'No hay resultados para "$_searchQuery"'
                      : 'No hay compañerismos registrados en esta organización.',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          itemCount: companionships.length,
          itemBuilder: (context, index) {
            return _buildCompanionshipCard(companionships[index], org);
          },
        );
      },
    );
  }

  // ===========================================================================
  // TARJETA DE COMPAÑERISMO
  // ===========================================================================
  Widget _buildCompanionshipCard(Map<String, dynamic> comp, String org) {
    final String id = comp['id'];
    final String m1 = comp['minister1Name'] ?? 'Sin asignar';
    final String? p1 = comp['minister1Phone'];
    final String m2 = comp['minister2Name'] ?? 'Sin asignar';
    final String? p2 = comp['minister2Phone'];
    final String ward = comp['ward'] ?? widget.currentUser.ward;
    final String? district = comp['district'];
    final bool hasAlert = comp['hasAlert'] == true;
    final String? alertMessage = comp['alertMessage'];
    final List<dynamic> families = comp['families'] ?? [];

    final bool canEdit = _canManageOrg(org);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: hasAlert
            ? BorderSide(color: Colors.red.shade400, width: 1.5)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabecera: Compañeros y opciones
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: (org == 'elders' ? Colors.blue : Colors.purple).shade100,
                  child: Icon(
                    org == 'elders' ? Icons.people_alt : Icons.diversity_1,
                    color: (org == 'elders' ? Colors.blue : Colors.purple).shade800,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$m1 & $m2',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Barrio $ward${district != null && district.isNotEmpty ? ' • $district' : ''}',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                if (p1 != null && p1.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.message, color: Color(0xFF25D366), size: 20),
                    tooltip: 'WhatsApp $m1',
                    onPressed: () => _launchWhatsApp(p1),
                  ),
                if (p2 != null && p2.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.message, color: Color(0xFF25D366), size: 20),
                    tooltip: 'WhatsApp $m2',
                    onPressed: () => _launchWhatsApp(p2),
                  ),
                if (canEdit)
                  PopupMenuButton<String>(
                    onSelected: (val) {
                      if (val == 'edit') {
                        _showCompanionshipFormModal(context, org: org, compToEdit: comp);
                      } else if (val == 'alert') {
                        _showAlertModal(context, id, hasAlert, alertMessage);
                      } else if (val == 'delete') {
                        _confirmDelete(context, id, '$m1 y $m2');
                      }
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(children: [Icon(Icons.edit, size: 18), SizedBox(width: 8), Text('Editar Compañerismo')]),
                      ),
                      PopupMenuItem(
                        value: 'alert',
                        child: Row(
                          children: [
                            Icon(Icons.warning_amber_rounded, size: 18, color: hasAlert ? Colors.green : Colors.red),
                            const SizedBox(width: 8),
                            Text(hasAlert ? 'Resolver Foco de Atención' : 'Reportar Foco de Atención'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(children: [Icon(Icons.delete, color: Colors.red, size: 18), SizedBox(width: 8), Text('Eliminar', style: TextStyle(color: Colors.red))]),
                      ),
                    ],
                  ),
              ],
            ),

            // Alerta Pastoral / Foco de Atención
            if (hasAlert && alertMessage != null && alertMessage.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.red.shade800, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        alertMessage,
                        style: TextStyle(color: Colors.red.shade900, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const Divider(height: 22),

            // Lista de Familias / Hermanos asignados
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Familias y Miembros Asignados (${families.length}):',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                if (canEdit)
                  TextButton.icon(
                    style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                    icon: const Icon(Icons.add, size: 16, color: _brandBlue),
                    label: const Text('Añadir Familia', style: TextStyle(fontSize: 12, color: _brandBlue)),
                    onPressed: () => _showAddFamilyModal(context, id, families),
                  ),
              ],
            ),
            const SizedBox(height: 6),

            if (families.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('Sin asignaciones asignadas por la presidencia.', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic, fontSize: 12)),
              )
            else
              ...families.asMap().entries.map((entry) {
                final int fIndex = entry.key;
                final Map<String, dynamic> f = Map<String, dynamic>.from(entry.value);
                final String fName = f['name'] ?? 'Familia';
                final String? fPhone = f['phone'];
                final String? fNeeds = f['needs'];
                final Timestamp? lastContact = f['lastContact'];

                final String lastContactStr = lastContact != null
                    ? DateFormat('d/MM/yyyy').format(lastContact.toDate())
                    : 'Sin registro';

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(fName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            const SizedBox(height: 2),
                            Text(
                              'Último contacto: $lastContactStr${fNeeds != null && fNeeds.isNotEmpty ? " • $fNeeds" : ""}',
                              style: TextStyle(color: Colors.grey.shade700, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      if (fPhone != null && fPhone.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.message, color: Color(0xFF25D366), size: 18),
                          tooltip: 'Escribir a $fName',
                          onPressed: () => _launchWhatsApp(fPhone),
                        ),
                      IconButton(
                        icon: const Icon(Icons.checklist_rounded, color: _brandBlue, size: 20),
                        tooltip: 'Registrar Visita/Contacto',
                        onPressed: () => _showLogVisitModal(context, id, families, fIndex, fName),
                      ),
                      if (canEdit)
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.grey, size: 18),
                          tooltip: 'Quitar familia',
                          onPressed: () {
                            families.removeAt(fIndex);
                            FirebaseFirestore.instance
                                .collection('ministering_companionships')
                                .doc(id)
                                .update({'families': families});
                          },
                        ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // MODALES: COMPAÑERISMOS, FAMILIAS Y REGISTRO DE VISITAS
  // ===========================================================================

  void _showCompanionshipFormModal(BuildContext context, {required String org, Map<String, dynamic>? compToEdit}) {
    final bool isEditing = compToEdit != null;
    final m1Ctrl = TextEditingController(text: isEditing ? compToEdit['minister1Name'] : '');
    final p1Ctrl = TextEditingController(text: isEditing ? compToEdit['minister1Phone'] : '');
    final m2Ctrl = TextEditingController(text: isEditing ? compToEdit['minister2Name'] : '');
    final p2Ctrl = TextEditingController(text: isEditing ? compToEdit['minister2Phone'] : '');
    final districtCtrl = TextEditingController(text: isEditing ? compToEdit['district'] : '');

    String selectedWard = isEditing
        ? (compToEdit['ward'] ?? widget.currentUser.ward)
        : (widget.isStakeMode ? kWardsList.first : widget.currentUser.ward);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            left: 20, right: 20, top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isEditing ? 'Editar Compañerismo' : 'Nuevo Compañerismo',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
                const SizedBox(height: 14),

                if (widget.isStakeMode) ...[
                  DropdownButtonFormField<String>(
                    value: selectedWard,
                    decoration: const InputDecoration(labelText: 'Barrio', border: OutlineInputBorder(), isDense: true),
                    items: kWardsList.map((w) => DropdownMenuItem(value: w, child: Text(w))).toList(),
                    onChanged: (val) => setModalState(() => selectedWard = val!),
                  ),
                  const SizedBox(height: 12),
                ],

                TextField(
                  controller: districtCtrl,
                  decoration: const InputDecoration(labelText: 'Distrito / Zona (Opcional)', border: OutlineInputBorder(), isDense: true),
                ),
                const SizedBox(height: 12),

                // Ministrador 1
                TextField(
                  controller: m1Ctrl,
                  decoration: const InputDecoration(labelText: 'Ministrador(a) 1 (Nombre Completo)', border: OutlineInputBorder(), isDense: true, prefixIcon: Icon(Icons.person)),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: p1Ctrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'WhatsApp Ministrador(a) 1', border: OutlineInputBorder(), isDense: true, prefixIcon: Icon(Icons.phone)),
                ),
                const SizedBox(height: 16),

                // Ministrador 2
                TextField(
                  controller: m2Ctrl,
                  decoration: const InputDecoration(labelText: 'Ministrador(a) 2 (Nombre Completo)', border: OutlineInputBorder(), isDense: true, prefixIcon: Icon(Icons.person_outline)),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: p2Ctrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'WhatsApp Ministrador(a) 2', border: OutlineInputBorder(), isDense: true, prefixIcon: Icon(Icons.phone)),
                ),
                const SizedBox(height: 22),

                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _brandBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(isEditing ? 'GUARDAR CAMBIOS' : 'CREAR COMPAÑERISMO', style: const TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: () async {
                    if (m1Ctrl.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ingresa al menos el nombre del primer ministro')));
                      return;
                    }

                    final data = {
                      'organization': org,
                      'ward': selectedWard,
                      'district': districtCtrl.text.trim(),
                      'minister1Name': m1Ctrl.text.trim(),
                      'minister1Phone': p1Ctrl.text.trim(),
                      'minister2Name': m2Ctrl.text.trim(),
                      'minister2Phone': p2Ctrl.text.trim(),
                      'updatedAt': FieldValue.serverTimestamp(),
                    };

                    if (isEditing) {
                      await FirebaseFirestore.instance.collection('ministering_companionships').doc(compToEdit['id']).update(data);
                    } else {
                      data['families'] = [];
                      data['hasAlert'] = false;
                      data['alertMessage'] = '';
                      data['createdAt'] = FieldValue.serverTimestamp();
                      await FirebaseFirestore.instance.collection('ministering_companionships').add(data);
                    }

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

  void _showAddFamilyModal(BuildContext context, String compId, List<dynamic> currentFamilies) {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final notesCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20, right: 20, top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Asignar Familia / Miembro', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              const SizedBox(height: 14),

              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Nombre de la Familia o Miembro', border: OutlineInputBorder(), isDense: true),
              ),
              const SizedBox(height: 10),

              TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Teléfono / WhatsApp de contacto', border: OutlineInputBorder(), isDense: true),
              ),
              const SizedBox(height: 10),

              TextField(
                controller: notesCtrl,
                decoration: const InputDecoration(labelText: 'Dirección o referencia rápida', border: OutlineInputBorder(), isDense: true),
              ),
              const SizedBox(height: 20),

              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: _brandBlue, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)),
                child: const Text('ASIGNAR', style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () async {
                  if (nameCtrl.text.trim().isEmpty) return;

                  currentFamilies.add({
                    'name': nameCtrl.text.trim(),
                    'phone': phoneCtrl.text.trim(),
                    'needs': notesCtrl.text.trim(),
                    'lastContact': null,
                  });

                  await FirebaseFirestore.instance
                      .collection('ministering_companionships')
                      .doc(compId)
                      .update({'families': currentFamilies});

                  if (context.mounted) Navigator.pop(ctx);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogVisitModal(BuildContext context, String compId, List<dynamic> families, int index, String familyName) {
    DateTime visitDate = DateTime.now();
    final noteCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20, right: 20, top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Registrar Contacto: $familyName', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                const SizedBox(height: 14),

                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.event, color: _brandBlue),
                  title: Text('Fecha de Visita: ${DateFormat('d/MM/yyyy').format(visitDate)}'),
                  trailing: TextButton(
                    child: const Text('Cambiar'),
                    onPressed: () async {
                      final p = await showDatePicker(
                        context: context,
                        initialDate: visitDate,
                        firstDate: DateTime(2025),
                        lastDate: DateTime(2030),
                      );
                      if (p != null) setModalState(() => visitDate = p);
                    },
                  ),
                ),
                const SizedBox(height: 8),

                TextField(
                  controller: noteCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Nota breve (¿Cómo están? ¿Tienen alguna necesidad?)',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 20),

                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: _brandBlue, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)),
                  child: const Text('REGISTRAR CONTACTO', style: TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: () async {
                    families[index]['lastContact'] = Timestamp.fromDate(visitDate);
                    if (noteCtrl.text.trim().isNotEmpty) {
                      families[index]['needs'] = noteCtrl.text.trim();
                    }

                    await FirebaseFirestore.instance
                        .collection('ministering_companionships')
                        .doc(compId)
                        .update({'families': families});

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

  void _showAlertModal(BuildContext context, String compId, bool currentAlert, String? currentMessage) {
    final alertCtrl = TextEditingController(text: currentMessage ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(currentAlert ? 'Foco de Atención Activo' : 'Reportar Foco de Atención'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Las alertas pastorales se resaltan para que el Obispado y la Presidencia puedan brindar auxilio o seguimiento oportuno.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: alertCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Motivo de atención (ej. Enfermó gravemente, duelo familiar, necesidad temporal)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          if (currentAlert)
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.green),
              onPressed: () async {
                await FirebaseFirestore.instance.collection('ministering_companionships').doc(compId).update({
                  'hasAlert': false,
                  'alertMessage': '',
                });
                if (context.mounted) Navigator.pop(ctx);
              },
              child: const Text('Marcar como Resuelto'),
            ),
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _brandBlue, foregroundColor: Colors.white),
            onPressed: () async {
              await FirebaseFirestore.instance.collection('ministering_companionships').doc(compId).update({
                'hasAlert': true,
                'alertMessage': alertCtrl.text.trim(),
              });
              if (context.mounted) Navigator.pop(ctx);
            },
            child: const Text('Guardar Alerta'),
          ),
        ],
      ),
    );
  }

  void _launchWhatsApp(String phone) async {
    String clean = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (!clean.startsWith('51') && clean.length == 9) clean = '51$clean';
    final uri = Uri.parse('https://wa.me/$clean');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  void _confirmDelete(BuildContext context, String compId, String title) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar Compañerismo'),
        content: Text('¿Deseas eliminar el compañerismo de $title?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              await FirebaseFirestore.instance.collection('ministering_companionships').doc(compId).delete();
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}