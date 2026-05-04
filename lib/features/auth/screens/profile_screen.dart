import 'package:flutter/material.dart';
import 'package:gestor_lds/core/utils/alert_utils.dart';
import 'package:gestor_lds/features/auth/auth_service.dart';
import 'package:gestor_lds/features/auth/models/user_model.dart';
import 'package:gestor_lds/features/auth/services/user_service.dart';
import 'package:gestor_lds/core/utils/avatar_colors.dart';
import 'package:intl/intl.dart';

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
  late TextEditingController _phoneController;
  late TextEditingController _callingController; // 🚀 Reemplazamos el Dropdown por este controlador

  late String _fixedOrganization;
  DateTime? _selectedBirthDate;

  final UserService _userService = UserService();
  bool _isLoading = false;

  final Color _brandBlue = const Color(0xFF164772); // 🚀 Color Institucional

  @override
  void initState() {
    super.initState();
    _nombresController = TextEditingController(text: widget.user.firstName);
    _apellidosController = TextEditingController(text: widget.user.lastName);
    _phoneController = TextEditingController(text: widget.user.phoneNumber ?? '');
    _callingController = TextEditingController(text: widget.user.calling); // 🚀 Inicializamos con el texto actual

    _selectedBirthDate = widget.user.birthDate;
    _fixedOrganization = widget.user.organization;
  }

  @override
  void dispose() {
    _nombresController.dispose();
    _apellidosController.dispose();
    _phoneController.dispose();
    _callingController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {

      if (_selectedBirthDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Por favor indica tu fecha de nacimiento', style: TextStyle(color: Colors.white)), backgroundColor: Colors.orange));
        return;
      }

      setState(() => _isLoading = true);
      try {
        await _userService.updateUserProfile(
          uid: widget.user.uid,
          nombres: _nombresController.text.trim(),
          apellidos: _apellidosController.text.trim(),
          calling: _callingController.text.trim().isEmpty ? 'Pendiente' : _callingController.text.trim(), // 🚀 Guardamos el texto libre
          phoneNumber: _phoneController.text.trim(),
          birthDate: _selectedBirthDate,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ Perfil actualizado correctamente.'), backgroundColor: Colors.green),
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
            style: ElevatedButton.styleFrom(backgroundColor: _brandBlue, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await AuthService().sendPasswordResetEmail(widget.user.email);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Correo enviado. Revisa tu bandeja de entrada.'), backgroundColor: Colors.blue),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Perfil', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: _brandBlue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFEEF2F6), // Fondo unificado con el resto de la app
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // ==========================================
                // TARJETA DE USUARIO (FICHA TÉCNICA)
                // ==========================================
                Card(
                  elevation: 4,
                  shadowColor: Colors.black12,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 45,
                          backgroundColor: AvatarColors.getColor(widget.user.firstName),
                          child: Text(
                            widget.user.firstName.isNotEmpty ? widget.user.firstName[0].toUpperCase() : '?',
                            style: const TextStyle(fontSize: 36, color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(widget.user.email, style: TextStyle(color: Colors.grey[600], fontSize: 16)),

                        if (widget.user.phoneNumber != null && widget.user.phoneNumber!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.phone, size: 18, color: _brandBlue),
                                const SizedBox(width: 6),
                                Text(widget.user.phoneNumber!, style: TextStyle(color: Colors.grey[800], fontWeight: FontWeight.bold, fontSize: 15)),
                              ],
                            ),
                          ),

                        if (widget.user.birthDate != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 6.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.cake, size: 18, color: _brandBlue),
                                const SizedBox(width: 6),
                                Text(DateFormat('dd MMM yyyy', 'es').format(widget.user.birthDate!), style: TextStyle(color: Colors.grey[800], fontSize: 15)),
                              ],
                            ),
                          ),

                        const SizedBox(height: 16),

                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color: _brandBlue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: _brandBlue.withOpacity(0.3)),
                          ),
                          child: Text(
                            widget.user.role.name.toUpperCase(),
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: _brandBlue),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(_fixedOrganization, style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey[600])),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // ==========================================
                // FORMULARIO DE EDICIÓN
                // ==========================================
                Card(
                  elevation: 4,
                  shadowColor: Colors.black12,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.edit_document, color: _brandBlue),
                              const SizedBox(width: 10),
                              const Text('Editar Información', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const Divider(height: 30),

                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _nombresController,
                                  decoration: const InputDecoration(labelText: 'Nombres', border: OutlineInputBorder(), isDense: true),
                                  validator: (v) => v!.isEmpty ? 'Requerido' : null,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextFormField(
                                  controller: _apellidosController,
                                  decoration: const InputDecoration(labelText: 'Apellidos', border: OutlineInputBorder(), isDense: true),
                                  validator: (v) => v!.isEmpty ? 'Requerido' : null,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 15),

                          TextFormField(
                            controller: _phoneController,
                            decoration: const InputDecoration(
                              labelText: 'Celular / WhatsApp',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.phone_android),
                              isDense: true,
                            ),
                            keyboardType: TextInputType.phone,
                          ),
                          const SizedBox(height: 15),

                          InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _selectedBirthDate ?? DateTime(2000),
                                firstDate: DateTime(1920),
                                lastDate: DateTime.now(),
                                locale: const Locale('es', 'ES'),
                              );
                              if (picked != null) {
                                setState(() => _selectedBirthDate = picked);
                              }
                            },
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Fecha de Nacimiento',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.calendar_month),
                                isDense: true,
                              ),
                              child: Text(
                                _selectedBirthDate != null
                                    ? DateFormat('dd/MM/yyyy').format(_selectedBirthDate!)
                                    : 'Toca para seleccionar',
                                style: TextStyle(color: _selectedBirthDate != null ? Colors.black : Colors.grey[600]),
                              ),
                            ),
                          ),
                          const SizedBox(height: 15),

                          TextFormField(
                            initialValue: _fixedOrganization,
                            readOnly: true,
                            enabled: false,
                            decoration: InputDecoration(
                              labelText: 'Organización (Fija)',
                              border: const OutlineInputBorder(),
                              prefixIcon: const Icon(Icons.lock_outline),
                              helperText: 'Contacta al Admin para cambiar de organización',
                              fillColor: Colors.grey.shade100,
                              filled: true,
                              isDense: true,
                            ),
                          ),
                          const SizedBox(height: 15),

                          // 🚀 NUEVO: Campo de texto libre para el llamamiento
                          TextFormField(
                            controller: _callingController,
                            decoration: const InputDecoration(
                              labelText: 'Llamamiento Actual',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.badge),
                              isDense: true,
                            ),
                          ),

                          const SizedBox(height: 30),

                          _isLoading
                              ? const Center(child: CircularProgressIndicator())
                              : ElevatedButton.icon(
                            onPressed: _saveProfile,
                            icon: const Icon(Icons.save),
                            label: const Text('Guardar Cambios', style: TextStyle(fontSize: 16)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _brandBlue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),

                          const SizedBox(height: 20),

                          // 🚀 Mejor visual para el reseteo de contraseña
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.red.shade200),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ListTile(
                              leading: Icon(Icons.lock_reset, color: Colors.red.shade700),
                              title: const Text('Cambiar Contraseña', style: TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: const Text('Se enviará un correo con instrucciones', style: TextStyle(fontSize: 12)),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: _requestPasswordChange,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}