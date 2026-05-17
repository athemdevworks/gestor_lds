import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:gestor_lds/features/auth/services/auth_service.dart';
import 'package:gestor_lds/features/auth/models/user_model.dart';
import 'package:gestor_lds/features/auth/screens/user_management_screen.dart';
import 'package:gestor_lds/features/meetings/screens/meetings_list_screen.dart';
import 'package:gestor_lds/features/commitments/screens/my_commitments_screen.dart';
import 'package:gestor_lds/features/auth/screens/profile_screen.dart';
import '../../../core/constants/wards_list.dart';
import '../../budget/screens/budget_list_screen.dart';
import '../../calendar/screens/calendar_screen.dart';
import 'package:gestor_lds/features/activities/screens/activities_screen.dart';
import 'package:gestor_lds/features/interviews/screens/interviews_screen.dart';
import 'package:gestor_lds/features/communications/screens/document_generator_screen.dart';
import 'package:gestor_lds/features/members/screens/members_screen.dart';
import 'package:gestor_lds/features/dashboard/widgets/birthdays_card.dart';
import 'package:gestor_lds/features/statistics/screens/manager_dashboard_screen.dart';

import '../../family_history/screens/family_history_hub_screen.dart';

class HomeScreen extends StatefulWidget {
  final UserModel user;

  const HomeScreen({super.key, required this.user});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const Color _brandBlue = Color(0xFF22539A);

  // Control del interruptor de contexto
  bool _isEstacaView = false;

