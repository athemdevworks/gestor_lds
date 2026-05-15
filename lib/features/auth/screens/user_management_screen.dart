import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
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
    const brandBlue = Color(0xFF22539A);

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
            // 🚀 Actualizado a user.phone
            final hasPhone = user.phone != null && user.phone!.isNotEmpty;

            // 🚀 Tomamos la primera organización de servicio, o mostramos su clase base si no tiene
            final displayOrg = user.callingOrganizations.isNotEmpty && user.callingOrganizations.first != 'Ninguna'
                ? user.callingOrganizations.first
                : user.organization;

            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: !showApproved ? Colors.orange.shade100 : Colors.blue.shade100,
                child: Text(
                  user.firstName.substring(0, 1).toUpperCase(),
                  style: TextStyle(
                    color: !showApproved ? Colors.orange.shade800 : Colors.blue.shade800,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: Text('${user.firstName} ${user.lastName}', style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 🚀 Usamos primaryCalling y displayOrg
                  Text('${user.primaryCalling} • $displayOrg'),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(4)),
                        child: Text(user.role.name.toUpperCase().replaceAll('_', ' '), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                      if (hasPhone) ...[
                        const SizedBox(width: 8),
                        Icon(Icons.phone_android, size: 12, color: Colors.grey[600]),
                        const SizedBox(width: 2),
                        Text(user.phone!, style: TextStyle(fontSize: 11, color: Colors.grey[600])), // 🚀 Actualizado a user.phone
                      ]
                    ],
                  )
                ],
              ),

              trailing: !showApproved
                  ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.check_circle, color: Colors.green),
                    onPressed: () => userService.updateUserAccess(
                      uid: user.uid,
                      role: user.role,
                      isApproved: true,
                      // 🚀 Pasamos las listas intactas
                      callings: user.callings,
                      callingOrganizations: user.callingOrganizations,
                      phone: user.phone,
                    ),
                    tooltip: 'Aprobar',
                  ),
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
                  if (hasPhone) IconButton(icon: const Icon(Icons.message, color: Colors.green), onPressed: () => _launchWhatsApp(context, user.phone!), tooltip: 'WhatsApp'),
                  if (hasPhone) IconButton(icon: const Icon(Icons.phone, color: Colors.blue), onPressed: () => _launchCall(context, user.phone!), tooltip: 'Llamar'),
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
    // ... (Se mantiene igual)
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rechazar Solicitud'),
        content: Text('¿Deseas eliminar la solicitud de ${user.firstName}?'),
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

// --- DIÁLOGO DE EDICIÓN COMPLETO ---
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

  // 🚀 Controladores para las listas (separadas por coma)
  late TextEditingController _callingsController;
  late TextEditingController _callingOrgsController;
  late TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.user.role;
    _isApproved = widget.user.isApproved;
    // 🚀 Mostramos las listas unidas por comas
    _callingsController = TextEditingController(text: widget.user.callings.join(', '));
    _callingOrgsController = TextEditingController(text: widget.user.callingOrganizations.join(', '));
    _phoneController = TextEditingController(text: widget.user.phone ?? '');
  }

  @override
  void dispose() {
    _callingsController.dispose();
    _callingOrgsController.dispose();
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
                controller: _callingsController,
                decoration: const InputDecoration(
                    labelText: 'Llamamientos',
                    border: OutlineInputBorder(),
                    helperText: 'Separa múltiples con comas (Ej: Obispo, Organista)'
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _callingOrgsController,
                decoration: const InputDecoration(
                    labelText: 'Área de Servicio (Filtros)',
                    border: OutlineInputBorder(),
                    helperText: 'Ej: Obispado, Música'
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Celular', border: OutlineInputBorder(), prefixIcon: Icon(Icons.phone)),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 15),
              DropdownButtonFormField<UserRole>(
                decoration: const InputDecoration(labelText: 'Nivel de Permiso', border: OutlineInputBorder()),
                value: _selectedRole,
                items: UserRole.values.map((r) => DropdownMenuItem(value: r, child: Text(r.name.toUpperCase().replaceAll('_', ' ')))).toList(),
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
            // 🚀 Convertimos los textos separados por coma de vuelta a List<String>
            List<String> newCallings = _callingsController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
            List<String> newOrgs = _callingOrgsController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

            // Si lo dejan vacío, le ponemos valores por defecto
            if (newCallings.isEmpty) newCallings = ['Sin Llamamiento'];
            if (newOrgs.isEmpty) newOrgs = ['Ninguna'];

            await _userService.updateUserAccess(
              uid: widget.user.uid,
              role: _selectedRole,
              isApproved: _isApproved,
              callings: newCallings,         // 🚀 Pasamos la lista
              callingOrganizations: newOrgs, // 🚀 Pasamos la lista
              phone: _phoneController.text.trim(),
            );
            if (mounted) Navigator.pop(context);
          },
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}