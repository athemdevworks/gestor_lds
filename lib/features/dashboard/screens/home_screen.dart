import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:gestor_lds/features/auth/services/auth_service.dart';
import 'package:gestor_lds/features/auth/models/user_model.dart';
import 'package:gestor_lds/features/meetings/screens/meetings_list_screen.dart';
import 'package:gestor_lds/features/commitments/screens/my_commitments_screen.dart';
import 'package:gestor_lds/features/auth/screens/profile_screen.dart';
import 'package:gestor_lds/features/admin/screens/module_settings_screen.dart';
import 'package:gestor_lds/features/budget/screens/budget_list_screen.dart';
import 'package:gestor_lds/features/calendar/screens/calendar_screen.dart';
import 'package:gestor_lds/features/activities/screens/activities_screen.dart';
import 'package:gestor_lds/features/interviews/screens/interviews_screen.dart';
import 'package:gestor_lds/features/communications/screens/document_generator_screen.dart';
import 'package:gestor_lds/features/members/screens/members_screen.dart';
import 'package:gestor_lds/features/dashboard/widgets/birthdays_card.dart';
import 'package:gestor_lds/features/statistics/screens/manager_dashboard_screen.dart';
import 'package:gestor_lds/features/family_history/screens/family_history_hub_screen.dart';

// Módulos Doctrinales
import 'package:gestor_lds/features/attendance/screens/attendance_screen.dart';
import 'package:gestor_lds/features/ministering/screens/ministering_screen.dart';
import 'package:gestor_lds/features/missionary_work/screens/missionary_work_screen.dart';

class HomeScreen extends StatefulWidget {
  final UserModel user;

  const HomeScreen({super.key, required this.user});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const Color _brandBlue = Color(0xFF22539A);

  bool _isEstacaView = false;

