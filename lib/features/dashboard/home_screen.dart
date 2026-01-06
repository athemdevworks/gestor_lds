import 'package:flutter/material.dart';
import 'package:gestor_lds/features/auth/auth_service.dart';
import 'package:gestor_lds/features/auth/models/user_model.dart';
import 'package:gestor_lds/features/dashboard/screens/user_management_screen.dart';
import 'package:gestor_lds/features/meetings/screens/meetings_list_screen.dart';
import 'package:gestor_lds/features/commitments/screens/my_commitments_screen.dart';
import 'package:gestor_lds/features/auth/screens/profile_screen.dart';
import '../calendar/screens/calendar_screen.dart';
import 'package:gestor_lds/features/activities/screens/activities_screen.dart';
import 'package:gestor_lds/features/interviews/screens/interviews_screen.dart';
import 'package:gestor_lds/features/communications/screens/whatsapp_sender_screen.dart';

class HomeScreen extends StatelessWidget {
  final UserModel user;

  const HomeScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final bool isAdmin = user.role == UserRole.obispado;
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
          // NOTA: Quité el icono de calendario de aquí porque ya está como Módulo Principal
          IconButton(
            icon: const Icon(Icons.account_circle),
            tooltip: 'Mi Perfil',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ProfileScreen(user: user)),
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

            // SECCIÓN 1: MÓDULOS PRINCIPALES (Ahora Calendario y Entrevistas)
            const Text(
                'MODULOS PRINCIPALES',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: brandBlue)
            ),
            const SizedBox(height: 10),

            _buildGridOrList(
              isWideScreen,
              children: [
                // --- CALENDARIO (Movido aquí) ---
                _DashboardCard(
                  title: 'CALENDARIO',
                  subtitle: 'Eventos del mes',
                  icon: Icons.calendar_month,
                  iconColor: Colors.deepPurple.shade600,
                  textColor: Colors.black,
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => CalendarScreen(currentUser: user))),
                ),
                // --- ENTREVISTAS (Futuro) ---
                _DashboardCard(
                  title: 'ENTREVISTAS',
                  subtitle: 'Mis citas con el Obispo',
                  icon: Icons.upcoming,
                  iconColor: Colors.teal.shade600,
                  textColor: Colors.black,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => InterviewsScreen(currentUser: user)),
                    );                  },
                ),
              ],
            ),

            // SECCIÓN 2: GESTIÓN DE REUNIONES (Actividades + Agendas + Compromisos)
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
                  // --- ACTIVIDADES (Movido aquí) ---
                  _DashboardCard(
                    title: 'ACTIVIDADES',
                    subtitle: 'Planificación anual',
                    icon: Icons.local_activity,
                    iconColor: Colors.orange.shade700,
                    textColor: Colors.black,
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ActivitiesScreen())),
                  ),
                  _DashboardCard(
                    title: 'AGENDAS',
                    subtitle: 'Consejo y Obispado',
                    icon: Icons.edit_calendar,
                    iconColor: Colors.blue.shade700,
                    textColor: Colors.black,
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => MeetingsListScreen(currentUser: user))),
                  ),
                  _DashboardCard(
                    title: 'COMPROMISOS',
                    subtitle: 'Mis tareas pendientes',
                    icon: Icons.task_alt,
                    iconColor: Colors.green.shade700,
                    textColor: Colors.black,
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => MyCommitmentsScreen(currentUser: user))),
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
                    title: 'DIRECTORIO',
                    subtitle: 'Aprobar y editar usuarios',
                    icon: Icons.verified_user,
                    iconColor: Colors.indigo.shade700,
                    textColor: Colors.black,
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const UserManagementScreen())),
                  ),
                  // --- COMUNICACIONES (Nuevo Módulo) ---
                  _DashboardCard(
                    title: 'COMUNICACIONES',
                    subtitle: 'Enviar citas por WhatsApp',
                    icon: Icons.send_to_mobile,
                    iconColor: const Color(0xFF25D366), // Verde WhatsApp
                    textColor: Colors.black,
                    onTap: () {
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const WhatsAppSenderScreen()));
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