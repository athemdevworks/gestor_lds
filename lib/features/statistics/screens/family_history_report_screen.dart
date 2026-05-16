import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gestor_lds/core/constants/wards_list.dart';
import 'package:gestor_lds/core/constants/organizations_list.dart';

class FamilyHistoryReportScreen extends StatefulWidget {
  const FamilyHistoryReportScreen({super.key});

  @override
  State<FamilyHistoryReportScreen> createState() => _FamilyHistoryReportScreenState();
}

class _FamilyHistoryReportScreenState extends State<FamilyHistoryReportScreen> {
  final Color _brandBlue = const Color(0xFF22539A);

  // Filtros principales de la pantalla completa
  String _barrioSeleccionado = 'Todos';
  String _filtroOrganizacion = 'Todos';

  final int _anioActual = DateTime.now().year;

  final Map<String, String> _nombresMeses = {
    '01': 'Ene', '02': 'Feb', '03': 'Mar', '04': 'Abr', '05': 'May', '06': 'Jun',
    '07': 'Jul', '08': 'Ago', '09': 'Sep', '10': 'Oct', '11': 'Nov', '12': 'Dic'
  };

  final List<String> _opcionesDemograficas = [
    'Todos', 'JAS', 'Hombres', 'Mujeres', 'Jóvenes', ...kOrganizationsList
  ];

  // Generamos de forma dinámica los meses transcurridos del año para la comparativa
  late final List<String> _mesesHistoricos;

  @override
  void initState() {
    super.initState();
    // Traemos los meses en orden cronológico (ej: de Enero hasta el mes actual)
    int mesActual = DateTime.now().month;
    _mesesHistoricos = List.generate(mesActual, (i) => (i + 1).toString().padLeft(2, '0'));
  }

