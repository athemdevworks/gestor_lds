import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; // Asegúrate de tener esta dependencia
import 'package:gestor_lds/features/auth/models/user_model.dart';
import 'package:gestor_lds/features/auth/services/user_service.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    const brandBlue = Color(0xFF164772);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Directorio y Accesos'),
        backgroundColor: brandBlue,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: 'PENDIENTES', icon: Icon(Icons.person_add)),
            Tab(text: 'DIRECTORIO', icon: Icon(Icons.people_alt)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          // PESTAÑA 1: PENDIENTES (showApproved = false)
          _UserList(showApproved: false),

          // PESTAÑA 2: APROBADOS (showApproved = true)
          _UserList(showApproved: true),
        ],
      ),
    );
  }
}

// --- WIDGET INTERNO: LISTA DE USUARIOS ---
class _UserList extends StatelessWidget {
  final bool showApproved;
  const _UserList({required this.showApproved});

  Future<void> _launchWhatsApp(BuildContext context, String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final uri = Uri.parse("https://wa.me/$cleanPhone");
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw 'No se pudo abrir WhatsApp';
      }
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No se pudo abrir WhatsApp')));
    }
  }

  Future<void> _launchCall(BuildContext context, String phone) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phone);
    try {
      await launchUrl(launchUri);
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No se pudo realizar la llamada')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final UserService userService = UserService();

    return StreamBuilder<List<UserModel>>(
      // 1. USAMOS EL STREAM UNIFICADO DEL NUEVO SERVICIO
      stream: userService.streamUsersByApproval(showApproved),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(showApproved ? Icons.folder_open : Icons.person_off, size: 60, color: Colors.grey[300]),
                const SizedBox(height: 10),
                Text(
                  showApproved ? 'El directorio está vacío.' : 'No hay solicitudes pendientes.',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        final users = snapshot.data!;

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: users.length,
          separatorBuilder: (_, __) => const Divider(),
          itemBuilder: (context, index) {
            final user = users[index];
            final hasPhone = user.phoneNumber != null && user.phoneNumber!.isNotEmpty;

            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: !showApproved ? Colors.orange.shade100 : Colors.blue.shade100,
                child: Text(
                  user.nombres.substring(0, 1).toUpperCase(),
                  style: TextStyle(
                    color: !showApproved ? Colors.orange.shade800 : Colors.blue.shade800,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: Text('${user.nombres} ${user.apellidos}', style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${user.calling} • ${user.organization}'),
                  Row(
                    children: [
                      // Rol (Chip pequeño)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(4)),
                        child: Text(user.role.toString().split('.').last.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                      // Teléfono (si tiene)
                      if (hasPhone) ...[
                        const SizedBox(width: 8),
                        Icon(Icons.phone_android, size: 12, color: Colors.grey[600]),
                        const SizedBox(width: 2),
                        Text(user.phoneNumber!, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                      ]
                    ],
                  )
                ],
              ),

              // ACCIONES
              trailing: !showApproved
                  ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // BOTÓN APROBAR
                  IconButton(
                    icon: const Icon(Icons.check_circle, color: Colors.green),
                    onPressed: () => userService.updateUserAccess(
                      uid: user.uid,
                      role: user.role,
                      isApproved: true, // <--- AQUÍ APROBAMOS
                      calling: user.calling,
                      phoneNumber: user.phoneNumber,
                    ),
                    tooltip: 'Aprobar',
                  ),
                  // BOTÓN RECHAZAR
                  IconButton(
                    icon: const Icon(Icons.cancel, color: Colors.red),
                    onPressed: () => _showDeleteConfirm(context, user, userService),
                    tooltip: 'Rechazar',
                  ),
                ],
              )
                  : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // BOTONES DE CONTACTO (Solo si está aprobado)
                  if (hasPhone) IconButton(icon: const Icon(Icons.message, color: Colors.green), onPressed: () => _launchWhatsApp(context, user.phoneNumber!), tooltip: 'WhatsApp'),
                  if (hasPhone) IconButton(icon: const Icon(Icons.phone, color: Colors.blue), onPressed: () => _launchCall(context, user.phoneNumber!), tooltip: 'Llamar'),

                  // BOTÓN EDITAR
                  IconButton(
                    icon: const Icon(Icons.edit_note, color: Colors.grey),
                    onPressed: () => showDialog(
                      context: context,
                      builder: (_) => _EditUserDialog(user: user),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showDeleteConfirm(BuildContext context, UserModel user, UserService service) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rechazar Solicitud'),
        content: Text('¿Deseas eliminar la solicitud de ${user.nombres}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              service.deleteUser(user.uid);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}

// --- DIÁLOGO DE EDICIÓN COMPLETO (Rol, Llamamiento, Teléfono) ---
class _EditUserDialog extends StatefulWidget {
  final UserModel user;
  const _EditUserDialog({required this.user});

  @override
  State<_EditUserDialog> createState() => _EditUserDialogState();
}

class _EditUserDialogState extends State<_EditUserDialog> {
  final UserService _userService = UserService();
  late UserRole _selectedRole;
  late bool _isApproved;
  late TextEditingController _callingController;
  late TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.user.role;
    _isApproved = widget.user.isApproved;
    _callingController = TextEditingController(text: widget.user.calling);
    _phoneController = TextEditingController(text: widget.user.phoneNumber ?? '');
  }

  @override
  void dispose() {
    _callingController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Editar Usuario'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _callingController,
                decoration: const InputDecoration(labelText: 'Llamamiento', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Celular', border: OutlineInputBorder(), prefixIcon: Icon(Icons.phone)),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 15),
              DropdownButtonFormField<UserRole>(
                decoration: const InputDecoration(labelText: 'Rol', border: OutlineInputBorder()),
                value: _selectedRole,
                items: UserRole.values.map((r) => DropdownMenuItem(value: r, child: Text(r.toString().split('.').last.toUpperCase()))).toList(),
                onChanged: (v) => setState(() => _selectedRole = v!),
              ),
              const SizedBox(height: 15),
              DropdownButtonFormField<bool>(
                decoration: const InputDecoration(labelText: 'Estado', border: OutlineInputBorder()),
                value: _isApproved,
                items: const [
                  DropdownMenuItem(value: false, child: Text('Pendiente / Bloqueado')),
                  DropdownMenuItem(value: true, child: Text('Activo (Aprobado)')),
                ],
                onChanged: (v) => setState(() => _isApproved = v!),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        ElevatedButton(
          onPressed: () async {
            // 2. USAMOS LA NUEVA FUNCIÓN DE ACTUALIZACIÓN MASIVA
            await _userService.updateUserAccess(
              uid: widget.user.uid,
              role: _selectedRole,
              isApproved: _isApproved,
              calling: _callingController.text,
              phoneNumber: _phoneController.text.trim(),
            );
            if (mounted) Navigator.pop(context);
          },
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}