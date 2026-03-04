import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:gestor_lds/features/statistics/screens/speaker_list_screen.dart';
import 'package:gestor_lds/features/statistics/services/statistics_service.dart';
// ¡Importa aquí tu nueva pantalla! Ajusta la ruta si la guardaste en otro lado.
import 'package:gestor_lds/features/statistics/screens/hymn_list_screen.dart';

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

  // Ya no cargamos el ranking aquí para que el dashboard sea súper veloz
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
    return Scaffold(
      backgroundColor: const Color(0xFFEEF2F6),
      appBar: AppBar(
        title: const Text('Modo Manager'),
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
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Visión General del Barrio', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
              const SizedBox(height: 16),

              // 1. GRÁFICO DE ANILLO (Compromisos)
              _buildCommitmentsCard(),
              const SizedBox(height: 16),

              // 2. GRÁFICO DE BARRAS (Presupuesto)
              _buildBudgetCard(),
              const SizedBox(height: 16),

              // 3. MEDIDOR (Entrevistas)
              _buildInterviewsCard(),
              const SizedBox(height: 16),

              // 4. BOTÓN HACIA LISTADO DE HIMNOS (NUEVO)
              _buildHymnsButtonCard(context),
              const SizedBox(height: 16),

              // 4. BOTÓN HACIA LISTADO DE HIMNOS (NUEVO)
              _buildSpeakersButtonCard(context),
              const SizedBox(height: 16),

              // 5. LISTA DE ALERTA (Focos Rojos)
              _buildOverdueCard(),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // WIDGET 1: COMPROMISOS (DONUT CHART)
  // ==========================================
  Widget _buildCommitmentsCard() {
    final completed = _commitmentsStats?['completed'] ?? 0;
    final pending = _commitmentsStats?['pending'] ?? 0;
    final total = completed + pending;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text('Estado de Compromisos', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 20),
            SizedBox(
              height: 180,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 4,
                  centerSpaceRadius: 50,
                  sections: total == 0
                      ? [PieChartSectionData(color: Colors.grey.shade300, value: 1, title: '0', radius: 40)]
                      : [
                    PieChartSectionData(color: Colors.green.shade400, value: completed.toDouble(), title: '$completed', radius: completed >= pending ? 45 : 35, titleStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    PieChartSectionData(color: Colors.orange.shade400, value: pending.toDouble(), title: '$pending', radius: pending > completed ? 45 : 35, titleStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _legendIndicator(Colors.green.shade400, 'Completados ($completed)'),
                const SizedBox(width: 20),
                _legendIndicator(Colors.orange.shade400, 'Pendientes ($pending)'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // WIDGET 2: PRESUPUESTO (BAR CHART)
  // ==========================================
  Widget _buildBudgetCard() {
    final reimbursements = _budgetStats?['reimbursements'] ?? 0.0;
    final advances = _budgetStats?['advances'] ?? 0.0;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text('Flujo de Gastos (Solicitudes)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 30),
            SizedBox(
              height: 150,
              child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    barTouchData: BarTouchData(
                      enabled: true,
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipColor: (group) => Colors.transparent,
                        tooltipPadding: EdgeInsets.zero,
                        tooltipMargin: 8,
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          return BarTooltipItem(
                            rod.toY.toStringAsFixed(2),
                            TextStyle(
                              color: group.x == 0 ? Colors.blue.shade700 : Colors.purple.shade700,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          );
                        },
                      ),
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            if (value == 0) return const Text('Reembolsos', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold));
                            if (value == 1) return const Text('Adelantos', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold));
                            return const Text('');
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
                      BarChartGroupData(
                        x: 0,
                        barRods: [BarChartRodData(toY: reimbursements, color: Colors.blue.shade500, width: 40, borderRadius: BorderRadius.circular(6))],
                        showingTooltipIndicators: [0],
                      ),
                      BarChartGroupData(
                        x: 1,
                        barRods: [BarChartRodData(toY: advances, color: Colors.purple.shade400, width: 40, borderRadius: BorderRadius.circular(6))],
                        showingTooltipIndicators: [0],
                      ),
                    ],
                  )
              ),
            ),
            const SizedBox(height: 10),
            Text('Total: S/ ${(reimbursements + advances).toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // WIDGET 3: ENTREVISTAS (PROGRESO)
  // ==========================================
  Widget _buildInterviewsCard() {
    final reserved = _interviewStats?['reserved'] ?? 0;
    final available = _interviewStats?['available'] ?? 0;
    final total = reserved + available;
    final double progress = total == 0 ? 0 : (reserved / total);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Ocupación de Entrevistas (Mes Actual)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('$reserved Reservados', style: TextStyle(fontWeight: FontWeight.bold, color: _brandBlue, fontSize: 16)),
                Text('$available Libres', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 12,
                backgroundColor: Colors.green.shade100,
                color: _brandBlue,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // WIDGET 4: BOTÓN HACIA RANKING DE HIMNOS (NUEVO)
  // ==========================================
  Widget _buildHymnsButtonCard(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      // InkWell hace que tooooda la tarjeta sea un botón interactivo
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const HymnListScreen()),
          );
        },
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              // Ícono redondeado
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.indigo.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.library_music, color: Colors.indigo.shade600, size: 28),
              ),
              const SizedBox(width: 15),
              // Textos
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        'Ranking de Himnos',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.indigo.shade900)
                    ),
                    const SizedBox(height: 4),
                    Text(
                        'Ver historial y frecuencias del mes',
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade600)
                    ),
                  ],
                ),
              ),
              // Flechita indicadora
              Icon(Icons.arrow_forward_ios_rounded, color: Colors.indigo.shade300, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // WIDGET 5: FOCOS ROJOS (LISTA)
  // ==========================================
  Widget _buildOverdueCard() {
    return Card(
      elevation: 2,
      color: Colors.red.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: Colors.red.shade200)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.red.shade700),
                const SizedBox(width: 8),
                Text('Focos Rojos (Vencidos)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red.shade900)),
              ],
            ),
            const SizedBox(height: 15),
            if (_overdueCommitments == null || _overdueCommitments!.isEmpty)
              const Text('¡Excelente! No hay compromisos atrasados.', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold))
            else
              ..._overdueCommitments!.map((item) {
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(vertical: 4),
                  leading: Icon(Icons.error_outline, color: Colors.red.shade400),
                  title: Text(
                      item['description'],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)
                  ),
                  subtitle: Text('${item['responsible']} • ${item['topic']}'),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: '${item['daysLate']} ',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.red.shade900,
                              ),
                            ),
                            TextSpan(
                              text: 'días',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.red.shade900,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Text(
                        'de atraso',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
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

  // ==========================================
  // WIDGET 6: BOTÓN HACIA HISTORIAL DE DISCURSANTES
  // ==========================================
  Widget _buildSpeakersButtonCard(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const SpeakerListScreen()

            ),
          );
        },
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.record_voice_over, color: Colors.blue.shade600, size: 28),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        'Historial de Discursantes',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue.shade900)
                    ),
                    const SizedBox(height: 4),
                    Text(
                        'Ver temas y frecuencia anual',
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade600)
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, color: Colors.blue.shade300, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  // Auxiliar
  Widget _legendIndicator(Color color, String text) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
      ],
    );
  }
}