  @override
  Widget build(BuildContext context) {
    // Consulta táctica a la colección única
    Query query = FirebaseFirestore.instance.collection('users');
    if (_barrioSeleccionado != 'Todos') {
      query = query.where('ward', isEqualTo: _barrioSeleccionado);
    }

    final String keyRegistroAnio = 'registro_$_anioActual';

    return Scaffold(
      backgroundColor: const Color(0xFFEEF2F6),
      appBar: AppBar(
        title: const Text('Comparativa de Historia Familiar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: _brandBlue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // ==========================================
          // 🚀 BARRA SUPERIOR DE FILTROS EN PANTALLA
          // ==========================================
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _barrioSeleccionado,
                    decoration: InputDecoration(
                        labelText: 'Barrio',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        isDense: true,
                        prefixIcon: const Icon(Icons.location_city, size: 20)
                    ),
                    items: ['Todos', ...kWardsList].map((b) => DropdownMenuItem(value: b, child: Text(b, style: const TextStyle(fontSize: 13)))).toList(),
                    onChanged: (val) => setState(() => _barrioSeleccionado = val!),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _filtroOrganizacion,
                    decoration: InputDecoration(
                        labelText: 'Filtro Demográfico',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        isDense: true,
                        prefixIcon: const Icon(Icons.group, size: 20)
                    ),
                    items: _opcionesDemograficas.map((o) => DropdownMenuItem(value: o, child: Text(o, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis))).toList(),
                    onChanged: (val) => setState(() => _filtroOrganizacion = val!),
                  ),
                ),
              ],
            ),
          ),

          // ==========================================
          // 🚀 PROCESAMIENTO Y GRÁFICOS EVOLUTIVOS
          // ==========================================
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: query.snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No hay datos disponibles para la combinación elegida.'));
                }

                final usersDocs = snapshot.data!.docs;

                // Estructuras de datos para calcular los totales mes a mes por cada indicador
                Map<String, int> histLogin = { for (var m in _mesesHistoricos) m : 0 };
                Map<String, int> histArbol = { for (var m in _mesesHistoricos) m : 0 };
                Map<String, int> histRecuerdos = { for (var m in _mesesHistoricos) m : 0 };
                Map<String, int> histTemplo = { for (var m in _mesesHistoricos) m : 0 };
                Map<String, int> hist4Gen = { for (var m in _mesesHistoricos) m : 0 };

                int totalMiembrosFiltrados = 0;

                // Recorremos los usuarios aplicando el filtro demográfico seleccionado
                for (var doc in usersDocs) {
                  var data = doc.data() as Map<String, dynamic>;

                  bool esYSA = data['isYSA'] == true;
                  String userOrg = data['organization'] ?? 'Miembro General';

                  if (_filtroOrganizacion == 'JAS' && !esYSA) continue;
                  if (_filtroOrganizacion == 'Hombres' && data['gender'] != 'M') continue;
                  if (_filtroOrganizacion == 'Mujeres' && data['gender'] != 'F') continue;
                  if (_filtroOrganizacion == 'Jóvenes' && !['Mujeres Jóvenes', 'Hombres Jóvenes'].contains(userOrg)) continue;
                  if (_filtroOrganizacion != 'Todos' && kOrganizationsList.contains(_filtroOrganizacion) && userOrg != _filtroOrganizacion) continue;

                  totalMiembrosFiltrados++;

                  var regAnio = data[keyRegistroAnio] as Map<String, dynamic>? ?? {};

                  // Mapeamos los logros de este usuario en cada uno de los meses del histórico
                  for (String mesKey in _mesesHistoricos) {
                    var mesData = regAnio[mesKey] as Map<String, dynamic>? ?? {};
                    if (mesData['login_fs'] == true) histLogin[mesKey] = (histLogin[mesKey] ?? 0) + 1;
                    if (mesData['arbol_crecido'] == true) histArbol[mesKey] = (histArbol[mesKey] ?? 0) + 1;
                    if (mesData['recuerdos'] == true) histRecuerdos[mesKey] = (histRecuerdos[mesKey] ?? 0) + 1;
                    if (mesData['nombres_templo'] == true) histTemplo[mesKey] = (histTemplo[mesKey] ?? 0) + 1;
                    if (mesData['cuatro_generaciones'] == true) hist4Gen[mesKey] = (hist4Gen[mesKey] ?? 0) + 1;
                  }
                }

                if (totalMiembrosFiltrados == 0) {
                  return const Center(child: Text('Ningún miembro cumple con el criterio demográfico actual.', style: TextStyle(fontStyle: FontStyle.italic)));
                }

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Banner informativo superior
                    Card(
                      color: _brandBlue,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline, color: Colors.white, size: 28),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Evaluando el impacto sobre un universo total de $totalMiembrosFiltrados miembro(s) filtrado(s). Las gráficas muestran la evolución y avance comparativo mes a mes.',
                                style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.3),
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 📊 SECCIÓN DE GRÁFICAS COMPARATIVAS INDEPENDIENTES
                    _buildEvolutionCard('1. Sesión Iniciada en FamilySearch', histLogin, totalMiembrosFiltrados, Colors.blue),
                    _buildEvolutionCard('2. Antepasados Agregados al Árbol', histArbol, totalMiembrosFiltrados, Colors.orange),
                    _buildEvolutionCard('3. Recuerdos Guardados (Fotos/Audios)', histRecuerdos, totalMiembrosFiltrados, Colors.purple),
                    _buildEvolutionCard('4. Nombres Listos Enviados al Templo', histTemplo, totalMiembrosFiltrados, Colors.green),
                    _buildEvolutionCard('5. Cuadro de 4 Generaciones Completo', hist4Gen, totalMiembrosFiltrados, Colors.teal),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // WIDGET CONSTRUCTOR DE CADA BLOQUE DE METAS
  // ==========================================
  Widget _buildEvolutionCard(String title, Map<String, int> dataHistorica, int universoTotal, Color colorIndicador) {
    // Hallamos el valor máximo del histórico para escalar visualmente de forma limpia
    int maxValor = dataHistorica.values.fold(1, (max, e) => e > max ? e : max);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87)),
            const SizedBox(height: 20),

            // Render de las barras de progreso comparativas alineadas en horizontal
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: _mesesHistoricos.map((mesKey) {
                final int logsMes = dataHistorica[mesKey] ?? 0;
                final double porcentaje = universoTotal > 0 ? (logsMes / universoTotal) * 100 : 0.0;

                // Altura de la barra física (máximo de 100 de altura)
                final double alturaCalculada = (logsMes / maxValor) * 90;

                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text('$logsMes', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: colorIndicador)),
                    Text('${porcentaje.toStringAsFixed(0)}%', style: TextStyle(fontSize: 9, color: Colors.grey.shade500)),
                    const SizedBox(height: 6),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 28,
                      height: alturaCalculada < 4 ? 4 : alturaCalculada,
                      decoration: BoxDecoration(
                          color: colorIndicador.withOpacity(0.85),
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                          boxShadow: [
                            BoxShadow(color: colorIndicador.withOpacity(0.15), blurRadius: 2, offset: const Offset(0, 1))
                          ]
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(_nombresMeses[mesKey] ?? '', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black54)),
                  ],
                );
              }).toList(),
            )
          ],
        ),
      ),
    );
  }
}