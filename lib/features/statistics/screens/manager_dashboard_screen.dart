import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Importa aquí tus pantallas y la lista de barrios centralizada
import 'package:gestor_lds/features/statistics/screens/speaker_list_screen.dart';
import 'package:gestor_lds/features/statistics/services/statistics_service.dart';
import 'package:gestor_lds/features/statistics/screens/hymn_list_screen.dart';
import 'package:gestor_lds/core/constants/wards_list.dart';

class ManagerDashboardScreen extends StatefulWidget {
  const ManagerDashboardScreen({super.key});

  @override
  State<ManagerDashboardScreen> createState() => _ManagerDashboardScreenState();
}

class _ManagerDashboardScreenState extends State<ManagerDashboardScreen> {
  final StatisticsService _statsService = StatisticsService();
  final Color _brandBlue = const Color(0xFF164772);

  Map<String, int>? _commitmentsStats;
  Map<String, double>? _budgetStats;
  Map<String, int>? _interviewStats;
  List<Map<String, dynamic>>? _overdueCommitments;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    final results = await Future.wait([
      _statsService.getCommitmentsStats(),
      _statsService.getBudgetStats(),
      _statsService.getInterviewStats(),
      _statsService.getOverdueCommitments(),
    ]);

    if (mounted) {
      setState(() {
        _commitmentsStats = results[0] as Map<String, int>;
        _budgetStats = results[1] as Map<String, double>;
        _interviewStats = results[2] as Map<String, int>;
        _overdueCommitments = results[3] as List<Map<String, dynamic>>;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // 🚀 MAGIA RESPONSIVA: Medimos el ancho de la pantalla
    double screenWidth = MediaQuery.of(context).size.width;
    bool isMobile = screenWidth < 600; // Si es menor a 600px, asumimos que es celular

    return Scaffold(
      backgroundColor: const Color(0xFFEEF2F6),
      appBar: AppBar(
        title: const Text('Panel Manager', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: _brandBlue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _loadAllData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                // 📱 Móvil = 2 columnas | 💻 PC = 3 columnas
                crossAxisCount: isMobile ? 2 : 3,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                // 📱 Móvil = Cuadrados (1.1) | 💻 PC = Rectangulares (2.4)
                childAspectRatio: isMobile ? 1.1 : 2.4,
                children: [
                  _buildCategoryCard(
                    title: 'Discursos',
                    icon: Icons.record_voice_over,
                    color: Colors.blue,
                    isMobile: isMobile, // Pasamos el dato
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SpeakerListScreen())),
                  ),
                  _buildCategoryCard(
                    title: 'Himnos',
                    icon: Icons.library_music,
                    color: Colors.indigo,
                    isMobile: isMobile,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HymnListScreen())),
                  ),
                  _buildCategoryCard(
                    title: 'Entrevistas',
                    icon: Icons.people_alt,
                    color: Colors.teal,
                    isMobile: isMobile,
                    onTap: () => _mostrarPanelEntrevistas(),
                  ),
                  _buildCategoryCard(
                    title: 'Presupuesto',
                    icon: Icons.account_balance_wallet,
                    color: Colors.purple,
                    isMobile: isMobile,
                    onTap: () => _mostrarPanelPresupuesto(),
                  ),
                  _buildCategoryCard(
                    title: 'Pendientes',
                    icon: Icons.assignment_late,
                    color: Colors.orange,
                    badgeCount: _overdueCommitments?.length ?? 0,
                    isMobile: isMobile,
                    onTap: () => _mostrarPanelCompromisos(),
                  ),
                  _buildCategoryCard(
                    title: 'Historia Familiar',
                    icon: Icons.family_restroom,
                    color: Colors.green,
                    isMobile: isMobile,
                    onTap: () => _mostrarPanelHistoriaFamiliar(),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Divider(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryCard({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    int badgeCount = 0,
    required bool isMobile, // 🚀 Recibimos si es móvil o no
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: isMobile
                  ? Column( // 📱 DISEÑO MÓVIL (Apilado y compacto)
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 40, color: color),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, height: 1.1),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              )
                  : Row( // 💻 DISEÑO WEB (Horizontal y gigante)
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 64, color: color),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, height: 1.1),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            if (badgeCount > 0)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                  child: Text('$badgeCount', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ),
          ],
        ),
      ),
    );
  }
  // --- MÉTODOS DE PANELES (IGUALES A LOS ANTERIORES) ---
  void _mostrarPanelEntrevistas() {
    final reserved = _interviewStats?['reserved'] ?? 0;
    final available = _interviewStats?['available'] ?? 0;
    final total = reserved + available;
    final double progress = total == 0 ? 0 : (reserved / total);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Ocupación de Entrevistas', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 25),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('$reserved Reservados', style: TextStyle(fontWeight: FontWeight.bold, color: _brandBlue, fontSize: 16)),
                Text('$available Libres', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 15),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 15,
                backgroundColor: Colors.green.shade100,
                color: _brandBlue,
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
  void _mostrarPanelPresupuesto() {
    final reimbursements = _budgetStats?['reimbursements'] ?? 0.0;
    final advances = _budgetStats?['advances'] ?? 0.0;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Flujo de Gastos', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 30),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  barTouchData: BarTouchData(enabled: false),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value == 0) return const Text('Reembolsos', style: TextStyle(fontWeight: FontWeight.bold));
                          if (value == 1) return const Text('Adelantos', style: TextStyle(fontWeight: FontWeight.bold));
                          return const SizedBox();
                        },
                      ),
                    ),
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  barGroups: [
                    BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: reimbursements, color: Colors.blue, width: 45, borderRadius: BorderRadius.circular(6))]),
                    BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: advances, color: Colors.purple, width: 45, borderRadius: BorderRadius.circular(6))]),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 15),
            Text('Total: S/ ${(reimbursements + advances).toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _mostrarPanelCompromisos() {
    final completed = _commitmentsStats?['completed'] ?? 0;
    final pending = _commitmentsStats?['pending'] ?? 0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Permite que el modal sea más alto si hay muchos atrasos
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.all(25),
          children: [
            const Text('Estado de Compromisos', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            const SizedBox(height: 20),
            SizedBox(
              height: 150,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 4,
                  centerSpaceRadius: 40,
                  sections: (completed + pending) == 0
                      ? [PieChartSectionData(color: Colors.grey.shade300, value: 1, title: '0', radius: 30)]
                      : [
                    PieChartSectionData(color: Colors.green, value: completed.toDouble(), title: '$completed', radius: 40, titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    PieChartSectionData(color: Colors.orange, value: pending.toDouble(), title: '$pending', radius: 40, titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _legendIndicator(Colors.green, 'Completados'),
                const SizedBox(width: 20),
                _legendIndicator(Colors.orange, 'Pendientes'),
              ],
            ),
            const Divider(height: 40, thickness: 1),
            Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.red.shade700),
                const SizedBox(width: 8),
                Text('Focos Rojos (Vencidos)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red.shade900)),
              ],
            ),
            const SizedBox(height: 10),
            if (_overdueCommitments == null || _overdueCommitments!.isEmpty)
              const Text('¡Excelente! No hay compromisos atrasados.', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold))
            else
              ..._overdueCommitments!.map((item) {
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.error_outline, color: Colors.red.shade400),
                  title: Text(item['description'], maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${item['responsible']} • ${item['topic']}'),
                  trailing: Text('${item['daysLate']} días', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red.shade900)),
                );
              }),
          ],
        ),
      ),
    );
  }

  void _mostrarPanelHistoriaFamiliar() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => const Padding(
        padding: EdgeInsets.only(top: 10),
        child: FamilyHistoryStatsPanel(),
      ),
    );
  }
}

