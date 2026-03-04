import 'package:flutter/material.dart';
import 'package:gestor_lds/features/auth/auth_service.dart';
import 'package:gestor_lds/features/auth/models/user_model.dart';
import 'package:gestor_lds/features/dashboard/screens/user_management_screen.dart';
import 'package:gestor_lds/features/meetings/screens/meetings_list_screen.dart';
import 'package:gestor_lds/features/commitments/screens/my_commitments_screen.dart';
import 'package:gestor_lds/features/auth/screens/profile_screen.dart';
import '../budget/screens/budget_list_screen.dart';
import '../calendar/screens/calendar_screen.dart';
import 'package:gestor_lds/features/activities/screens/activities_screen.dart';
import 'package:gestor_lds/features/interviews/screens/interviews_screen.dart';
import 'package:gestor_lds/features/communications/screens/document_generator_screen.dart';
import 'package:gestor_lds/features/members/screens/members_screen.dart';
import 'package:gestor_lds/features/dashboard//widgets/birthdays_card.dart';
import 'package:gestor_lds/features/statistics/screens/manager_dashboard_screen.dart';

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

    return Scaffold(
      backgroundColor: const Color(0xFFEEF2F6), // Fondo Gris Suave

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
                  // 👇 AGREGADO: Ruta web para Perfil
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
            const SizedBox(height: 30),

            //Cumpleaños
            SizedBox(
              height: 250, // Altura para la lista de cumples
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
                        // 👇 AGREGADO: Ruta web para Calendario
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
                        // 👇 AGREGADO: Ruta web para Entrevistas
                        settings: const RouteSettings(name: '/interviews'),
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
                        // 👇 AGREGADO: Ruta web para Actividades
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
                          // 👇 AGREGADO: Ruta web para Agendas
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
                          // 👇 AGREGADO: Ruta web para Compromisos
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
                          // 👇 AGREGADO: Ruta web para Presupuesto
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
                          // 👇 AGREGADO: Ruta web para Estadísticas
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
                          // 👇 AGREGADO: Ruta web para Usuarios
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
                            // 👇 AGREGADO: Ruta web para Comunicaciones
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
                          // 👇 AGREGADO: Ruta web para Directorio
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
    );
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
            'BIENVENIDO, ${user.nombres.toUpperCase()} ${user.apellidos.toUpperCase()}',
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