import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // 🚀 IMPORTANTE: Agregado para el Radar

import 'package:gestor_lds/features/auth/auth_service.dart';
import 'package:gestor_lds/features/auth/models/user_model.dart';
import 'package:gestor_lds/features/dashboard/screens/user_management_screen.dart';
import 'package:gestor_lds/features/meetings/screens/meetings_list_screen.dart';
import 'package:gestor_lds/features/commitments/screens/my_commitments_screen.dart';
import 'package:gestor_lds/features/auth/screens/profile_screen.dart';
// 👇 AGREGADO: Import de la nueva pantalla de Historia Familiar
import 'package:gestor_lds/features/family_history/screens/historia_familiar_screen.dart';
import '../../core/constants/wards_list.dart';
import '../budget/screens/budget_list_screen.dart';
import '../calendar/screens/calendar_screen.dart';
import 'package:gestor_lds/features/activities/screens/activities_screen.dart';
import 'package:gestor_lds/features/interviews/screens/interviews_screen.dart';
import 'package:gestor_lds/features/communications/screens/document_generator_screen.dart';
import 'package:gestor_lds/features/members/screens/members_screen.dart';
import 'package:gestor_lds/features/dashboard/widgets/birthdays_card.dart';
import 'package:gestor_lds/features/statistics/screens/manager_dashboard_screen.dart';

import '../members/services/member_service.dart';

class HomeScreen extends StatelessWidget {
  final UserModel user;

  const HomeScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final bool isAdmin = user.role == UserRole.obispado|| user.role == UserRole.admin;
    final bool isLeader = user.role == UserRole.lider;

    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 700;
    final bool isWideScreen = screenWidth > 900;

    // Color Azul Institucional
    const Color brandBlue = Color(0xFF164772);