Widget _legendIndicator(Color color, String text) {
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color)
      ),
      const SizedBox(width: 6),
      Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
    ],
  );
}

// ============================================================================
// PANEL DE HISTORIA FAMILIAR (USANDO TUS CONSTRAINTS GLOBALES)
// ============================================================================
class FamilyHistoryStatsPanel extends StatefulWidget {
  const FamilyHistoryStatsPanel({super.key});

  @override
  State<FamilyHistoryStatsPanel> createState() => _FamilyHistoryStatsPanelState();
}

class _FamilyHistoryStatsPanelState extends State<FamilyHistoryStatsPanel> {
  String _mesSeleccionado = DateTime.now().month.toString().padLeft(2, '0');
  String _barrioSeleccionado = 'Todos';

  final List<String> _meses = ['01', '02', '03', '04', '05', '06', '07', '08', '09', '10', '11', '12'];

  final Map<String, String> _nombresMeses = {
    '01': 'Enero', '02': 'Febrero', '03': 'Marzo', '04': 'Abril',
    '05': 'Mayo', '06': 'Junio', '07': 'Julio', '08': 'Agosto',
    '09': 'Septiembre', '10': 'Octubre', '11': 'Noviembre', '12': 'Diciembre'
  };

  // 🚀 AHORA SÍ: Usamos tu Constraint global para alimentar el Dropdown.
  // (Cambia 'AppConstants.wardsList' por el nombre exacto de tu variable global)
  late final List<String> _barriosSelectable;

