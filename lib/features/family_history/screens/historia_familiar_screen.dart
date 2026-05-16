import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gestor_lds/core/constants/wards_list.dart';
import 'package:gestor_lds/core/constants/organizations_list.dart';

class HistoriaFamiliarScreen extends StatefulWidget {
  final dynamic currentUser;
  const HistoriaFamiliarScreen({super.key, this.currentUser});
  @override
  State<HistoriaFamiliarScreen> createState() => _HistoriaFamiliarScreenState();
}

class _HistoriaFamiliarScreenState extends State<HistoriaFamiliarScreen> {
  final Color _brandBlue = const Color(0xFF22539A);

  // --- VARIABLES DE FILTROS ---
  String _barrioSeleccionado = 'Todos';
  String _mesSeleccionado = DateTime.now().month.toString().padLeft(2, '0');
  String _searchQuery = '';
  String _filtroProgreso = 'Todos';
  String _filtroOrganizacion = 'Todos';

  // 🚀 TÁCTICA AÑO DINÁMICO: Evita romper la base de datos al cambiar de año
  final int _anioActual = DateTime.now().year;

  final List<String> _meses = ['01', '02', '03', '04', '05', '06', '07', '08', '09', '10', '11', '12'];
  final Map<String, String> _nombresMeses = {
    '01': 'Enero', '02': 'Febrero', '03': 'Marzo', '04': 'Abril',
    '05': 'Mayo', '06': 'Junio', '07': 'Julio', '08': 'Agosto',
    '09': 'Septiembre', '10': 'Octubre', '11': 'Noviembre', '12': 'Diciembre'
  };

  final List<String> _opcionesProgreso = ['Todos', 'Sin Iniciar', 'En Progreso', 'Listos'];

  final List<String> _opcionesDemograficas = [
    'Todos',
    'JAS',
    'Hombres',
    'Mujeres',
    'Jóvenes',
    ...kOrganizationsList
  ];