    return PopScope(
        canPop: false,
        child: Scaffold(
          backgroundColor: const Color(0xFFEEF2F6),

          appBar: AppBar(
            title: isMobile
                ? Image.asset(
              'assets/images/logont.png',
              height: 35,
              color: Colors.white,
              fit: BoxFit.contain,
              alignment: Alignment.centerLeft,
            )
                : const Text(
              'GestorLDS',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            centerTitle: false,
            flexibleSpace: isMobile
                ? null
                : SafeArea(
              child: Center(
                child: Image.asset(
                  'assets/images/logont.png',
                  height: 45,
                  color: Colors.white,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.account_circle),
                tooltip: 'Mi Perfil',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProfileScreen(user: user),
                      settings: const RouteSettings(name: '/profile'),
                    ),
                  );
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
                _buildWelcomeBanner(context),

                // ==========================================================
                // 🚀 EL RADAR: ALERTA DE SOLICITUDES PENDIENTES
                // ==========================================================
                if (isAdmin)
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .where('isApproved', isEqualTo: false)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const SizedBox(height: 30); // Espacio normal si no hay pendientes
                      }

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
                if (!isAdmin) const SizedBox(height: 30),
                // ==========================================================


              // BOTÓN PARA IMPORTAR
                /*ElevatedButton.icon(
                  icon: const Icon(Icons.cloud_upload),
                  label: const Text('⚠️ Importar Directorio LCR (JSON)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  onPressed: () {
                    _mostrarDialogoDeImportacion(context);
                  },
                ),
                const SizedBox(height: 20),*/



                //Cumpleaños
                const SizedBox(
                  height: 250,
                  width: double.infinity,
                  child: BirthdaysCard(),
                ),
                const SizedBox(height: 20),

                // SECCIÓN 1: MÓDULOS PRINCIPALES
                const Text(
                    'MODULOS PRINCIPALES',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: brandBlue)
                ),
                const SizedBox(height: 10),

                _buildGridOrList(
                  isWideScreen,
                  children: [
                    // --- CALENDARIO ---
                    _DashboardCard(
                      title: 'CALENDARIO',
                      subtitle: 'Cronograma de actividades del barrio',
                      icon: Icons.calendar_month,
                      iconColor: Colors.deepPurple.shade600,
                      textColor: Colors.black,
                      onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => CalendarScreen(currentUser: user),
                            settings: const RouteSettings(name: '/calendar'),
                          )
                      ),
                    ),
                    // --- ENTREVISTAS ---
                    _DashboardCard(
                      title: 'ENTREVISTAS',
                      subtitle: 'Gestión de citas y entrevistas',
                      icon: Icons.upcoming,
                      iconColor: Colors.teal.shade600,
                      textColor: Colors.black,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => InterviewsScreen(currentUser: user),
                            settings: const RouteSettings(name: '/interviews'),
                          ),
                        );
                      },
                    ),
                    // 👇 AGREGADO: --- HISTORIA FAMILIAR ---
                    _DashboardCard(
                      title: 'HISTORIA FAMILIAR',
                      subtitle: 'Seguimiento de metas y progreso',
                      icon: Icons.account_tree_rounded,
                      iconColor: Colors.cyan.shade700,
                      textColor: Colors.black,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => HistoriaFamiliarScreen(currentUser: user),
                            settings: const RouteSettings(name: '/family_history'),
                          ),
                        );
                      },
                    ),
                  ],
                ),

                // SECCIÓN 2: GESTIÓN DE REUNIONES
                if (isAdmin || isLeader) ...[
                  const SizedBox(height: 30),
                  const Text(
                      'GESTION DE REUNIONES',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: brandBlue)
                  ),
                  const SizedBox(height: 10),

                  _buildGridOrList(
                    isWideScreen,
                    children: [
                      // --- ACTIVIDADES ---
                      _DashboardCard(
                        title: 'ACTIVIDADES',
                        subtitle: 'Organización y control de actividades',
                        icon: Icons.local_activity,
                        iconColor: Colors.orange.shade700,
                        textColor: Colors.black,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ActivitiesScreen(currentUser: user),
                            settings: const RouteSettings(name: '/activities'),
                          ),
                        ),
                      ),
                      _DashboardCard(
                        title: 'AGENDAS',
                        subtitle: 'Minutas y pautas de reunión',
                        icon: Icons.edit_calendar,
                        iconColor: Colors.blue.shade700,
                        textColor: Colors.black,
                        onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => MeetingsListScreen(currentUser: user),
                              settings: const RouteSettings(name: '/meetings'),
                            )
                        ),
                      ),
                      _DashboardCard(
                        title: 'MIS COMPROMISOS',
                        subtitle: 'Seguimiento de asignaciones',
                        icon: Icons.task_alt,
                        iconColor: Colors.green.shade700,
                        textColor: Colors.black,
                        onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => MyCommitmentsScreen(currentUser: user),
                              settings: const RouteSettings(name: '/commitments'),
                            )
                        ),
                      ),
                      _DashboardCard(
                        title: 'PRESUPUESTO',
                        subtitle: 'Control financiero y solicitudes',
                        icon: Icons.monetization_on_outlined,
                        iconColor: Colors.green.shade700,
                        textColor: Colors.black,
                        onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const BudgetListScreen(),
                              settings: const RouteSettings(name: '/budget'),
                            )
                        ),
                      ),
                    ],
                  ),
                ],

                // SECCIÓN 3: ADMINISTRACIÓN
                if (isAdmin) ...[
                  const SizedBox(height: 30),
                  const Text(
                      'ADMINISTRACION',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: brandBlue)
                  ),
                  const SizedBox(height: 10),

                  _buildGridOrList(
                    isWideScreen,
                    children: [
                      _DashboardCard(
                        title: 'ESTADISTICAS',
                        subtitle: 'Panel de métricas y rendimiento',
                        icon: Icons.pie_chart_rounded,
                        iconColor: Colors.amber.shade700,
                        textColor: Colors.black,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ManagerDashboardScreen(),
                              settings: const RouteSettings(name: '/statistics'),
                            ),
                          );
                        },
                      ),
                      _DashboardCard(
                        title: 'USUARIOS',
                        subtitle: 'Gestión de cuentas y permisos',
                        icon: Icons.verified_user,
                        iconColor: Colors.indigo.shade700,
                        textColor: Colors.black,
                        onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const UserManagementScreen(),
                              settings: const RouteSettings(name: '/users'),
                            )
                        ),
                      ),
                      // --- COMUNICACIONES ---
                      _DashboardCard(
                        title: 'COMUNICACIONES',
                        subtitle: 'Citaciones y documentos oficiales',
                        icon: Icons.campaign_rounded,
                        iconColor: const Color(0xFF25D366),
                        textColor: Colors.black,
                        onTap: () {
                          Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const DocumentGeneratorScreen(),
                                settings: const RouteSettings(name: '/communications'),
                              )
                          );
                        },
                      ),

                      _DashboardCard(
                        title: 'DIRECTORIO',
                        subtitle: 'Base de datos del barrio',
                        icon: Icons.people_alt_rounded,
                        iconColor: Colors.deepOrange,
                        textColor: Colors.black,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const MembersScreen(),
                              settings: const RouteSettings(name: '/members'),
                            ),
                          );
                        },
                      ),

                    ],
                  ),
                ],

                const SizedBox(height: 50),
              ],
            ),
          ),
        ));
  }

  // --- WIDGETS AUXILIARES ---

  Widget _buildWelcomeBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Theme.of(context).primaryColor, const Color(0xFF164772)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'BIENVENIDO, ${user.firstName.toUpperCase()} ${user.lastName.toUpperCase()}',
            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 5),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              user.calling,
              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
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
        children: children.map((child) {
          return SizedBox(
            width: 320,
            height: 110,
            child: child,
          );
        }).toList(),
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

  // 🚀 LA NUEVA JUGADA: POP-UP PARA ELEGIR EL BARRIO ANTES DE IMPORTAR
  void _mostrarDialogoDeImportacion(BuildContext context) {
    String? _barrioSeleccionado;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                title: const Row(
                  children: [
                    Icon(Icons.file_upload, color: Colors.deepOrange),
                    SizedBox(width: 10),
                    Text('Importar JSON', style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Selecciona a qué Barrio pertenece la lista de miembros que vas a importar:'),
                    const SizedBox(height: 20),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Barrio de Destino',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.location_city),
                        isDense: true,
                      ),
                      items: kWardsList.map((w) => DropdownMenuItem(value: w, child: Text(w))).toList(),
                      onChanged: (val) => setState(() => _barrioSeleccionado = val),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancelar', style: TextStyle(color: Colors.grey))
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrange, foregroundColor: Colors.white),
                    onPressed: () async {
                      if (_barrioSeleccionado == null) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Por favor, selecciona un barrio'), backgroundColor: Colors.orange));
                        return;
                      }

                      Navigator.pop(ctx); // Cerramos el pop-up

                      // 1. Avisamos que el proceso empezó
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Importando miembros para $_barrioSeleccionado...')));

                      try {
                        // 2. Ejecutamos el script enviando el barrio por parámetro
                        await MemberService().importarBarrioDesdeJson(barrioDestino: _barrioSeleccionado!);

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ ¡Importación Exitosa!'), backgroundColor: Colors.green));
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ Error: $e'), backgroundColor: Colors.red));
                        }
                      }
                    },
                    child: const Text('Importar Ahora'),
                  ),
                ],
              );
            }
        );
      },
    );
  }


  // ==========================================================
  // 🚀 PANEL INFERIOR PARA APROBACIONES
  // ==========================================================
  void _mostrarPanelAprobaciones(BuildContext context, List<QueryDocumentSnapshot> pendingUsers) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFF164772),
                borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
              ),
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

                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.orange.shade100,
                        child: const Icon(Icons.person_outline, color: Colors.orange),
                      ),
                      title: Text('${userData['firstName']} ${userData['lastName']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('${userData['email']}\nBarrio: ${userData['ward']}'),
                      isThreeLine: true,
                      trailing: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                        onPressed: () {
                          Navigator.pop(context); // Cerramos la lista
                          // Abrimos el buscador para vincular
                          showDialog(
                            context: context,
                            builder: (context) => _LinkMemberDialog(
                              userUid: uid,
                              userEmail: userData['email'],
                              userFullName: '${userData['firstName']} ${userData['lastName']}',
                              userWard: userData['ward'],
                            ),
                          );
                        },
                        child: const Text('Vincular'),
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
}

