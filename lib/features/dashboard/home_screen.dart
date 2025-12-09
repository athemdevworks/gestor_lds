import 'package:flutter/material.dart';
import 'package:gestor_lds/features/auth/auth_service.dart';
import 'package:gestor_lds/features/auth/models/user_model.dart';
import 'package:gestor_lds/features/dashboard/screens/user_management_screen.dart';
import 'package:gestor_lds/features/meetings/screens/meetings_list_screen.dart';
import 'package:gestor_lds/features/commitments/screens/my_commitments_screen.dart';
import 'package:gestor_lds/features/auth/screens/profile_screen.dart';
import '../calendar/screens/calendar_screen.dart';
import 'package:gestor_lds/features/activities/screens/activities_screen.dart';

class HomeScreen extends StatelessWidget {
  final UserModel user;

  const HomeScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    // 1. DEFINICIÓN DE PERMISOS
    final bool isAdmin = user.role == UserRole.obispado;
    final bool isLeader = user.role == UserRole.lider;

    return Scaffold(
      appBar: AppBar(
        // 1. TEXTO DEL APP A LA IZQUIERDA
        title: const Text(
            'GESTORLDS',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)
        ),
        centerTitle: false, // Alineado a la izquierda

        // 2. LOGO AL CENTRO (Corregido: Sin Padding extra)
        flexibleSpace: SafeArea(
          child: Center(
            child: Image.asset(
              'assets/images/logont.png', // Asegúrate que este sea el path correcto
              height: 40, // Un poquito más grande para que luzca mejor centrado
              color: Colors.white, // Lo pintamos de blanco puro
              fit: BoxFit.contain, // Asegura que se vea completo
            ),
          ),
        ),

        // 3. ICONOS A LA DERECHA
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            tooltip: 'Calendario Mensual',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CalendarScreen(currentUser: user)),
              );
            },
          ),
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
            // --- CABECERA DE BIENVENIDA ---
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Saludo con Nombre y Apellido
                Text(
                    'Bienvenido, ${user.nombres} ${user.apellidos}',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)
                ),
                const SizedBox(height: 6),
                // 2. Llamamiento debajo (Destacado)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF164772).withOpacity(0.1), // Fondo azul muy suave
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFF164772).withOpacity(0.3)),
                  ),
                  child: Text(
                      user.calling,
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF164772) // Azul corporativo
                      )
                  ),
                ),
              ],
            ),
            // ------------------------------------

            const Divider(height: 30),

            const Text('Módulos Principales', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),

            _buildModuleCard(context, Icons.local_activity, 'Actividades', 'Ver y planificar actividades del barrio.'),

            if (isAdmin || isLeader) ...[
              const Divider(height: 30),
              const Text('Gestión de Reuniones', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              _buildModuleCard(context, Icons.list_alt, 'Crear/Editar Agendas', 'Gestionar reuniones de Obispado y Consejo.'),
              _buildModuleCard(context, Icons.people, 'Revisar Compromisos', 'Ver todos los compromisos pendientes.'),
            ],

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

  Widget _buildModuleCard(BuildContext context, IconData icon, String title, String subtitle) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: ListTile(
        leading: Icon(icon, size: 30, color: Theme.of(context).primaryColor),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          if (title == 'Actividades') {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const ActivitiesScreen()),
            );
          } else if (title == 'Crear/Editar Agendas') {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => MeetingsListScreen(currentUser: user)),
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