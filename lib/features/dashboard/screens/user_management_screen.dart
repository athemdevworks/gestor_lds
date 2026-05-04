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
  final Color _brandBlue = const Color(0xFF164772); // 🚀 Color corporativo unificado

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEF2F6), // 🚀 Fondo unificado
      appBar: AppBar(
        title: const Text('Directorio de Accesos', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: _brandBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: 'PENDIENTES', icon: Icon(Icons.person_add_alt_1)),
            Tab(text: 'APROBADOS', icon: Icon(Icons.admin_panel_settings)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // PESTAÑA 1: PENDIENTES (showApproved = false)
          _UserList(showApproved: false, brandColor: _brandBlue),

          // PESTAÑA 2: APROBADOS (showApproved = true)
          _UserList(showApproved: true, brandColor: _brandBlue),
        ],
      ),
    );
  }
}

// --- WIDGET INTERNO: LISTA DE USUARIOS ---
class _UserList extends StatelessWidget {
  final bool showApproved;
  final Color brandColor;

  const _UserList({required this.showApproved, required this.brandColor});

  Future<void> _launchWhatsApp(BuildContext context, String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final uri = Uri.parse("https://wa.me/51$cleanPhone"); // 🚀 Asumimos +51 como en members_screen
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw 'No se pudo abrir WhatsApp';
      }
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No se pudo abrir WhatsApp', style: TextStyle(color: Colors.white)), backgroundColor: Colors.red));
    }
  }

  Future<void> _launchCall(BuildContext context, String phone) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phone);
    try {
      await launchUrl(launchUri);
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No se pudo realizar la llamada', style: TextStyle(color: Colors.white)), backgroundColor: Colors.red));
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
                Icon(showApproved ? Icons.verified_user_outlined : Icons.inbox_outlined, size: 80, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text(
                  showApproved ? 'Directorio de accesos vacío.' : 'No hay solicitudes pendientes.',
                  style: TextStyle(color: Colors.grey[600], fontSize: 16),
                ),
              ],
            ),
          );
        }

        final users = snapshot.data!;

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            final hasPhone = user.phoneNumber != null && user.phoneNumber!.trim().isNotEmpty;

            String displaySubtitle = user.organization;
            if (user.calling.isNotEmpty && user.calling != 'Ninguno') {
              displaySubtitle = '${user.calling} • $displaySubtitle';
            }

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: 2,
              shadowColor: Colors.black12,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: CircleAvatar(
                  radius: 24,
                  backgroundColor: !showApproved ? Colors.orange.shade50 : brandColor.withOpacity(0.1),
                  child: Text(
                    user.firstName.isNotEmpty ? user.firstName.substring(0, 1).toUpperCase() : '?',
                    style: TextStyle(
                      color: !showApproved ? Colors.orange.shade800 : brandColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                title: Text(
                    '${user.firstName} ${user.lastName}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(
                      displaySubtitle,
                      style: TextStyle(
                        color: user.isActive ? Colors.grey[700] : Colors.red,
                        fontWeight: user.isActive ? FontWeight.normal : FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(4)),
                          child: Text(
                              user.role.name.toUpperCase(),
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade800)
                          ),
                        ),
                        if (hasPhone) ...[
                          const SizedBox(width: 8),
                          Icon(Icons.phone_android, size: 12, color: Colors.grey[500]),
                          const SizedBox(width: 2),
                          Text(user.phoneNumber!, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                        ],
                        // 🚀 Indicador visual de inactividad
                        if (!user.isActive) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(4)),
                            child: const Text('BLOQUEADO', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.red)),
                          ),
                        ]
                      ],
                    )
                  ],
                ),
                // 🚀 BOTONERÍA TÁCTICA
                trailing: !showApproved
                    ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.check_circle, color: Colors.green, size: 28),
                      onPressed: () => userService.updateUserAccess(
                        uid: user.uid,
                        role: user.role,
                        isApproved: true,
                        calling: user.calling,
                        phoneNumber: user.phoneNumber,
                      ),
                      tooltip: 'Aprobar',
                    ),
                    IconButton(
                      icon: const Icon(Icons.cancel, color: Colors.red, size: 28),
                      onPressed: () => _showDeleteConfirm(context, user, userService),
                      tooltip: 'Rechazar',
                    ),
                  ],
                )
                    : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (hasPhone) IconButton(icon: const Icon(Icons.message, color: Color(0xFF25D366)), onPressed: () => _launchWhatsApp(context, user.phoneNumber!), tooltip: 'WhatsApp'),
                    if (hasPhone) IconButton(icon: const Icon(Icons.phone, color: Colors.blue), onPressed: () => _launchCall(context, user.phoneNumber!), tooltip: 'Llamar'),
                    IconButton(
                      icon: const Icon(Icons.edit_document, color: Colors.grey),
                      tooltip: 'Editar Permisos',
                      onPressed: () => showDialog(
                        context: context,
                        builder: (_) => _EditUserDialog(user: user, brandColor: brandColor),
                      ),
                    ),
                  ],
                ),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Rechazar Solicitud', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('¿Deseas eliminar definitivamente la solicitud de acceso de ${user.firstName}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              service.deleteUser(user.uid);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}

