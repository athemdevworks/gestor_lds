import 'package:flutter/material.dart';
import 'package:gestor_lds/features/auth/auth_service.dart';
import 'package:gestor_lds/features/auth/models/user_model.dart';
import 'package:gestor_lds/features/dashboard/screens/user_management_screen.dart';
import 'package:gestor_lds/features/meetings/screens/meetings_list_screen.dart';
import 'package:gestor_lds/features/commitments/screens/my_commitments_screen.dart';
import 'package:gestor_lds/features/auth/screens/profile_screen.dart';
import '../calendar/screens/calendar_screen.dart';

// --- NUEVO IMPORT PARA ACTIVIDADES ---
import 'package:gestor_lds/features/activities/screens/activities_screen.dart';
// -------------------------------------

class HomeScreen extends StatelessWidget {
  final UserModel user;

  const HomeScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    // Definimos qué tipo de módulos tendrá acceso el usuario
    final bool isAdmin = user.role == UserRole.bishopric;
    final bool isClerk = user.role == UserRole.clerk;
    // final bool isCouncil = user.role == UserRole.ward_council; // (Se usará después para filtros)

    // Obtenemos el nombre y rol para el saludo
    final String greeting = 'Bienvenido, ${user.nombres}';

    return Scaffold(
      appBar: AppBar(
        title: Text('GestorLDS - ${user.calling}'),
        actions: [
          // BOTÓN CALENDARIO GENERAL (Vista Mensual)
          IconButton(
            icon: const Icon(Icons.calendar_month),
            tooltip: 'Calendario Mensual',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CalendarScreen()),
              );
            },
          ),
          // Botón Mi Perfil
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
          // Botón Logout
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar Sesión',
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Cerrar Sesión'),
                  content: const Text('¿Estás seguro de que deseas salir?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: const Text('Cancelar'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        AuthService().signOut();
                      },
                      child: const Text('Salir'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Saludo
            Text(greeting, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const Divider(height: 30),

            // 3. MÓDULOS UNIVERSALES (Todos los activos)
            const Text('Módulos Principales', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),

            // --- AQUÍ ESTÁ EL BOTÓN DE ACTIVIDADES ---
            _buildModuleCard(context, Icons.local_activity, 'Calendario de Actividades', 'Ver y planificar actividades del barrio.'),
            // -----------------------------------------

            // 4. MÓDULOS POR ROL
            if (isAdmin || isClerk) ...[
              const Divider(height: 30),
              const Text('Gestión de Reuniones', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              _buildModuleCard(context, Icons.list_alt, 'Crear/Editar Agendas', 'Gestionar reuniones de Obispado y Consejo.'),
              _buildModuleCard(context, Icons.people, 'Revisar Compromisos', 'Ver todos los compromisos pendientes.'),
            ],

            // 5. MÓDULOS DE ADMINISTRACIÓN (Solo Obispado)
            if (isAdmin) ...[
              const Divider(height: 30),
              const Text('Administración', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.red)),
              _buildModuleCard(context, Icons.verified_user, 'Aprobar Usuarios', 'Gestionar y asignar roles a líderes nuevos.'),
            ],
          ],
        ),
      ),
    );
  }

  // Widget auxiliar para crear las tarjetas de módulo
  Widget _buildModuleCard(BuildContext context, IconData icon, String title, String subtitle) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: ListTile(
        leading: Icon(icon, size: 30, color: Theme.of(context).primaryColor),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {

          // --- LÓGICA DE NAVEGACIÓN ---
          if (title == 'Calendario de Actividades') {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const ActivitiesScreen()),
            );
          } else if (title == 'Crear/Editar Agendas') {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const MeetingsListScreen()),
            );
          } else if (title == 'Revisar Compromisos') {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => MyCommitmentsScreen(currentUser: user),
              ),
            );
          } else if (title == 'Aprobar Usuarios') {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const UserManagementScreen()),
            );
          }
        },
      ),
    );
  }
}