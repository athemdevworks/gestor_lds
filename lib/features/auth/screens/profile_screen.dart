import 'package:flutter/material.dart';
import 'package:gestor_lds/core/constants/callings_list.dart';
import 'package:gestor_lds/core/utils/alert_utils.dart';
import 'package:gestor_lds/features/auth/auth_service.dart';
import 'package:gestor_lds/features/auth/models/user_model.dart';
import 'package:gestor_lds/features/auth/services/user_service.dart';

class ProfileScreen extends StatefulWidget {
  final UserModel user;

  const ProfileScreen({super.key, required this.user});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nombresController;
  late TextEditingController _apellidosController;

  // Variables para los Dropdowns
  late String _fixedOrganization; // <-- AHORA ES FIJA
  String? _selectedCalling;

  final UserService _userService = UserService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nombresController = TextEditingController(text: widget.user.nombres);
    _apellidosController = TextEditingController(text: widget.user.apellidos);

    // Fijamos la organización actual (NO SE PUEDE CAMBIAR AQUÍ)
    _fixedOrganization = widget.user.organization;

    // Validamos si el llamamiento actual es válido
    if (kLdsStructure.containsKey(_fixedOrganization)) {
      final validCallings = kLdsStructure[_fixedOrganization]!;
      if (validCallings.contains(widget.user.calling)) {
        _selectedCalling = widget.user.calling;
      }
    }
  }

  @override
  void dispose() {
    _nombresController.dispose();
    _apellidosController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate() && _selectedCalling != null) {
      setState(() => _isLoading = true);
      try {
        // Solo actualizamos Nombre, Apellido y Llamamiento.
        // La Organización y el Rol NO se tocan (seguridad).
        await _userService.updateUserProfile(
          uid: widget.user.uid,
          nombres: _nombresController.text.trim(),
          apellidos: _apellidosController.text.trim(),
          calling: _selectedCalling!,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Perfil actualizado correctamente.')),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) showErrorDialog(context, 'Error', e.toString());
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  void _requestPasswordChange() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cambiar Contraseña'),
        content: Text('Se enviará un enlace a ${widget.user.email} para que puedas crear una nueva contraseña segura.\n\n¿Deseas continuar?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await AuthService().sendPasswordResetEmail(widget.user.email);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Correo enviado. Revisa tu bandeja de entrada.')),
                  );
                }
              } catch (e) {
                if (mounted) showErrorDialog(context, 'Error', e.toString());
              }
            },
            child: const Text('Enviar Correo'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Obtenemos SOLO los llamamientos de la organización FIJA del usuario
    final List<String> callings = kLdsStructure[_fixedOrganization] ?? [];

    return Scaffold(
      appBar: AppBar(title: const Text('Mi Perfil')),
      backgroundColor: Colors.grey[50],
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // TARJETA DE USUARIO
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          child: Text(
                            widget.user.nombres.isNotEmpty ? widget.user.nombres[0].toUpperCase() : '?',
                            style: const TextStyle(fontSize: 32, color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(widget.user.email, style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                        const SizedBox(height: 5),

                        // Badge de Rol
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Text(
                            widget.user.role.name.toUpperCase(),
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blue.shade800),
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(_fixedOrganization, style: const TextStyle(fontStyle: FontStyle.italic)),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // FORMULARIO BLINDADO
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text('Editar Información', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const Divider(height: 30),

                          TextFormField(
                            controller: _nombresController,
                            decoration: const InputDecoration(labelText: 'Nombres', border: OutlineInputBorder()),
                            validator: (v) => v!.isEmpty ? 'Requerido' : null,
                          ),
                          const SizedBox(height: 15),

                          TextFormField(
                            controller: _apellidosController,
                            decoration: const InputDecoration(labelText: 'Apellidos', border: OutlineInputBorder()),
                            validator: (v) => v!.isEmpty ? 'Requerido' : null,
                          ),
                          const SizedBox(height: 15),

                          // --- ORGANIZACIÓN (SOLO LECTURA / BLOQUEADO) ---
                          TextFormField(
                            initialValue: _fixedOrganization,
                            readOnly: true, // No se puede escribir
                            enabled: false, // Se ve gris para indicar que es fijo
                            decoration: const InputDecoration(
                              labelText: 'Organización (Fija)',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.lock_outline),
                              helperText: 'Contacta al Admin para cambiar de organización',
                            ),
                          ),
                          const SizedBox(height: 15),

                          // Dropdown Llamamiento (Limitado a su organización)
                          DropdownButtonFormField<String>(
                            value: _selectedCalling,
                            decoration: const InputDecoration(labelText: 'Llamamiento', border: OutlineInputBorder()),
                            items: callings.map<DropdownMenuItem<String>>((String c) {
                              return DropdownMenuItem<String>(value: c, child: Text(c));
                            }).toList(),
                            onChanged: (val) => setState(() => _selectedCalling = val),
                          ),

                          const SizedBox(height: 30),

                          _isLoading
                              ? const Center(child: CircularProgressIndicator())
                              : ElevatedButton.icon(
                            onPressed: _saveProfile,
                            icon: const Icon(Icons.save),
                            label: const Text('Guardar Cambios'),
                            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
                          ),

                          const SizedBox(height: 20),
                          const Divider(),
                          const SizedBox(height: 10),

                          TextButton.icon(
                            onPressed: _requestPasswordChange,
                            icon: const Icon(Icons.lock_reset, color: Colors.grey),
                            label: const Text('Enviar correo para cambiar contraseña', style: TextStyle(color: Colors.grey)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}