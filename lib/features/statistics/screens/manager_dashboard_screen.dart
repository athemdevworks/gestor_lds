import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import 'package:gestor_lds/features/statistics/screens/speaker_list_screen.dart';
import 'package:gestor_lds/features/statistics/services/statistics_service.dart';
import 'package:gestor_lds/features/statistics/screens/hymn_list_screen.dart';
import 'package:gestor_lds/core/constants/wards_list.dart';

import 'package:gestor_lds/features/auth/models/user_model.dart';
import 'package:gestor_lds/features/family_history/screens/family_history_report_screen.dart';
import 'package:gestor_lds/features/budget/screens/budget_list_screen.dart';
import 'package:gestor_lds/features/interviews/screens/interviews_screen.dart';
import 'package:gestor_lds/features/commitments/screens/my_commitments_screen.dart';

class ManagerDashboardScreen extends StatefulWidget {
  final bool isStakeMode;
  final UserModel currentUser;

  const ManagerDashboardScreen({
    super.key,
    required this.isStakeMode,
    required this.currentUser,
  });

  @override
  State<ManagerDashboardScreen> createState() => _ManagerDashboardScreenState();
}

class _ManagerDashboardScreenState extends State<ManagerDashboardScreen> {
  final StatisticsService _statsService = StatisticsService();
  final Color _brandBlue = const Color(0xFF22539A);

  late String _selectedWard;

