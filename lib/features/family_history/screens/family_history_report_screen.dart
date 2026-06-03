import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gestor_lds/features/auth/models/user_model.dart';
import 'package:gestor_lds/core/constants/wards_list.dart';
import 'package:gestor_lds/core/constants/organizations_list.dart';
import 'family_history_list_screen.dart';

class FamilyHistoryReportScreen extends StatefulWidget {
  // 🚀 RECIBIMOS LOS MANDOS DIRECTOS DESDE EL HUB
  final bool isStakeMode;
  final UserModel currentUser;

  const FamilyHistoryReportScreen({
    super.key,
    required this.isStakeMode,
    required this.currentUser,
  });

  @override
  State<FamilyHistoryReportScreen> createState() => _FamilyHistoryReportScreenState();
}

class _FamilyHistoryReportScreenState extends State<FamilyHistoryReportScreen> {
  static const Color _brandBlue = Color(0xFF22539A);

  // Filtros iniciales
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

  late final List<String> _mesesHistoricos;

  @override
  void initState() {
    super.initState();
    // Generamos los meses transcurridos en orden cronológico
    int mesActual = DateTime.now().month;
    _mesesHistoricos = List.generate(mesActual, (i) => (i + 1).toString().padLeft(2, '0'));

    // 🚀 CONTROL DE DROPDOWN ANTICRASH: Sincroniza el inicio según el sombrero activo
    _barrioSeleccionado = widget.isStakeMode ? 'Todos' : widget.currentUser.ward;
  }

