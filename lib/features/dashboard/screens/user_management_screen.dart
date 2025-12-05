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
          // CONFIGURACIÓN DE CONTRASTE
          labelColor: Colors.white,             // Icono/Texto SELECCIONADO (Blanco puro)
          unselectedLabelColor: Colors.white60, // Icono/Texto NO SELECCIONADO (Blanco con transparencia)
          indicatorColor: Colors.white,         // La rayita de abajo
          indicatorWeight: 3,                   // Un poco más gruesa para que se note
            tabs: [
              Tab(icon: Icon(Icons.person_add), text: 'Pendientes'),
              Tab(icon: Icon(Icons.people), text: 'Activos'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _UserList(status: 'pending'), // Pestaña 1
            _UserList(status: 'active'),  // Pestaña 2
          ],
        ),
      ),
    );
  }
}

// Widget interno para listar usuarios según su estado
class _UserList extends StatelessWidget {
  final String status;
  const _UserList({required this.status});

  @override
  Widget build(BuildContext context) {
    final UserService userService = UserService();

    return StreamBuilder<List<UserModel>>(
      stream: userService.streamUsersByStatus(status),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final users = snapshot.data ?? [];

        if (users.isEmpty) {
          return Center(child: Text('No hay usuarios $status'));
        }

        return ListView.builder(
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: status == 'pending' ? Colors.orange : Colors.indigo,
                  child: Text(user.nombres[0], style: const TextStyle(color: Colors.white)),
                ),
                title: Text('${user.apellidos}, ${user.nombres}'),
                subtitle: Text('${user.calling} (${user.role.name})'),
                trailing: const Icon(Icons.edit),
                onTap: () {
                  // Abrir diálogo de edición
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

// Diálogo para editar Rol, Estado y Llamamiento
class _EditUserDialog extends StatefulWidget {
  final UserModel user;
  const _EditUserDialog({required this.user});

  @override
  State<_EditUserDialog> createState() => _EditUserDialogState();
}

class _EditUserDialogState extends State<_EditUserDialog> {
  late UserRole _selectedRole;
  late String _selectedStatus;
  late TextEditingController _callingController;
  final UserService _userService = UserService();

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.user.role;
    _selectedStatus = widget.user.status;
    _callingController = TextEditingController(text: widget.user.calling);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Administrar Acceso'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Usuario: ${widget.user.nombres} ${widget.user.apellidos}'),
            const SizedBox(height: 20),

            // 1. EDITAR LLAMAMIENTO
            TextField(
              controller: _callingController,
              decoration: const InputDecoration(labelText: 'Llamamiento', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 15),

            // 2. CAMBIAR ESTADO (Aprobar/Suspender)
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Estado'),
              value: _selectedStatus,
              items: const [
                DropdownMenuItem(value: 'pending', child: Text('Pendiente (Sin Acceso)')),
                DropdownMenuItem(value: 'active', child: Text('Activo (Aprobado)')),
                DropdownMenuItem(value: 'suspended', child: Text('Suspendido')),
              ],
              onChanged: (v) => setState(() => _selectedStatus = v!),
            ),
            const SizedBox(height: 15),

            // 3. CAMBIAR ROL (Permisos)
            DropdownButtonFormField<UserRole>(
              decoration: const InputDecoration(labelText: 'Rol de Sistema'),
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
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        ElevatedButton(
          onPressed: () async {
            await _userService.updateUserAccess(
              widget.user.uid,
              _selectedRole,
              _selectedStatus,
              _callingController.text,
            );
            if (mounted) Navigator.pop(context);
          },
          child: const Text('Guardar Cambios'),
        ),
      ],
    );
  }
}