  @override
  void initState() {
    super.initState();
    // 🚀 INTELIGENCIA DE ARRANQUE: Si eres Admin o tu ficha dice "Estaca",
    // la app inicia por defecto en Modo Estaca para evitar bloqueos de barrio local.
    final String roleStr = widget.user.role.toString().toLowerCase();
    if (roleStr.contains('admin') || widget.user.ward == 'Estaca') {
      _isEstacaView = true;
    } else {
      _isEstacaView = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    // 🚀 ESCUDO DE ENUM: Limpiamos a minúsculas para interceptar 'UserRole.admin' o 'admin'
    final String role = widget.user.role.toString().toLowerCase();
    final String org = widget.user.organization.toString().toLowerCase();

    final List<dynamic> callingOrgs = widget.user.toMap()['callingOrganizations'] ?? [];
    final List<dynamic> callings = widget.user.toMap()['callings'] ?? [];

    // Definición blindada de privilegios administrativos
    final bool isGlobalAdmin = role.contains('admin');
    final bool isLocalAdmin = role.contains('obispado');

    // Control de extracción a prueba de fallos nulos para el llamamiento primario
    String primaryCallingStr = '';
    try {
      primaryCallingStr = widget.user.primaryCalling.toString().toLowerCase();
    } catch (_) {}

    // Detectamos si tiene derecho a usar el "Modo Estaca" (Sumo Consejo o Niveles Superiores)
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

    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isWideScreen = screenWidth > 900;

    Query radarQuery = FirebaseFirestore.instance
        .collection('users')
        .where('isApproved', isEqualTo: false)
        .where('isRegistered', isEqualTo: true);

    // Si no es el administrador absoluto del sistema, acota las solicitudes por su barrio
    if (!isGlobalAdmin) {
      radarQuery = radarQuery.where('ward', isEqualTo: widget.user.ward);
    }

    return PopScope(
        canPop: false,
        child: Scaffold(
          backgroundColor: const Color(0xFFEEF2F6),
          appBar: AppBar(
            backgroundColor: _brandBlue,
            leading: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Image.asset('assets/images/isotipo_stake.png', fit: BoxFit.contain),
            ),
            title: Image.asset('assets/images/glds-logo-hor.png', height: 35, fit: BoxFit.contain),
            centerTitle: true,
            actions: [
              // SWITCHER DE CONTEXTO ESTACA / BARRIO
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
                            onTap: () => _mostrarPanelAprobaciones(context, snapshot.data!.docs),
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                              child: Row(
                                children: [
                                  const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 28),
                                  const SizedBox(width: 12),
                                  Expanded(child: Text('$pendingCount Solicitud(es) de acceso pendiente(s)', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16))),
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

                const Text('MÓDULOS ACTIVOS', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _brandBlue, letterSpacing: 1.1)),
                const SizedBox(height: 12),

                _buildGridOrList(
                  isWideScreen,
                  children: [
                    // 🛡️ SECCIÓN MAESTRA: Solo visible para ti (El Administrador Global)
                    if (isGlobalAdmin) ...[
                      _DashboardCard(title: 'CALENDARIO', subtitle: 'Cronograma de actividades', icon: Icons.calendar_month, iconColor: Colors.deepPurple.shade600, textColor: Colors.black, onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => CalendarScreen(currentUser: widget.user)))),
                      _DashboardCard(title: 'ENTREVISTAS', subtitle: 'Gestión de citas y entrevistas', icon: Icons.upcoming, iconColor: Colors.teal.shade600, textColor: Colors.black, onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => InterviewsScreen(currentUser: widget.user)))),
                    ],

                    // 🌟 EL MÓDULO ESTRELLA: Visible para todo el universo de usuarios siempre
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
                                )
                            )
                        )
                    ),
                  ],
                ),

                // 🛡️ CONTROL DE REUNIONES SECUNDARIO: Exclusivo del Admin Global
                if (isGlobalAdmin) ...[
                  const SizedBox(height: 30),
                  const Text('GESTION DE REUNIONES', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _brandBlue, letterSpacing: 1.1)),
                  const SizedBox(height: 10),
                  _buildGridOrList(
                    isWideScreen,
                    children: [
                      _DashboardCard(title: 'ACTIVIDADES', subtitle: 'Organización y control de actividades', icon: Icons.local_activity, iconColor: Colors.orange.shade700, textColor: Colors.black, onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ActivitiesScreen(currentUser: widget.user)))),
                      _DashboardCard(title: 'AGENDAS', subtitle: 'Minutas y pautas de reunión', icon: Icons.edit_calendar, iconColor: Colors.blue.shade700, textColor: Colors.black, onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => MeetingsListScreen(currentUser: widget.user)))),
                      _DashboardCard(title: 'MIS COMPROMISOS', subtitle: 'Seguimiento de asignaciones', icon: Icons.task_alt, iconColor: Colors.green.shade700, textColor: Colors.black, onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => MyCommitmentsScreen(currentUser: widget.user)))),
                      _DashboardCard(title: 'PRESUPUESTO', subtitle: 'Control financiero y solicitudes', icon: Icons.monetization_on_outlined, iconColor: Colors.green.shade700, textColor: Colors.black, onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const BudgetListScreen()))),
                    ],
                  ),
                ],

                // 🛡️ ADMINISTRACIÓN GENERAL DE LA ESTACA: Exclusivo del Admin Global
                if (isGlobalAdmin) ...[
                  const SizedBox(height: 30),
                  const Text('ADMINISTRACION DE ESTACA', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _brandBlue, letterSpacing: 1.1)),
                  const SizedBox(height: 10),
                  _buildGridOrList(
                    isWideScreen,
                    children: [
                      _DashboardCard(title: 'REPORTES', subtitle: 'Panel de métricas y rendimiento', icon: Icons.pie_chart_rounded, iconColor: Colors.amber.shade700, textColor: Colors.black, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ManagerDashboardScreen(isStakeMode: isStakeModeActive, currentUser: widget.user)))),
                      _DashboardCard(title: 'USUARIOS', subtitle: 'Gestión de cuentas y permisos', icon: Icons.verified_user, iconColor: Colors.indigo.shade700, textColor: Colors.black, onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const UserManagementScreen()))),
                      _DashboardCard(title: 'COMUNICACIONES', subtitle: 'Citaciones y documentos oficiales', icon: Icons.campaign_rounded, iconColor: const Color(0xFF25D366), textColor: Colors.black, onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const DocumentGeneratorScreen()))),
                      _DashboardCard(title: 'DIRECTORIO GENERAL', subtitle: 'Base de datos de miembros', icon: Icons.people_alt_rounded, iconColor: Colors.deepOrange, textColor: Colors.black, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const MembersScreen()))),
                    ],
                  ),
                ],
                const SizedBox(height: 50),
              ],
            ),
          ),
        ));
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
      return Wrap(spacing: 20, runSpacing: 20, children: children.map((child) => SizedBox(width: 320, height: 110, child: child)).toList());
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
              child: const Text('Salir')
          ),
        ],
      ),
    );
  }

  void _mostrarPanelAprobaciones(BuildContext context, List<QueryDocumentSnapshot> pendingUsers) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(color: Color(0xFF22539A), borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
              child: const Row(
                children: [
                  Icon(Icons.shield, color: Colors.white),
                  SizedBox(width: 10),
                  Text('Aprobación de Accesos', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: pendingUsers.length,
                itemBuilder: (context, index) {
                  var userData = pendingUsers[index].data() as Map<String, dynamic>;
                  String uid = pendingUsers[index].id;
                  List<dynamic> rawCallings = userData['callings'] ?? ['Sin Llamamiento'];
                  String displayCalling = rawCallings.isNotEmpty ? rawCallings.first.toString() : 'Sin Llamamiento';

                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: CircleAvatar(backgroundColor: Colors.green.shade50, child: const Icon(Icons.person, color: Colors.green)),
                      title: Text('${userData['firstName']} ${userData['lastName']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('$displayCalling\n${userData['ward']}'),
                      isThreeLine: true,
                      trailing: ElevatedButton.icon(
                        icon: const Icon(Icons.check, size: 18),
                        label: const Text('Aprobar'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                        onPressed: () => _aprobarDirecto(context, uid),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _aprobarDirecto(BuildContext context, String uid) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({'isApproved': true});
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ ¡Usuario Aprobado Exitosamente!'), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al aprobar: $e'), backgroundColor: Colors.red));
      }
    }
  }

  void _showImportJsonDialog(BuildContext context) {
    final TextEditingController jsonController = TextEditingController();
    bool isImporting = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Importar Fichas (JSON)', style: TextStyle(fontWeight: FontWeight.bold)),
              content: SizedBox(
                width: 500,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Abre tu archivo import_arevalo.json, copia todo el texto y pégalo aquí abajo:', style: TextStyle(fontSize: 13, color: Colors.grey)),
                    const SizedBox(height: 10),
                    TextField(controller: jsonController, maxLines: 10, decoration: const InputDecoration(hintText: '[{"firstName": "Juan"...}]', border: OutlineInputBorder())),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: isImporting ? null : () => Navigator.pop(ctx), child: const Text('Cancelar', style: TextStyle(color: Colors.grey))),
                isImporting
                    ? const CircularProgressIndicator()
                    : ElevatedButton.icon(
                  icon: const Icon(Icons.upload),
                  label: const Text('Inyectar a Firebase'),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF22539A), foregroundColor: Colors.white),
                  onPressed: () async {
                    if (jsonController.text.trim().isEmpty) return;
                    setStateDialog(() => isImporting = true);
                    try {
                      List<dynamic> usersToImport = jsonDecode(jsonController.text.trim());
                      final batch = FirebaseFirestore.instance.batch();
                      final usersCollection = FirebaseFirestore.instance.collection('users');

                      for (var userMap in usersToImport) {
                        var newDocRef = usersCollection.doc();
                        batch.set(newDocRef, userMap);
                      }
                      await batch.commit();
                      if (context.mounted) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('✅ ¡${usersToImport.length} fichas importadas con éxito!'), backgroundColor: Colors.green));
                      }
                    } catch (e) {
                      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error en el JSON: $e'), backgroundColor: Colors.red));
                    } finally {
                      if (context.mounted) setStateDialog(() => isImporting = false);
                    }
                  },
                ),
              ],
            );
          }
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
      elevation: 10,
      shadowColor: Colors.black,
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
                      Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor), maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Text(subtitle, style: TextStyle(color: Colors.grey[600], fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
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