  Map<String, int>? _commitmentsStats;
  Map<String, double>? _budgetStats;
  Map<String, int>? _interviewStats;
  List<Map<String, dynamic>>? _overdueCommitments;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedWard = widget.isStakeMode ? 'Todos' : widget.currentUser.ward;
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);

    final results = await Future.wait([
      _statsService.getCommitmentsStats(ward: _selectedWard),
      _statsService.getBudgetStats(ward: _selectedWard),
      _statsService.getInterviewStats(ward: _selectedWard),
      _statsService.getOverdueCommitments(ward: _selectedWard),
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
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 600;

    return Scaffold(
      backgroundColor: const Color(0xFFEEF2F6),
      appBar: AppBar(
        title: Text(widget.isStakeMode ? 'Panel de Métricas (Estaca)' : 'Panel de Métricas'),
        backgroundColor: _brandBlue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Selector de barrio para líderes de Estaca
          if (widget.isStakeMode)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: Colors.white,
              child: DropdownButtonFormField<String>(
                value: _selectedWard,
                decoration: InputDecoration(
                  labelText: 'Filtrar Datos por Unidad',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  isDense: true,
                  prefixIcon: const Icon(Icons.location_city),
                ),
                items: ['Todos', ...kWardsList]
                    .map((b) => DropdownMenuItem(value: b, child: Text(b, style: const TextStyle(fontSize: 14))))
                    .toList(),
                onChanged: (val) {
                  if (val != null && val != _selectedWard) {
                    setState(() => _selectedWard = val);
                    _loadAllData();
                  }
                },
              ),
            ),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
              onRefresh: _loadAllData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: isMobile ? 2 : 3,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: isMobile ? 1.15 : 2.2,
                      children: [
                        _buildCategoryCard(
                          title: 'Discursos',
                          icon: Icons.record_voice_over,
                          color: Colors.blue.shade700,
                          isMobile: isMobile,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => SpeakerListScreen(
                                isStakeMode: widget.isStakeMode,
                                currentUser: widget.currentUser,
                              ),
                            ),
                          ),
                        ),
                        _buildCategoryCard(
                          title: 'Himnos',
                          icon: Icons.library_music,
                          color: Colors.indigo.shade600,
                          isMobile: isMobile,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => HymnListScreen(
                                isStakeMode: widget.isStakeMode,
                                currentUser: widget.currentUser,
                              ),
                            ),
                          ),
                        ),
                        _buildCategoryCard(
                          title: 'Entrevistas',
                          icon: Icons.people_alt,
                          color: Colors.teal.shade700,
                          isMobile: isMobile,
                          onTap: _mostrarPanelEntrevistas,
                        ),
                        _buildCategoryCard(
                          title: 'Presupuesto',
                          icon: Icons.account_balance_wallet,
                          color: Colors.purple.shade700,
                          isMobile: isMobile,
                          onTap: _mostrarPanelPresupuesto,
                        ),
                        _buildCategoryCard(
                          title: 'Compromisos',
                          icon: Icons.assignment_late,
                          color: Colors.orange.shade800,
                          badgeCount: _overdueCommitments?.length ?? 0,
                          isMobile: isMobile,
                          onTap: _mostrarPanelCompromisos,
                        ),
                        _buildCategoryCard(
                          title: 'Historia Familiar',
                          icon: Icons.family_restroom,
                          color: Colors.green.shade700,
                          isMobile: isMobile,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => FamilyHistoryReportScreen(
                                isStakeMode: widget.isStakeMode,
                                currentUser: widget.currentUser,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    int badgeCount = 0,
    required bool isMobile,
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
              padding: const EdgeInsets.all(12.0),
              child: isMobile
                  ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 36, color: color),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              )
                  : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 44, color: color),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      title,
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            if (badgeCount > 0)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                  child: Text(
                    '$badgeCount',
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

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
            const Text('Ocupación de Entrevistas (Mes Actual)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('$reserved Reservadas', style: TextStyle(fontWeight: FontWeight.bold, color: _brandBlue, fontSize: 16)),
                Text('$available Disponibles', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 15),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 14,
                backgroundColor: Colors.green.shade100,
                color: _brandBlue,
              ),
            ),
            const SizedBox(height: 25),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _brandBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.calendar_month),
                label: const Text('Gestionar Agenda de Entrevistas'),
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => InterviewsScreen(currentUser: widget.currentUser)));
                },
              ),
            ),
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
            const Text('Distribución de Solicitudes Financieras', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 25),
            SizedBox(
              height: 180,
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
                          if (value == 0) return const Text('Reembolsos', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12));
                          if (value == 1) return const Text('Adelantos', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12));
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
                    BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: reimbursements, color: Colors.blue.shade700, width: 40, borderRadius: BorderRadius.circular(6))]),
                    BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: advances, color: Colors.purple.shade700, width: 40, borderRadius: BorderRadius.circular(6))]),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 15),
            Text('Total Movilizado: S/ ${(reimbursements + advances).toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: BorderSide(color: _brandBlue),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: Icon(Icons.receipt_long, color: _brandBlue),
                label: Text('Ver Solicitudes de Presupuesto', style: TextStyle(color: _brandBlue, fontWeight: FontWeight.bold)),
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => BudgetListScreen(currentUser: widget.currentUser)));
                },
              ),
            ),
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
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.all(25),
          children: [
            const Text('Estado de Asignaciones y Compromisos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            const SizedBox(height: 20),
            SizedBox(
              height: 140,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 4,
                  centerSpaceRadius: 35,
                  sections: (completed + pending) == 0
                      ? [PieChartSectionData(color: Colors.grey.shade300, value: 1, title: '0', radius: 30)]
                      : [
                    PieChartSectionData(color: Colors.green.shade600, value: completed.toDouble(), title: '$completed', radius: 35, titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    PieChartSectionData(color: Colors.orange.shade700, value: pending.toDouble(), title: '$pending', radius: 35, titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _legendIndicator(Colors.green.shade600, 'Completados'),
                const SizedBox(width: 20),
                _legendIndicator(Colors.orange.shade700, 'Pendientes'),
              ],
            ),
            const Divider(height: 35, thickness: 1),
            Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.red.shade700),
                const SizedBox(width: 8),
                Text('Focos Rojos (Vencidos)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red.shade900)),
              ],
            ),
            const SizedBox(height: 10),
            if (_overdueCommitments == null || _overdueCommitments!.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 15),
                child: Text('Sin compromisos atrasados.', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
              )
            else
              ..._overdueCommitments!.map((item) {
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.error_outline, color: Colors.red.shade600),
                  title: Text(item['description'], maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  subtitle: Text('${item['responsible']} • ${item['topic']}', style: const TextStyle(fontSize: 11)),
                  trailing: Text('${item['daysLate']} d tarde', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red.shade900, fontSize: 12)),
                );
              }),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _brandBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => MyCommitmentsScreen(currentUser: widget.currentUser)));
              },
              child: const Text('Ir a Tablero de Compromisos'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _legendIndicator(Color color, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
      ],
    );
  }
}