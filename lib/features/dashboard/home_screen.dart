import 'package:flutter/material.dart';
import 'package:gestor_lds/features/auth/auth_service.dart';
import 'package:gestor_lds/features/auth/models/user_model.dart';
import 'package:gestor_lds/features/dashboard/screens/user_management_screen.dart';
import 'package:gestor_lds/features/meetings/screens/meetings_list_screen.dart';
import 'package:gestor_lds/features/commitments/screens/my_commitments_screen.dart';
import 'package:gestor_lds/features/auth/screens/profile_screen.dart';

class HomeScreen extends StatelessWidget {
  // 1. Añadimos el objeto UserModel como parámetro requerido
  final UserModel user;

  const HomeScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    // Definimos qué tipo de módulos tendrá acceso el usuario
    final bool isAdmin = user.role == UserRole.bishopric;
    final bool isClerk = user.role == UserRole.clerk;
    final bool isCouncil = user.role == UserRole.ward_council;

    // Obtenemos el nombre y rol para el saludo
    final String greeting = 'Bienvenido, ${user.nombres}';
    final String roleText = user.role.name.toUpperCase();

    return Scaffold(
      appBar: AppBar(
        title: Text('GestorLDS - ${user.calling}'), // Título basado en el llamamiento
        actions: [
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
            onPressed: () async {
              await AuthService().signOut();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Saludo y Rol
            Text(greeting, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const Divider(height: 30),

            // 3. MÓDULOS UNIVERSALES (Todos los activos)
            const Text('Módulos Principales', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            _buildModuleCard(context, Icons.calendar_today, 'Calendario de Actividades', 'Ver el calendario de actividades del barrio.'),

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
          if (title == 'Crear/Editar Agendas') {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const MeetingsListScreen()),
            );
          } else if (title == 'Revisar Compromisos') {
            // NAVEGACIÓN NUEVA:
            Navigator.of(context).push(
              MaterialPageRoute(
                // Pasamos el usuario actual (que ya tenemos en HomeScreen)
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