  @override
  Widget build(BuildContext context) {
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
    // 🚀 IDENTIFICAMOS LAS CREDENCIALES DINÁMICAS SIN DOBLE CONSULTA
    final bool esAdminEstaca = widget.isStakeMode;

    Query query = FirebaseFirestore.instance.collection('users');
    if (_barrioSeleccionado != 'Todos') {
      query = query.where('ward', isEqualTo: _barrioSeleccionado);
    }

    final String keyRegistroAnio = 'registro_$_anioActual';

    return Scaffold(
      backgroundColor: const Color(0xFFEEF2F6),
      appBar: AppBar(
        title: const Text('Informe y Métricas Evolutivas', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: _brandBlue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      // 🚀 BLOQUEO ABSOLUTO: Si no tiene permiso, no se renderiza la información
      body: !tienePermisoGestion
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.security_outlined, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text(
              'Acceso restringido.',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black54),
            ),
            const SizedBox(height: 8),
            const Text(
              'Solo presidencias autorizadas pueden ver las métricas.',
              style: TextStyle(fontSize: 14, color: Colors.black45),
            ),
          ],
        ),
      )
          : Column(
        children: [
          // ==========================================
          // 🚀 BARRA DE FILTROS SUPERIOR
          // ==========================================
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    // 🚀 ESCUDO ABSOLUTO CONTRA EL CRASH: Asegura consistencia de valor
                    value: esAdminEstaca ? _barrioSeleccionado : widget.currentUser.ward,
                    decoration: InputDecoration(
                      labelText: 'Barrio',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      isDense: true,
                      prefixIcon: const Icon(Icons.location_city, size: 20),
                      fillColor: esAdminEstaca ? Colors.white : Colors.grey.shade100,
                      filled: !esAdminEstaca,
                    ),
                    items: esAdminEstaca
                        ? ['Todos', ...kWardsList].map((b) => DropdownMenuItem(value: b, child: Text(b, style: const TextStyle(fontSize: 13)))).toList()
                        : [widget.currentUser.ward].map((b) => DropdownMenuItem(value: b, child: Text(b, style: const TextStyle(fontSize: 13)))).toList(),
                    onChanged: esAdminEstaca ? (val) => setState(() => _barrioSeleccionado = val!) : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _filtroOrganizacion,
                    decoration: InputDecoration(
                        labelText: 'Organización',
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
          // 🚀 PROCESAMIENTO ACUMULATIVO ANUAL EN VIVO
          // ==========================================
          Theme(
            data: Theme.of(context).copyWith(scrollbarTheme: ScrollbarThemeData(thumbColor: WidgetStateProperty.all(_brandBlue.withOpacity(0.4)))),
            child: Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: query.snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('No hay datos disponibles para el barrio seleccionado.'));
                  }

                  final usersDocs = snapshot.data!.docs;

                  Map<String, int> histLogin = { for (var m in _mesesHistoricos) m : 0 };
                  Map<String, int> histArbol = { for (var m in _mesesHistoricos) m : 0 };
                  Map<String, int> histRecuerdos = { for (var m in _mesesHistoricos) m : 0 };
                  Map<String, int> histTemplo = { for (var m in _mesesHistoricos) m : 0 };
                  Map<String, int> hist4Gen = { for (var m in _mesesHistoricos) m : 0 };

                  int totalMiembrosFiltrados = 0;

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

                    bool teniaLogin = false;
                    bool teniaArbol = false;
                    bool teniaRecuerdos = false;
                    bool teniaTemplo = false;
                    bool tenia4Gen = false;

                    for (String mesKey in _mesesHistoricos) {
                      var mesData = regAnio[mesKey] as Map<String, dynamic>? ?? {};

                      if (mesData['login_fs'] == true) teniaLogin = true;
                      if (mesData['arbol_crecido'] == true) teniaArbol = true;
                      if (mesData['recuerdos'] == true) teniaRecuerdos = true;
                      if (mesData['nombres_templo'] == true) teniaTemplo = true;
                      if (mesData['cuatro_generaciones'] == true) tenia4Gen = true;

                      if (teniaLogin) histLogin[mesKey] = (histLogin[mesKey] ?? 0) + 1;
                      if (teniaArbol) histArbol[mesKey] = (histArbol[mesKey] ?? 0) + 1;
                      if (teniaRecuerdos) histRecuerdos[mesKey] = (histRecuerdos[mesKey] ?? 0) + 1;
                      if (teniaTemplo) histTemplo[mesKey] = (histTemplo[mesKey] ?? 0) + 1;
                      if (tenia4Gen) hist4Gen[mesKey] = (hist4Gen[mesKey] ?? 0) + 1;
                    }
                  }

                  if (totalMiembrosFiltrados == 0) {
                    return const Center(child: Text('Ningún miembro cumple con el criterio demográfico actual.', style: TextStyle(fontStyle: FontStyle.italic)));
                  }

                  return ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Card(
                        color: _brandBlue,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              const Icon(Icons.trending_up, color: Colors.white, size: 28),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Metas Anuales con Seguimiento Acumulativo. Universo actual: $totalMiembrosFiltrados miembros. Presiona cualquier tarjeta para ver la lista de nombres.',
                                  style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.3),
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      _buildEvolutionCard('1. Sesión Iniciada en FamilySearch', 'login_fs', histLogin, totalMiembrosFiltrados, Colors.blue),
                      _buildEvolutionCard('2. Antepasados Agregados al Árbol', 'arbol_crecido', histArbol, totalMiembrosFiltrados, Colors.orange),
                      _buildEvolutionCard('3. Recuerdos Guardados (Fotos/Audios)', 'recuerdos', histRecuerdos, totalMiembrosFiltrados, Colors.purple),
                      _buildEvolutionCard('4. Nombres Listos Enviados al Templo', 'nombres_templo', histTemplo, totalMiembrosFiltrados, Colors.green),
                      _buildEvolutionCard('5. Cuadro de 4 Generaciones Completo', 'cuatro_generaciones', hist4Gen, totalMiembrosFiltrados, Colors.teal),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEvolutionCard(String title, String fieldKey, Map<String, int> dataHistorica, int universoTotal, Color colorIndicador) {
    int maxValor = dataHistorica.values.fold(1, (max, e) => e > max ? e : max);
    String ultimoMes = _mesesHistoricos.last;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => FamilyHistoryListScreen(
                title: title,
                fieldKey: fieldKey,
                initialWard: _barrioSeleccionado,
                initialMonth: ultimoMes,
                initialOrg: _filtroOrganizacion,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
                  Icon(Icons.people_alt_outlined, size: 18, color: colorIndicador.withOpacity(0.7)),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: _mesesHistoricos.map((mesKey) {
                  final int logsMes = dataHistorica[mesKey] ?? 0;
                  final double porcentaje = universoTotal > 0 ? (logsMes / universoTotal) * 100 : 0.0;
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
      ),
    );
  }
}