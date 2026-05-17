import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gestor_lds/core/constants/wards_list.dart';
import 'package:gestor_lds/core/constants/organizations_list.dart';
import 'package:gestor_lds/features/auth/models/user_model.dart';

class FamilyHistoryScreen extends StatefulWidget {
  final bool isStakeMode;
  final UserModel currentUser;

  const FamilyHistoryScreen({
    super.key,
    required this.isStakeMode,
    required this.currentUser
  });

  @override
  State<FamilyHistoryScreen> createState() => _FamilyHistoryScreenState();
}

class _FamilyHistoryScreenState extends State<FamilyHistoryScreen> {
  static const Color _brandBlue = Color(0xFF22539A);

  // --- VARIABLES DE FILTROS ---
  String _barrioSeleccionado = 'Todos';
  String _mesSeleccionado = DateTime.now().month.toString().padLeft(2, '0');
  String _searchQuery = '';
  String _filtroProgreso = 'Todos';
  String _filtroOrganizacion = 'Todos';

  final int _anioActual = DateTime.now().year;
  final List<String> _meses = ['01', '02', '03', '04', '05', '06', '07', '08', '09', '10', '11', '12'];

  final Map<String, String> _nombresMeses = {
    '01': 'Enero', '02': 'Febrero', '03': 'Marzo', '04': 'Abril',
    '05': 'Mayo', '06': 'Junio', '07': 'Julio', '08': 'Agosto',
    '09': 'Septiembre', '10': 'Octubre', '11': 'Noviembre', '12': 'Diciembre'
  };

  final List<String> _opcionesProgreso = ['Todos', 'Sin Iniciar', 'En Progreso', 'Listos'];
  final List<String> _opcionesDemograficas = ['Todos', 'JAS', 'Hombres', 'Mujeres', 'Jóvenes', ...kOrganizationsList];

