import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gestor_lds/core/constants/wards_list.dart'; // Tu lista de barrios

class HistoriaFamiliarScreen extends StatefulWidget {

  final dynamic currentUser; // O cambia "dynamic" por "UserModel" si lo tienes tipado
  const HistoriaFamiliarScreen({super.key, this.currentUser}); // 🚀 Ahora acepta el parámetro
  @override
  State<HistoriaFamiliarScreen> createState() => _HistoriaFamiliarScreenState();
}

class _HistoriaFamiliarScreenState extends State<HistoriaFamiliarScreen> {
  final Color _brandBlue = const Color(0xFF164772);

  // --- VARIABLES DE FILTROS ---
  String _barrioSeleccionado = 'Todos';
  String _mesSeleccionado = DateTime.now().month.toString().padLeft(2, '0');
  String _searchQuery = '';
  String _filtroProgreso = 'Todos'; // 'Todos', 'Sin Iniciar', 'En Progreso', 'Listos'
  String _filtroDemografico = 'Todos';

  final List<String> _meses = ['01', '02', '03', '04', '05', '06', '07', '08', '09', '10', '11', '12'];
  final Map<String, String> _nombresMeses = {
    '01': 'Enero', '02': 'Febrero', '03': 'Marzo', '04': 'Abril',
    '05': 'Mayo', '06': 'Junio', '07': 'Julio', '08': 'Agosto',
    '09': 'Septiembre', '10': 'Octubre', '11': 'Noviembre', '12': 'Diciembre'
  };
  final List<String> _opcionesProgreso = ['Todos', 'Sin Iniciar', 'En Progreso', 'Listos'];
  final List<String> _opcionesDemograficas = [
    'Todos', 'Solo JAS', 'Hombres', 'Mujeres',
    'Sociedad de Socorro', 'Cuórum de Élderes', 'Jóvenes'
  ];

  late final List<String> _barriosSelectable;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _barriosSelectable = ['Todos', ...kWardsList]; // Ajusta 'kWardsList' a tu variable real
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Consulta principal a Firebase (Solo filtramos por barrio en la base de datos)
    Query query = FirebaseFirestore.instance.collection('members'); // Ajusta a tu colección de miembros
    if (_barrioSeleccionado != 'Todos') {
      query = query.where('ward', isEqualTo: _barrioSeleccionado);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFEEF2F6),
      appBar: AppBar(
        title: const Text('Templo e Historia Familiar', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: _brandBlue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // ==========================================
          // PANEL DE FILTROS AVANZADOS
          // ==========================================
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // 1. Barrio y Mes
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _barrioSeleccionado,
                        decoration: InputDecoration(labelText: 'Barrio', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), isDense: true),
                        items: _barriosSelectable.map((b) => DropdownMenuItem(value: b, child: Text(b, style: const TextStyle(fontSize: 13)))).toList(),
                        onChanged: (val) => setState(() => _barrioSeleccionado = val!),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _mesSeleccionado,
                        decoration: InputDecoration(labelText: 'Mes', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), isDense: true),
                        // 🚀 Aplicamos el traductor
                        items: _meses.map((m) => DropdownMenuItem(value: m, child: Text(_nombresMeses[m]!, style: const TextStyle(fontSize: 13)))).toList(),
                        onChanged: (val) => setState(() => _mesSeleccionado = val!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // 2. Buscador Instantáneo (Nombre/Apellido)
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: 'Buscar hermano(a)...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(icon: const Icon(Icons.clear), onPressed: () { _searchController.clear(); setState(() => _searchQuery = ''); })
                        : null,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    isDense: true,
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
                ),
                const SizedBox(height: 12),