// --- DIÁLOGO DE EDICIÓN ---
class _EditUserDialog extends StatefulWidget {
  final UserModel user;
  final Color brandColor;

  const _EditUserDialog({required this.user, required this.brandColor});

  @override
  State<_EditUserDialog> createState() => _EditUserDialogState();
}

class _EditUserDialogState extends State<_EditUserDialog>{
  final UserService _userService = UserService();
  late UserRole _selectedRole;
  late bool _isApproved;
  late bool _isActive;
  late TextEditingController _callingController;
  late TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.user.role;
    _isApproved = widget.user.isApproved;
    _isActive = widget.user.isActive;
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), // 🚀 Dialog más limpio
      title: Text('Permisos de ${widget.user.firstName}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _callingController,
                decoration: const InputDecoration(labelText: 'Llamamiento / Asignación', border: OutlineInputBorder(), prefixIcon: Icon(Icons.badge), isDense: true),
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Celular / WhatsApp', border: OutlineInputBorder(), prefixIcon: Icon(Icons.phone), isDense: true),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 15),
              if (_selectedRole == UserRole.admin)
                TextFormField(
                  initialValue: 'ADMINISTRADOR (Sistema)',
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'Rol',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.security, color: Colors.red),
                    helperText: 'El rol de Admin es fijo.',
                    fillColor: Colors.grey.shade100,
                    filled: true,
                    isDense: true,
                  ),
                )
              else
                DropdownButtonFormField<UserRole>(
                  decoration: const InputDecoration(labelText: 'Nivel de Acceso (Rol)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.vpn_key), isDense: true),
                  value: _selectedRole,
                  items: UserRole.values
                      .where((r) => r != UserRole.admin)
                      .map((r) => DropdownMenuItem(
                      value: r,
                      child: Text(r.name.toUpperCase())
                  ))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedRole = v!),
                ),
              const SizedBox(height: 20),

              // 🚀 Switches visualmente más limpios
              Container(
                decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('Registro Aprobado', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      value: _isApproved,
                      activeColor: widget.brandColor,
                      onChanged: (val) => setState(() => _isApproved = val),
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      title: Text(_isActive ? 'Cuenta Activa' : 'Cuenta Bloqueada', style: TextStyle(color: _isActive ? Colors.green.shade700 : Colors.red.shade700, fontWeight: FontWeight.bold, fontSize: 14)),
                      subtitle: const Text('Desactiva para denegar acceso a la app.', style: TextStyle(fontSize: 11)),
                      value: _isActive,
                      activeColor: Colors.green,
                      inactiveThumbColor: Colors.red,
                      inactiveTrackColor: Colors.red.shade100,
                      onChanged: (val) => setState(() => _isActive = val),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar', style: TextStyle(color: Colors.grey))),
        ElevatedButton.icon(
          icon: const Icon(Icons.save, size: 18),
          label: const Text('Guardar'),
          style: ElevatedButton.styleFrom(backgroundColor: widget.brandColor, foregroundColor: Colors.white),
          onPressed: () async {
            await _userService.updateUserAccess(
              uid: widget.user.uid,
              role: _selectedRole,
              isApproved: _isApproved,
              isActive: _isActive,
              calling: _callingController.text,
              phoneNumber: _phoneController.text.trim(),
            );
            if (mounted) Navigator.pop(context);
          },
        ),
      ],
    );
  }
}