  late final List<String> _barriosSelectable;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _barriosSelectable = ['Todos', ...kWardsList];
    // 🚀 CONTROL DE DROPDOWN ANTICRASH: Sincroniza el inicio según el sombrero activo
    if (widget.isStakeMode) {
      _barrioSeleccionado = kWardsList.first; // O puedes dejarlo en widget.currentUser.ward si prefieres
    } else {
      _barrioSeleccionado = widget.currentUser.ward;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _mostrarPanelFiltros() {
    final bool esAdminEstaca = widget.isStakeMode;

    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) {
          return StatefulBuilder(
              builder: (BuildContext context, StateSetter setModalState) {
                return Container(
                  decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
                  padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 20, top: 24, left: 20, right: 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Filtros Avanzados', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context))
                        ],
                      ),
                      const Divider(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              // 🚀 ESCUDO ABSOLUTO CONTRA EL CRASH: Asegura que el valor coincida exactamente con las opciones del menú
                              value: esAdminEstaca ? _barrioSeleccionado : widget.currentUser.ward,
                              decoration: InputDecoration(
                                labelText: 'Barrio',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                isDense: true,
                                filled: !esAdminEstaca,
                                fillColor: esAdminEstaca ? Colors.white : Colors.grey.shade100,
                              ),
                              items: esAdminEstaca
                                  ? _barriosSelectable.map((b) => DropdownMenuItem(value: b, child: Text(b, style: const TextStyle(fontSize: 14)))).toList()
                                  : [widget.currentUser.ward].map((b) => DropdownMenuItem(value: b, child: Text(b, style: const TextStyle(fontSize: 14)))).toList(),
                              onChanged: esAdminEstaca ? (val) {
                                setModalState(() => _barrioSeleccionado = val!);
                                setState(() {});
                              } : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _mesSeleccionado,
                              decoration: InputDecoration(labelText: 'Mes', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), isDense: true),
                              items: _meses.map((m) => DropdownMenuItem(value: m, child: Text(_nombresMeses[m]!, style: const TextStyle(fontSize: 14)))).toList(),
                              onChanged: (val) {
                                setModalState(() => _mesSeleccionado = val!);
                                setState(() {});
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _filtroOrganizacion,
                        decoration: InputDecoration(labelText: 'Organización', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), isDense: true),
                        items: _opcionesDemograficas.map((d) => DropdownMenuItem(value: d, child: Text(d, style: const TextStyle(fontSize: 14)))).toList(),
                        onChanged: (val) {
                          setModalState(() => _filtroOrganizacion = val!);
                          setState(() {});
                        },
                      ),
                      const SizedBox(height: 16),
                      const Text('Estado de las Metas:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black54)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8.0,
                        runSpacing: 8.0,
                        children: _opcionesProgreso.map((estado) {
                          return ChoiceChip(
                            label: Text(estado, style: TextStyle(color: _filtroProgreso == estado ? Colors.white : Colors.black87, fontWeight: FontWeight.bold)),
                            selectedColor: _brandBlue,
                            backgroundColor: Colors.grey.shade200,
                            selected: _filtroProgreso == estado,
                            onSelected: (selected) {
                              if (selected) {
                                setModalState(() => _filtroProgreso = estado);
                                setState(() {});
                              }
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: _brandBlue, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        onPressed: () => Navigator.pop(context),
                        child: const Text('APLICAR FILTROS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ],
                  ),
                );
              }
          );
        }
    );
  }

  @override
  Widget build(BuildContext context) {
    Query query = FirebaseFirestore.instance.collection('users');
    if (_barrioSeleccionado != 'Todos') {
      query = query.where('ward', isEqualTo: _barrioSeleccionado);
    }

    final String keyRegistroAnio = 'registro_$_anioActual';

    return Scaffold(
      backgroundColor: const Color(0xFFEEF2F6),
      appBar: AppBar(
        title: const Text('Registrar Logros', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: _brandBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [IconButton(icon: const Icon(Icons.filter_list_alt), tooltip: 'Filtros', onPressed: _mostrarPanelFiltros)],
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Buscar por nombre o apellido...',
                    prefixIcon: const Icon(Icons.search, color: _brandBlue),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(icon: const Icon(Icons.clear), onPressed: () { _searchController.clear(); setState(() => _searchQuery = ''); })
                        : null,
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 15),
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFiltroTag(Icons.location_city, _barrioSeleccionado),
                      _buildFiltroTag(Icons.calendar_month, 'Corte a: ${_nombresMeses[_mesSeleccionado]}'),
                      if (_filtroOrganizacion != 'Todos') _buildFiltroTag(Icons.group, _filtroOrganizacion),
                      if (_filtroProgreso != 'Todos') _buildFiltroTag(Icons.trending_up, _filtroProgreso),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: query.snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text('No hay miembros registrados en este barrio.'));

                var docsFiltrados = snapshot.data!.docs.where((doc) {
                  var data = doc.data() as Map<String, dynamic>;
                  String fullName = "${data['firstName'] ?? ''} ${data['lastName'] ?? ''}".toLowerCase();
                  if (_searchQuery.isNotEmpty && !fullName.contains(_searchQuery)) return false;

                  bool esJAS = data['isYSA'] == true;
                  String primaryOrganization = data['organization'] ?? 'Miembro General';

                  if (_filtroOrganizacion == 'JAS' && !esJAS) return false;
                  else if (_filtroOrganizacion == 'Hombres' && data['gender'] != 'M') return false;
                  else if (_filtroOrganizacion == 'Mujeres' && data['gender'] != 'F') return false;
                  else if (_filtroOrganizacion == 'Jóvenes') {
                    if (!['Mujeres Jóvenes', 'Hombres Jóvenes'].contains(primaryOrganization)) return false;
                  }
                  else if (_filtroOrganizacion != 'Todos' && kOrganizationsList.contains(_filtroOrganizacion)) {
                    if (primaryOrganization != _filtroOrganizacion) return false;
                  }

                  var reg = data[keyRegistroAnio] as Map<String, dynamic>? ?? {};
                  bool hLogin = false; bool hArbol = false; bool hRec = false; bool hTemplo = false; bool h4Gen = false;
                  int mesLimite = int.parse(_mesSeleccionado);

                  for(int i = 1; i <= mesLimite; i++) {
                    String mKey = i.toString().padLeft(2, '0');
                    var mData = reg[mKey] as Map<String, dynamic>? ?? {};
                    if (mData['login_fs'] == true) hLogin = true;
                    if (mData['arbol_crecido'] == true) hArbol = true;
                    if (mData['recuerdos'] == true) hRec = true;
                    if (mData['nombres_templo'] == true) hTemplo = true;
                    if (mData['cuatro_generaciones'] == true) h4Gen = true;
                  }

                  int checksCompletados = 0;
                  if (hLogin) checksCompletados++;
                  if (hArbol) checksCompletados++;
                  if (hRec) checksCompletados++;
                  if (hTemplo) checksCompletados++;
                  if (h4Gen) checksCompletados++;

                  if (_filtroProgreso == 'Sin Iniciar' && checksCompletados > 0) return false;
                  if (_filtroProgreso == 'En Progreso' && (checksCompletados == 0 || checksCompletados == 5)) return false;
                  if (_filtroProgreso == 'Listos' && checksCompletados < 5) return false;

                  return true;
                }).toList();

                if (docsFiltrados.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.person_search, size: 80, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text('Nadie coincide con estos filtros.', style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
                      ],
                    ),
                  );
                }

                docsFiltrados.sort((a, b) => ((a.data() as Map<String, dynamic>)['lastName'] ?? '').compareTo((b.data() as Map<String, dynamic>)['lastName'] ?? ''));

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: docsFiltrados.length,
                  itemBuilder: (context, index) {
                    var doc = docsFiltrados[index];
                    var data = doc.data() as Map<String, dynamic>;
                    var reg = data[keyRegistroAnio] as Map<String, dynamic>? ?? {};

                    return Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ExpansionTile(
                        leading: CircleAvatar(
                          backgroundColor: data['gender'] == 'M' ? Colors.blue.shade50 : Colors.pink.shade50,
                          child: Icon(Icons.person, color: data['gender'] == 'M' ? Colors.blue.shade700 : Colors.pink.shade700),
                        ),
                        title: Text("${data['firstName']} ${data['lastName']}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        subtitle: Text("${data['organization'] ?? 'Miembro General'} ${data['isYSA'] == true ? '• JAS' : ''}", style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            child: Column(
                              children: [
                                _buildCheckRow(doc.id, 'login_fs', '1. Inició Sesión en FamilySearch', reg, keyRegistroAnio),
                                _buildCheckRow(doc.id, 'arbol_crecido', '2. Agregó un Antepasado al Árbol', reg, keyRegistroAnio),
                                _buildCheckRow(doc.id, 'recuerdos', '3. Agregó un Recuerdo (Foto/Audio)', reg, keyRegistroAnio),
                                _buildCheckRow(doc.id, 'nombres_templo', '4. Envió nombres para el Templo', reg, keyRegistroAnio),
                                _buildCheckRow(doc.id, 'cuatro_generaciones', '5. Árbol de 4 Generaciones completo', reg, keyRegistroAnio),
                              ],
                            ),
                          )
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltroTag(IconData icon, String text) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: _brandBlue.withOpacity(0.08), borderRadius: BorderRadius.circular(20), border: Border.all(color: _brandBlue.withOpacity(0.3))),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: _brandBlue),
          const SizedBox(width: 4),
          Text(text, style: const TextStyle(fontSize: 12, color: _brandBlue, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildCheckRow(String userId, String fieldKey, String title, Map<String, dynamic> regAnio, String keyAnio) {
    bool completedThisMonth = regAnio[_mesSeleccionado]?[fieldKey] == true;
    bool completedBefore = false;
    String monthCompleted = '';

    int mesActualNum = int.parse(_mesSeleccionado);
    for (int i = 1; i < mesActualNum; i++) {
      String mKey = i.toString().padLeft(2, '0');
      if (regAnio[mKey]?[fieldKey] == true) {
        completedBefore = true;
        monthCompleted = _nombresMeses[mKey] ?? mKey;
        break;
      }
    }

    bool isChecked = completedThisMonth || completedBefore;

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(color: isChecked ? Colors.green.shade50 : Colors.transparent, borderRadius: BorderRadius.circular(8), border: Border.all(color: isChecked ? Colors.green.shade200 : Colors.transparent)),
      child: CheckboxListTile(
        title: Text(title, style: TextStyle(fontSize: 13, fontWeight: isChecked ? FontWeight.bold : FontWeight.normal, color: isChecked ? Colors.green.shade800 : Colors.black87)),
        subtitle: completedBefore ? Text('✅ Meta lograda en $monthCompleted', style: TextStyle(fontSize: 11, color: Colors.green.shade700, fontStyle: FontStyle.italic)) : null,
        value: isChecked,
        activeColor: Colors.green,
        dense: true,
        onChanged: completedBefore ? null : (bool? newValue) {
          if (newValue != null) {
            FirebaseFirestore.instance.collection('users').doc(userId).set({
              keyAnio: {
                _mesSeleccionado: {fieldKey: newValue}
              }
            }, SetOptions(merge: true));
          }
        },
      ),
    );
  }
}