                // 3. Filtro Demográfico
                DropdownButtonFormField<String>(
                  value: _filtroDemografico,
                  decoration: InputDecoration(labelText: 'Grupo Demográfico', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), isDense: true),
                  items: _opcionesDemograficas.map((d) => DropdownMenuItem(value: d, child: Text(d, style: const TextStyle(fontSize: 13)))).toList(),
                  onChanged: (val) => setState(() => _filtroDemografico = val!),
                ),
                const SizedBox(height: 12),

                // 4. Chips de Progreso (Estado)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _opcionesProgreso.map((estado) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          label: Text(estado, style: TextStyle(color: _filtroProgreso == estado ? Colors.white : Colors.black87)),
                          selectedColor: _brandBlue,
                          backgroundColor: Colors.grey.shade200,
                          selected: _filtroProgreso == estado,
                          onSelected: (selected) {
                            if (selected) setState(() => _filtroProgreso = estado);
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // ==========================================
          // LISTA DE MIEMBROS (CON FILTRADO EN MEMORIA)
          // ==========================================
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: query.snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No hay miembros en este barrio.'));
                }

                // --- MOTOR DE FILTRADO ---
                var docsFiltrados = snapshot.data!.docs.where((doc) {
                  var data = doc.data() as Map<String, dynamic>;

                  // A. Filtro de Búsqueda (Texto)
                  String fullName = "${data['firstName']} ${data['lastName']}".toLowerCase();
                  if (_searchQuery.isNotEmpty && !fullName.contains(_searchQuery)) return false;

                  // B. Filtro Demográfico
                  if (_filtroDemografico == 'Solo JAS' && data['isYSA'] != true) return false;
                  if (_filtroDemografico == 'Hombres' && data['gender'] != 'M') return false;
                  if (_filtroDemografico == 'Mujeres' && data['gender'] != 'F') return false;
                  if (_filtroDemografico == 'Sociedad de Socorro' && data['primaryOrganization'] != 'Sociedad de Socorro') return false;
                  if (_filtroDemografico == 'Cuórum de Élderes' && data['primaryOrganization'] != 'Cuórum de Élderes') return false;
                  if (_filtroDemografico == 'Jóvenes') {
                    bool esJoven = ['Mujeres Jóvenes', 'Presbíteros', 'Maestros', 'Diáconos'].contains(data['primaryOrganization']);
                    if (!esJoven) return false;
                  }

                  // C. Filtro de Progreso (Checks)
                  var reg = data['registro_2026'] as Map<String, dynamic>? ?? {};
                  var mesData = reg[_mesSeleccionado] as Map<String, dynamic>? ?? {};

                  int checksCompletados = 0;
                  if (mesData['login_fs'] == true) checksCompletados++;
                  if (mesData['recuerdos'] == true) checksCompletados++;
                  if (mesData['arbol_crecido'] == true) checksCompletados++;
                  if (mesData['nombres_templo'] == true) checksCompletados++;

                  if (_filtroProgreso == 'Sin Iniciar' && checksCompletados > 0) return false;
                  if (_filtroProgreso == 'En Progreso' && (checksCompletados == 0 || checksCompletados == 4)) return false;
                  if (_filtroProgreso == 'Listos' && checksCompletados < 4) return false;

                  return true; // Si pasa todos los filtros, lo mostramos
                }).toList();

                if (docsFiltrados.isEmpty) {
                  return const Center(child: Text('Nadie coincide con estos filtros.'));
                }

                // Renderizamos la lista filtrada
                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: docsFiltrados.length,
                  itemBuilder: (context, index) {
                    var doc = docsFiltrados[index];
                    var data = doc.data() as Map<String, dynamic>;

                    var reg = data['registro_2026'] as Map<String, dynamic>? ?? {};
                    var mesData = reg[_mesSeleccionado] as Map<String, dynamic>? ?? {};

                    return Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ExpansionTile(
                        leading: CircleAvatar(
                          backgroundColor: data['gender'] == 'M' ? Colors.blue.shade100 : Colors.pink.shade100,
                          child: Icon(Icons.person, color: data['gender'] == 'M' ? Colors.blue.shade700 : Colors.pink.shade700),
                        ),
                        title: Text("${data['firstName']} ${data['lastName']}", style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text("${data['primaryOrganization']} ${data['isYSA'] ? '• JAS' : ''}", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                _buildCheckRow(doc.id, 'login_fs', '1. Inició Sesión en FS', mesData['login_fs'] ?? false),
                                _buildCheckRow(doc.id, 'recuerdos', '2. Agregó Recuerdos', mesData['recuerdos'] ?? false),
                                _buildCheckRow(doc.id, 'arbol_crecido', '3. Árbol de 4 Generaciones', mesData['arbol_crecido'] ?? false),
                                _buildCheckRow(doc.id, 'nombres_templo', '4. Nombres listos para el Templo', mesData['nombres_templo'] ?? false),
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

  // --- WIDGET PARA LOS CHECKS ---
  Widget _buildCheckRow(String memberId, String fieldKey, String title, bool currentValue) {
    return CheckboxListTile(
      title: Text(title, style: const TextStyle(fontSize: 14)),
      value: currentValue,
      activeColor: Colors.green,
      dense: true,
      onChanged: (bool? newValue) {
        if (newValue != null) {
          FirebaseFirestore.instance.collection('members').doc(memberId).set({
            'registro_2026': {
              _mesSeleccionado: {
                fieldKey: newValue
              }
            }
          }, SetOptions(merge: true));
        }
      },
    );
  }
}