  @override
  void initState() {
    super.initState();
    final String roleStr = widget.user.role.toString().toLowerCase();
    if (roleStr.contains('admin') || widget.user.ward == 'Estaca') {
      _isEstacaView = true;
    } else {
      _isEstacaView = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final String role = widget.user.role.toString().toLowerCase();
    final String org = widget.user.organization.toString().toLowerCase();

    final List<dynamic> callingOrgs = widget.user.toMap()['callingOrganizations'] ?? [];
    final List<dynamic> callings = widget.user.toMap()['callings'] ?? [];

    final bool isGlobalAdmin = role.contains('admin');
    final bool isLocalAdmin = role.contains('obispado');

    String primaryCallingStr = '';
    try {
      primaryCallingStr = widget.user.primaryCalling.toString().toLowerCase();
    } catch (_) {}

    final bool hasStakePrivilege = isGlobalAdmin ||
        role.contains('presidencia_estaca') ||
        role.contains('lider_estaca') ||
        callingOrgs.any((o) => o.toString().toLowerCase().contains('sumo consejo')) ||
        callings.any((c) => c.toString().toLowerCase().contains('sumo consejo')) ||
        org.contains('estaca') ||
        primaryCallingStr.contains('estaca') ||
        primaryCallingStr.contains('sumo consejo');

    final bool isStakeModeActive = hasStakePrivilege && _isEstacaView;
    final bool canManageUsers = isGlobalAdmin || (isLocalAdmin && !_isEstacaView);
    final bool canAccessAdminTools = isGlobalAdmin || hasStakePrivilege || isLocalAdmin;

    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isWideScreen = screenWidth > 900;

    Query radarQuery = FirebaseFirestore.instance
        .collection('users')
        .where('isApproved', isEqualTo: false)
        .where('isRegistered', isEqualTo: true);

    if (!isGlobalAdmin) {
      radarQuery = radarQuery.where('ward', isEqualTo: widget.user.ward);
    }

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFFEEF2F6),
        appBar: AppBar(
          backgroundColor: _brandBlue,
          leading: isWideScreen
              ? Padding(
            padding: const EdgeInsets.all(10.0),
            child: Image.asset('assets/images/isotipo_stake.png', fit: BoxFit.contain),
          )
              : null,
          title: Image.asset('assets/images/glds-logo-hor.png', height: 35, fit: BoxFit.contain),
          centerTitle: true,
          actions: [
            if (hasStakePrivilege)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: TextButton.icon(
                  icon: Icon(
                    _isEstacaView ? Icons.visibility : Icons.visibility_off,
                    color: Colors.white,
                    size: 18,
                  ),
                  label: Text(
                    _isEstacaView ? 'Modo Estaca' : 'Modo Barrio',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  onPressed: () {
                    setState(() {
                      _isEstacaView = !_isEstacaView;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('👁️ Cambiando a vista de: ${_isEstacaView ? "ESTACA" : "BARRIO"}'),
                      duration: const Duration(seconds: 1),
                      backgroundColor: _isEstacaView ? _brandBlue : Colors.teal.shade700,
                    ));
                  },
                ),
              ),
            if (isGlobalAdmin)
              IconButton(
                icon: const Icon(Icons.upload_file),
                tooltip: 'Importar JSON',
                onPressed: () => _showImportJsonDialog(context),
              ),
            IconButton(
              icon: const Icon(Icons.account_circle),
              tooltip: 'Mi Perfil',
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => ProfileScreen(user: widget.user)));
              },
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Cerrar Sesión',
              onPressed: () => _showLogoutDialog(context),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWelcomeBanner(context, isStakeModeActive),

              // Radar de Aprobaciones de Cuentas Nuevas
              if (canManageUsers)
                StreamBuilder<QuerySnapshot>(
                  stream: radarQuery.snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const SizedBox(height: 30);
                    int pendingCount = snapshot.data!.docs.length;
                    return Padding(
                      padding: const EdgeInsets.only(top: 20, bottom: 10),
                      child: Material(
                        color: Colors.red.shade700,
                        borderRadius: BorderRadius.circular(12),
                        elevation: 4,
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => MembersScreen(
                                  isStakeMode: isStakeModeActive,
                                  currentUser: widget.user,
                                  initialTabIndex: 1, // Abre directamente en PENDIENTES
                                ),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                            child: Row(
                              children: [
                                const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 28),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    '$pendingCount Solicitud(es) de acceso pendiente(s)',
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                ),
                                const Icon(Icons.chevron_right, color: Colors.white),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              if (!canManageUsers) const SizedBox(height: 30),

              const SizedBox(height: 250, width: double.infinity, child: BirthdaysCard()),
              const SizedBox(height: 25),

              // =========================================================
              // 🚀 BLOQUE DE MÓDULOS CONECTADOS A ward_settings
              // =========================================================
              StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance.collection('ward_settings').doc(widget.user.ward).snapshots(),
                builder: (context, snapshot) {
                  final data = (snapshot.hasData && snapshot.data!.exists)
                      ? snapshot.data!.data() as Map<String, dynamic>
                      : <String, dynamic>{};

                  // 1. Obra de Salvación
                  bool historiaFamiliarActiva = data['historiaFamiliarActiva'] ?? true;
                  bool obraMisionalActiva = data['obraMisionalActiva'] ?? false;
                  bool ministracionActiva = data['ministracionActiva'] ?? false;
                  bool asistenciaActiva = data['asistenciaActiva'] ?? false;

                  // 2. Organización y Logística
                  bool calendarioActivo = data['calendarioActivo'] ?? true;
                  bool actividadesActivas = data['actividadesActivas'] ?? true;
                  bool entrevistasActivas = data['entrevistasActivas'] ?? true;
                  bool directorioActivo = data['directorioActivo'] ?? true;
                  bool presupuestoActivo = data['presupuestoActivo'] ?? false;
                  bool agendasActivas = data['agendasActivas'] ?? false;
                  bool compromisosActivos = data['compromisosActivos'] ?? false;

                  // 3. Administración y Reportes
                  bool reportesActivos = data['reportesActivos'] ?? false;
                  bool comunicacionesActivas = data['comunicacionesActivas'] ?? false;

                  // 🌟 PASE VIP: Admin Global o Vista de Estaca activa TODO
                  if (isGlobalAdmin || isStakeModeActive) {
                    historiaFamiliarActiva = true;
                    obraMisionalActiva = true;
                    ministracionActiva = true;
                    asistenciaActiva = true;

                    calendarioActivo = true;
                    actividadesActivas = true;
                    entrevistasActivas = true;
                    directorioActivo = true;
                    presupuestoActivo = true;
                    agendasActivas = true;
                    compromisosActivos = true;

                    reportesActivos = true;
                    comunicacionesActivas = true;
                  }

                  // Ensamblado reactivo de listas de tarjetas
                  final List<Widget> salvacionCards = [
                    if (historiaFamiliarActiva)
                      _DashboardCard(
                        title: 'HISTORIA FAMILIAR',
                        subtitle: 'Seguimiento de metas y reportes',
                        icon: Icons.account_tree_rounded,
                        iconColor: Colors.cyan.shade700,
                        textColor: Colors.black,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => FamilyHistoryHubScreen(
                              isStakeMode: isStakeModeActive,
                              currentUser: widget.user,
                            ),
                          ),
                        ),
                      ),
                    if (obraMisionalActiva)
                      _DashboardCard(
                        title: 'OBRA MISIONAL',
                        subtitle: 'Progreso de investigadores y conversos',
                        icon: Icons.public,
                        iconColor: Colors.indigo.shade600,
                        textColor: Colors.black,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => MissionaryWorkScreen(
                              isStakeMode: isStakeModeActive,
                              currentUser: widget.user,
                            ),
                          ),
                        ),
                      ),
                    if (ministracionActiva)
                      _DashboardCard(
                        title: 'MINISTRACIÓN',
                        subtitle: 'Compañerismos y entrevistas',
                        icon: Icons.handshake_outlined,
                        iconColor: Colors.teal.shade700,
                        textColor: Colors.black,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => MinisteringScreen(
                              isStakeMode: isStakeModeActive,
                              currentUser: widget.user,
                            ),
                          ),
                        ),
                      ),
                    if (asistenciaActiva)
                      _DashboardCard(
                        title: 'ASISTENCIA',
                        subtitle: 'Registro nominal dominical',
                        icon: Icons.fact_check_outlined,
                        iconColor: Colors.deepOrange.shade600,
                        textColor: Colors.black,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => AttendanceScreen(
                              isStakeMode: isStakeModeActive,
                              currentUser: widget.user,
                            ),
                          ),
                        ),
                      ),
                  ];

                  final List<Widget> logisticaCards = [
                    if (calendarioActivo)
                      _DashboardCard(
                        title: 'CALENDARIO',
                        subtitle: 'Cronograma de actividades',
                        icon: Icons.calendar_month,
                        iconColor: Colors.deepPurple.shade600,
                        textColor: Colors.black,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => CalendarScreen(currentUser: widget.user)),
                        ),
                      ),
                    if (actividadesActivas)
                      _DashboardCard(
                        title: 'ACTIVIDADES',
                        subtitle: 'Organización y control de actividades',
                        icon: Icons.local_activity,
                        iconColor: Colors.orange.shade700,
                        textColor: Colors.black,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => ActivitiesScreen(currentUser: widget.user)),
                        ),
                      ),
                    if (entrevistasActivas)
                      _DashboardCard(
                        title: 'ENTREVISTAS',
                        subtitle: 'Gestión de citas y entrevistas',
                        icon: Icons.upcoming,
                        iconColor: Colors.teal.shade600,
                        textColor: Colors.black,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => InterviewsScreen(currentUser: widget.user)),
                        ),
                      ),
                    if (directorioActivo)
                      _DashboardCard(
                        title: 'DIRECTORIO',
                        subtitle: isStakeModeActive ? 'Directorio de la estaca y gestión' : 'Directorio de miembros y llamamientos',
                        icon: Icons.people_alt_rounded,
                        iconColor: _brandBlue,
                        textColor: Colors.black,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => MembersScreen(
                              isStakeMode: isStakeModeActive,
                              currentUser: widget.user,
                            ),
                          ),
                        ),
                      ),
                    if (presupuestoActivo)
                      _DashboardCard(
                        title: 'PRESUPUESTO',
                        subtitle: 'Control financiero y solicitudes',
                        icon: Icons.monetization_on_outlined,
                        iconColor: Colors.green.shade700,
                        textColor: Colors.black,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => BudgetListScreen(currentUser: widget.user),
                            settings: const RouteSettings(name: '/budget-list'),
                          ),
                        ),
                      ),
                    if (agendasActivas)
                      _DashboardCard(
                        title: 'AGENDAS',
                        subtitle: 'Minutas y pautas de reunión',
                        icon: Icons.edit_calendar,
                        iconColor: Colors.blue.shade700,
                        textColor: Colors.black,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => MeetingsListScreen(
                              isStakeMode: isStakeModeActive,
                              currentUser: widget.user,
                            ),
                          ),
                        ),
                      ),
                    if (compromisosActivos)
                      _DashboardCard(
                        title: 'MIS COMPROMISOS',
                        subtitle: 'Seguimiento de asignaciones',
                        icon: Icons.task_alt,
                        iconColor: Colors.green.shade700,
                        textColor: Colors.black,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => MyCommitmentsScreen(currentUser: widget.user)),
                        ),
                      ),
                  ];

                  final List<Widget> adminCards = [
                    if (reportesActivos)
                      _DashboardCard(
                        title: 'REPORTES',
                        subtitle: 'Panel de métricas y rendimiento',
                        icon: Icons.pie_chart_rounded,
                        iconColor: Colors.amber.shade700,
                        textColor: Colors.black,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ManagerDashboardScreen(
                              isStakeMode: isStakeModeActive,
                              currentUser: widget.user,
                            ),
                          ),
                        ),
                      ),
                    if (comunicacionesActivas)
                      _DashboardCard(
                        title: 'COMUNICACIONES',
                        subtitle: 'Citaciones y documentos oficiales',
                        icon: Icons.campaign_rounded,
                        iconColor: const Color(0xFF25D366),
                        textColor: Colors.black,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => DocumentGeneratorScreen(
                              isStakeMode: isStakeModeActive,
                              currentUser: widget.user,
                            ),
                          ),
                        ),
                      ),
                    if (isGlobalAdmin)
                      _DashboardCard(
                        title: 'GESTOR DE MÓDULOS',
                        subtitle: 'Control de accesos y switches por barrio',
                        icon: Icons.toggle_on,
                        iconColor: Colors.deepOrange.shade600,
                        textColor: Colors.black,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const ModuleSettingsScreen()),
                        ),
                      ),
                  ];

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 🌟 1. OBRA DE SALVACIÓN Y EXALTACIÓN
                      if (salvacionCards.isNotEmpty) ...[
                        const Text(
                          'OBRA DE SALVACIÓN Y EXALTACIÓN',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _brandBlue, letterSpacing: 1.1),
                        ),
                        const SizedBox(height: 12),
                        _buildGridOrList(isWideScreen, children: salvacionCards),
                        const SizedBox(height: 30),
                      ],

                      // 📅 2. ORGANIZACIÓN Y LOGÍSTICA
                      if (logisticaCards.isNotEmpty) ...[
                        const Text(
                          'ORGANIZACIÓN Y LOGÍSTICA',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _brandBlue, letterSpacing: 1.1),
                        ),
                        const SizedBox(height: 12),
                        _buildGridOrList(isWideScreen, children: logisticaCards),
                        const SizedBox(height: 30),
                      ],

                      // ⚙️ 3. ADMINISTRACIÓN Y REPORTES
                      if (canAccessAdminTools && adminCards.isNotEmpty) ...[
                        const Text(
                          'ADMINISTRACIÓN Y REPORTES',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _brandBlue, letterSpacing: 1.1),
                        ),
                        const SizedBox(height: 12),
                        _buildGridOrList(isWideScreen, children: adminCards),
                        const SizedBox(height: 30),
                      ],
                    ],
                  );
                },
              ),
              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeBanner(BuildContext context, bool isEstacaMode) {
    String subTitle = isEstacaMode ? 'Vista de Líder de Estaca (Global)' : '${widget.user.primaryCalling} • ${widget.user.ward}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Theme.of(context).primaryColor, const Color(0xFF22539A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'BIENVENIDO, ${widget.user.firstName.toUpperCase()} ${widget.user.lastName.toUpperCase()}',
            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 5),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
            child: Text(
              subTitle,
              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridOrList(bool isWide, {required List<Widget> children}) {
    if (isWide) {
      return Wrap(
        spacing: 20,
        runSpacing: 20,
        children: children.map((child) => SizedBox(width: 320, height: 110, child: child)).toList(),
      );
    } else {
      return Column(children: children);
    }
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Estás seguro de que deseas salir?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.of(ctx).pop();
              AuthService().signOut();
            },
            child: const Text('Salir'),
          ),
        ],
      ),
    );
  }

  void _showImportJsonDialog(BuildContext context) {
    final TextEditingController jsonController = TextEditingController();
    bool isImporting = false;
    final double dialogWidth = MediaQuery.of(context).size.width * 0.9;

    showDialog(
      context: context,
      barrierDismissible: !isImporting,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: const Text('Importar Fichas (JSON)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            content: SizedBox(
              width: dialogWidth > 500 ? 500 : dialogWidth,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Pega aquí el contenido JSON de las fichas a importar:',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: jsonController,
                    maxLines: 8,
                    decoration: const InputDecoration(
                      hintText: '[{"firstName": "Juan"...}]',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isImporting ? null : () => Navigator.pop(ctx),
                child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
              ),
              isImporting
                  ? const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
              )
                  : ElevatedButton.icon(
                icon: const Icon(Icons.upload, size: 18),
                label: const Text('Inyectar a Firebase'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF22539A),
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  if (jsonController.text.trim().isEmpty) return;
                  setStateDialog(() => isImporting = true);
                  try {
                    List<dynamic> usersToImport = jsonDecode(jsonController.text.trim());
                    final usersCollection = FirebaseFirestore.instance.collection('users');

                    const int chunkSize = 400;
                    for (var i = 0; i < usersToImport.length; i += chunkSize) {
                      final batch = FirebaseFirestore.instance.batch();
                      final end = (i + chunkSize < usersToImport.length) ? i + chunkSize : usersToImport.length;
                      final chunk = usersToImport.sublist(i, end);

                      for (var userMap in chunk) {
                        var newDocRef = usersCollection.doc();
                        batch.set(newDocRef, userMap);
                      }
                      await batch.commit();
                    }

                    if (context.mounted) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('✅ ¡${usersToImport.length} fichas importadas con éxito!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error al importar: $e'), backgroundColor: Colors.red),
                      );
                    }
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final Color textColor;
  final VoidCallback onTap;

  const _DashboardCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isWide = MediaQuery.of(context).size.width > 900;
    const Color brandBlue = Color(0xFF22539A);

    return Card(
      color: Colors.white,
      surfaceTintColor: Colors.white,
      elevation: 4,
      shadowColor: Colors.black12,
      clipBehavior: Clip.hardEdge,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: isWide ? EdgeInsets.zero : const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: const BoxDecoration(border: Border(left: BorderSide(color: brandBlue, width: 6.0))),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: iconColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                  child: Icon(icon, size: 28, color: iconColor),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (!isWide) const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}