  @override
  void initState() {
    super.initState();
    // Inicializamos la lista juntando 'Todos' con tu constraint
    _barriosSelectable = ['Todos', ...kWardsList];
  }

  @override
  Widget build(BuildContext context) {
    Query query = FirebaseFirestore.instance.collection('members');
    if (_barrioSeleccionado != 'Todos') {
      query = query.where('ward', isEqualTo: _barrioSeleccionado);
    }

    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Estadísticas Historia Familiar', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _barrioSeleccionado,
                  decoration: const InputDecoration(labelText: 'Barrio', border: OutlineInputBorder(), isDense: true),
                  items: _barriosSelectable.map((b) => DropdownMenuItem(value: b, child: Text(b, style: const TextStyle(fontSize: 12)))).toList(),
                  onChanged: (val) => setState(() => _barrioSeleccionado = val!),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _mesSeleccionado,
                  decoration: const InputDecoration(labelText: 'Mes', border: OutlineInputBorder(), isDense: true),
                  items: _meses.map((m) => DropdownMenuItem(value: m, child: Text(_nombresMeses[m]!, style: const TextStyle(fontSize: 12)))).toList(),                  onChanged: (val) => setState(() => _mesSeleccionado = val!),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          StreamBuilder<QuerySnapshot>(
            stream: query.snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const LinearProgressIndicator();

              int tLogin = 0; int tRecuerdos = 0; int tArbol = 0; int tTemplo = 0;

              for (var doc in snapshot.data!.docs) {
                var data = doc.data() as Map<String, dynamic>;
                var reg = data['registro_2026'] as Map<String, dynamic>? ?? {};
                var mesData = reg[_mesSeleccionado] as Map<String, dynamic>? ?? {};

                if (mesData['login_fs'] == true) tLogin++;
                if (mesData['recuerdos'] == true) tRecuerdos++;
                if (mesData['arbol_crecido'] == true) tArbol++;
                if (mesData['nombres_templo'] == true) tTemplo++;
              }

              return GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                childAspectRatio: 2.2,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                children: [
                  _miniCard('FS Login', tLogin, Colors.blue),
                  _miniCard('Recuerdos', tRecuerdos, Colors.orange),
                  _miniCard('Árbol', tArbol, Colors.green),
                  _miniCard('Templo', tTemplo, Colors.purple),
                ],
              );
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _miniCard(String label, int val, Color col) {
    return Container(
      decoration: BoxDecoration(color: col.withOpacity(0.1), borderRadius: BorderRadius.circular(10), border: Border.all(color: col.withOpacity(0.2))),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(val.toString(), style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: col)),
          Text(label, style: TextStyle(fontSize: 10, color: col.withOpacity(0.7))),
        ],
      ),
    );
  }

}