import 'package:flutter/material.dart';
import 'package:gestor_lds/features/auth/models/user_model.dart';
import 'package:gestor_lds/features/auth/services/user_service.dart';

class UserManagementScreen extends StatelessWidget {
  const UserManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Administración de Usuarios'),
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            tabs: [
              Tab(icon: Icon(Icons.person_add), text: 'Pendientes'),
              Tab(icon: Icon(Icons.people), text: 'Aprobados'), // Texto cambiado
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            // Pasamos un booleano en lugar de un string
            _UserList(showApproved: false), // Pestaña 1: Pendientes (isApproved: false)
            _UserList(showApproved: true),  // Pestaña 2: Activos (isApproved: true)
          ],
        ),
      ),
    );
  }
}

// Widget interno para listar usuarios
class _UserList extends StatelessWidget {
  final bool showApproved; // <-- CAMBIO: bool en vez de String

  const _UserList({required this.showApproved});

  @override
  Widget build(BuildContext context) {
    final UserService userService = UserService();

    return StreamBuilder<List<UserModel>>(
      // Llama al nuevo método del servicio que filtra por booleano
      stream: userService.streamUsersByApproval(showApproved),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final users = snapshot.data ?? [];

        if (users.isEmpty) {
          return Center(child: Text(showApproved ? 'No hay usuarios activos.' : 'No hay solicitudes pendientes.'));
        }

        return ListView.builder(
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: !showApproved ? Colors.orange : Colors.indigo,
                  child: Text(
                      user.nombres.isNotEmpty ? user.nombres[0] : '?',
                      style: const TextStyle(color: Colors.white)
                  ),
                ),
                title: Text('${user.apellidos}, ${user.nombres}'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.calling),
                    Text(
                        user.role.name.toUpperCase(),
                        style: TextStyle(fontSize: 10, color: Colors.grey[600], fontWeight: FontWeight.bold)
                    ),
                  ],
                ),
                trailing: const Icon(Icons.edit),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (_) => _EditUserDialog(user: user),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}

// Diálogo para editar Rol, Aprobación y Llamamiento
class _EditUserDialog extends StatefulWidget {
  final UserModel user;
  const _EditUserDialog({required this.user});

  @override
  State<_EditUserDialog> createState() => _EditUserDialogState();
}

class _EditUserDialogState extends State<_EditUserDialog> {
  late UserRole _selectedRole;
  late bool _isApproved; // <-- CAMBIO: bool
  late TextEditingController _callingController;
  final UserService _userService = UserService();

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.user.role;
    _isApproved = widget.user.isApproved; // <-- CAMBIO
    _callingController = TextEditingController(text: widget.user.calling);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Administrar Acceso'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Usuario: ${widget.user.nombres} ${widget.user.apellidos}', style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 5),
                Text('Org: ${widget.user.organization}', style: const TextStyle(fontStyle: FontStyle.italic)),
                const SizedBox(height: 20),

                // 1. EDITAR LLAMAMIENTO
                TextField(
                  controller: _callingController,
                  decoration: const InputDecoration(labelText: 'Llamamiento', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 15),

                // 2. CAMBIAR ESTADO (Aprobado SI/NO)
                DropdownButtonFormField<bool>(
                  decoration: const InputDecoration(labelText: 'Estado de Acceso', border: OutlineInputBorder()),
                  value: _isApproved,
                  items: const [
                    DropdownMenuItem(value: false, child: Text('Pendiente (Sin Acceso)')),
                    DropdownMenuItem(value: true, child: Text('Activo (Aprobado)')),
                  ],
                  onChanged: (v) => setState(() => _isApproved = v!),
                ),
                const SizedBox(height: 15),

                // 3. CAMBIAR ROL (Permisos)
                DropdownButtonFormField<UserRole>(
                  decoration: const InputDecoration(labelText: 'Rol de Sistema', border: OutlineInputBorder()),
                  value: _selectedRole,
                  items: UserRole.values.map((role) {
                    return DropdownMenuItem(
                      value: role,
                      child: Text(role.name.toUpperCase()),
                    );
                  }).toList(),
                  onChanged: (v) => setState(() => _selectedRole = v!),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        ElevatedButton(
          onPressed: () async {
            // Llamamos al método actualizado del servicio
            await _userService.updateUserAccess(
              uid: widget.user.uid,
              role: _selectedRole,
              isApproved: _isApproved, // <-- Pasamos el booleano
              calling: _callingController.text,
            );
            if (mounted) Navigator.pop(context);
          },
          child: const Text('Guardar Cambios'),
        ),
      ],
    );
  }
}