  late final List<String> _barriosSelectable;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _barriosSelectable = ['Todos', ...kWardsList];
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ==========================================
  // 🚀 PANEL EMERGENTE DE FILTROS (BOTTOM SHEET INTACTO)
  // ==========================================
  void _mostrarPanelFiltros() {
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) {
          return StatefulBuilder(
              builder: (BuildContext context, StateSetter setModalState) {
                return Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                    top: 24,
                    left: 20,
                    right: 20,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Filtros Avanzados', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(context),
                          )
                        ],
                      ),
                      const Divider(height: 20),

                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _barrioSeleccionado,
                              decoration: InputDecoration(labelText: 'Barrio', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), isDense: true),
                              items: _barriosSelectable.map((b) => DropdownMenuItem(value: b, child: Text(b, style: const TextStyle(fontSize: 14)))).toList(),
                              onChanged: (val) {
                                setModalState(() => _barrioSeleccionado = val!);
                                setState(() {});
                              },
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
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _brandBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
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
    // 🚀 REDIRECCIÓN TÁCTICA A LA COLECCIÓN UNIFICADA "USERS"
    Query query = FirebaseFirestore.instance.collection('users');
    if (_barrioSeleccionado != 'Todos') {
      query = query.where('ward', isEqualTo: _barrioSeleccionado);
    }

    final String keyRegistroAnio = 'registro_$_anioActual';

    return Scaffold(
      backgroundColor: const Color(0xFFEEF2F6),
      appBar: AppBar(
        title: const Text('Historia Familiar', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: _brandBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list_alt),
            tooltip: 'Filtros',
            onPressed: _mostrarPanelFiltros,
          )
        ],
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
                    prefixIcon: Icon(Icons.search, color: _brandBlue),
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
                      _buildFiltroTag(Icons.calendar_month, _nombresMeses[_mesSeleccionado]!),
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
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No hay miembros registrados en este barrio.'));
                }

                var docsFiltrados = snapshot.data!.docs.where((doc) {
                  var data = doc.data() as Map<String, dynamic>;

                  // A. Filtro de Búsqueda Seguro (Usando los nuevos campos)
                  String firstName = data['firstName'] ?? '';
                  String lastName = data['lastName'] ?? '';
                  String fullName = "$firstName $lastName".toLowerCase();
                  if (_searchQuery.isNotEmpty && !fullName.contains(_searchQuery)) return false;

                  bool esJAS = data['isYSA'] == true;
                  String primaryOrganization = data['organization'] ?? 'Miembro General';

                  // B. Filtro Demográfico
                  if (_filtroOrganizacion == 'JAS' && !esJAS) return false;
                  else if (_filtroOrganizacion == 'Hombres' && data['gender'] != 'M') return false;
                  else if (_filtroOrganizacion == 'Mujeres' && data['gender'] != 'F') return false;
                  else if (_filtroOrganizacion == 'Jóvenes') {
                    bool esJoven = ['Mujeres Jóvenes', 'Hombres Jóvenes'].contains(primaryOrganization);
                    if (!esJoven) return false;
                  }
                  else if (_filtroOrganizacion != 'Todos' && kOrganizationsList.contains(_filtroOrganizacion)) {
                    if (primaryOrganization != _filtroOrganizacion) return false;
                  }

                  // C. Filtro de Progreso Dinámico
                  var reg = data[keyRegistroAnio] as Map<String, dynamic>? ?? {};
                  var mesData = reg[_mesSeleccionado] as Map<String, dynamic>? ?? {};

                  int checksCompletados = 0;
                  if (mesData['login_fs'] == true) checksCompletados++;
                  if (mesData['arbol_crecido'] == true) checksCompletados++;
                  if (mesData['recuerdos'] == true) checksCompletados++;
                  if (mesData['nombres_templo'] == true) checksCompletados++;
                  if (mesData['cuatro_generaciones'] == true) checksCompletados++;

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

                // Ordenamos alfabéticamente por apellido para que el consultor trabaje cómodo
                docsFiltrados.sort((a, b) {
                  String nameA = (a.data() as Map<String, dynamic>)['lastName'] ?? '';
                  String nameB = (b.data() as Map<String, dynamic>)['lastName'] ?? '';
                  return nameA.compareTo(nameB);
                });

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: docsFiltrados.length,
                  itemBuilder: (context, index) {
                    var doc = docsFiltrados[index];
                    var data = doc.data() as Map<String, dynamic>;

                    var reg = data[keyRegistroAnio] as Map<String, dynamic>? ?? {};
                    var mesData = reg[_mesSeleccionado] as Map<String, dynamic>? ?? {};

                    bool esJAS = data['isYSA'] == true;
                    String primaryOrganization = data['organization'] ?? 'Miembro General';

                    return Card(
                      elevation: 2,
                      shadowColor: Colors.black12,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ExpansionTile(
                        leading: CircleAvatar(
                          backgroundColor: data['gender'] == 'M' ? Colors.blue.shade50 : Colors.pink.shade50,
                          child: Icon(Icons.person, color: data['gender'] == 'M' ? Colors.blue.shade700 : Colors.pink.shade700),
                        ),
                        title: Text("${data['firstName']} ${data['lastName']}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        subtitle: Text("$primaryOrganization ${esJAS ? '• JAS' : ''}", style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            child: Column(
                              children: [
                                _buildCheckRow(doc.id, 'login_fs', '1. Inició Sesión en FamilySearch', mesData['login_fs'] ?? false, keyRegistroAnio),
                                _buildCheckRow(doc.id, 'arbol_crecido', '2. Agregó un Antepasado al Árbol', mesData['arbol_crecido'] ?? false, keyRegistroAnio),
                                _buildCheckRow(doc.id, 'recuerdos', '3. Agregó un Recuerdo (Foto/Audio)', mesData['recuerdos'] ?? false, keyRegistroAnio),
                                _buildCheckRow(doc.id, 'nombres_templo', '4. Envió nombres para el Templo', mesData['nombres_templo'] ?? false, keyRegistroAnio),
                                _buildCheckRow(doc.id, 'cuatro_generaciones', '5. Árbol de 4 Generaciones completo', mesData['cuatro_generaciones'] ?? false, keyRegistroAnio),
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
      decoration: BoxDecoration(
        color: _brandBlue.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _brandBlue.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: _brandBlue),
          const SizedBox(width: 4),
          Text(text, style: TextStyle(fontSize: 12, color: _brandBlue, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildCheckRow(String userId, String fieldKey, String title, bool currentValue, String keyAnio) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
          color: currentValue ? Colors.green.shade50 : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: currentValue ? Colors.green.shade200 : Colors.transparent)
      ),
      child: CheckboxListTile(
        title: Text(title, style: TextStyle(fontSize: 13, fontWeight: currentValue ? FontWeight.bold : FontWeight.normal, color: currentValue ? Colors.green.shade800 : Colors.black87)),
        value: currentValue,
        activeColor: Colors.green,
        dense: true,
        onChanged: (bool? newValue) {
          if (newValue != null) {
            // 🚀 ESCRITURA DIRECTA EN LA VARIABLE ANIO DINÁMICO
            FirebaseFirestore.instance.collection('users').doc(userId).set({
              keyAnio: {
                _mesSeleccionado: {
                  fieldKey: newValue
                }
              }
            }, SetOptions(merge: true));
          }
        },
      ),
    );
  }
}