// ==========================================================
// 🚀 EL DIÁLOGO MÁGICO DE VINCULACIÓN
// ==========================================================
class _LinkMemberDialog extends StatefulWidget {
  final String userUid;
  final String userEmail;
  final String userFullName;
  final String userWard;

  const _LinkMemberDialog({
    required this.userUid,
    required this.userEmail,
    required this.userFullName,
    required this.userWard,
  });

  @override
  State<_LinkMemberDialog> createState() => _LinkMemberDialogState();
}

class _LinkMemberDialogState extends State<_LinkMemberDialog> {
  String _searchQuery = '';
  String _selectedRole = 'miembro';
  bool _isLoading = false;

  final List<String> _roles = ['miembro', 'lider', 'obispado', 'admin'];

  Future<void> _aprobarYVincular(String memberId, Map<String, dynamic> memberData) async {
    setState(() => _isLoading = true);
    try {
      // 1. Actualizamos el Usuario (Le damos acceso, rol y el ID oficial)
      await FirebaseFirestore.instance.collection('users').doc(widget.userUid).update({
        'isApproved': true,
        'role': _selectedRole,
        'memberId': memberId,
        'calling': memberData['calling'] ?? 'Sin llamamiento',
      });

      // 2. Actualizamos el Directorio Oficial
      await FirebaseFirestore.instance.collection('members').doc(memberId).update({
        'relatedUserId': widget.userUid,
        'email': widget.userEmail,
      });

      if (mounted) {
        Navigator.pop(context); // Cierra el modal
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ ¡Usuario Aprobado y Vinculado Exitosamente!'), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Vincular a ${widget.userFullName}'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('1. Asignar Nivel de Permiso:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedRole,
              decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
              items: _roles.map((r) => DropdownMenuItem(value: r, child: Text(r.toUpperCase()))).toList(),
              onChanged: (val) => setState(() => _selectedRole = val!),
            ),
            const SizedBox(height: 20),
            Text('2. Buscar en el directorio de ${widget.userWard}:', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              decoration: const InputDecoration(
                hintText: 'Ej: Apellido, Nombre',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
            ),
            const SizedBox(height: 15),

            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('members')
                    .where('ward', isEqualTo: widget.userWard)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                  var members = snapshot.data!.docs.where((doc) {
                    var data = doc.data() as Map<String, dynamic>;
                    String fullName = "${data['lastName']} ${data['firstName']}".toLowerCase();
                    return fullName.contains(_searchQuery);
                  }).toList();

                  if (members.isEmpty) return const Center(child: Text('No se encontraron miembros con ese nombre.'));

                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: members.length,
                    itemBuilder: (context, index) {
                      var data = members[index].data() as Map<String, dynamic>;
                      bool alreadyLinked = data.containsKey('relatedUserId') && data['relatedUserId'] != null;

                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text("${data['lastName']}, ${data['firstName']}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        subtitle: Text(data['calling'] ?? 'Sin llamamiento', style: const TextStyle(fontSize: 12)),
                        trailing: alreadyLinked
                            ? const Icon(Icons.link_off, color: Colors.red)
                            : _isLoading
                            ? const CircularProgressIndicator()
                            : IconButton(
                          icon: const Icon(Icons.check_circle, color: Colors.green, size: 30),
                          onPressed: () => _aprobarYVincular(members[index].id, data),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
      ],
    );
  }
}

// --- TARJETA DEFINITIVA ---
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
    const Color brandBlue = Color(0xFF164772);

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
          decoration: const BoxDecoration(
            border: Border(
              left: BorderSide(
                color: brandBlue,
                width: 6.0,
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
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
                if (!isWide)
                  const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}