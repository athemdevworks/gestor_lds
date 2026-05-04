import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:gestor_lds/features/auth/auth_service.dart';
import 'package:gestor_lds/features/auth/models/user_model.dart';
import 'package:gestor_lds/core/utils/alert_utils.dart';
import 'package:gestor_lds/features/auth/services/user_service.dart';
import 'package:gestor_lds/features/auth/screens/login_screen.dart';
import 'package:gestor_lds/core/constants/wards_list.dart';
import 'package:gestor_lds/core/constants/organizations_list.dart'; // Tu lista maestra

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controladores
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _callingController = TextEditingController(); // 🚀 El nuevo campo de texto libre

  // Estado de Selección
  String? _selectedOrganization;
  DateTime? _selectedBirthDate;
  String? _selectedWard;
  bool _obscurePassword = true;
  bool _isLoading = false;

  final AuthService _authService = AuthService();
  final UserService _userService = UserService();

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _callingController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {

      if (_selectedBirthDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Por favor ingresa tu fecha de nacimiento'),
              backgroundColor: Colors.orange,
            )
        );
        return;
      }

      setState(() => _isLoading = true);
      try {
        final bool alreadyExists = await _userService.checkDuplicateUser(
            _firstNameController.text.trim(),
            _lastNameController.text.trim()
        );

        if (alreadyExists) {
          if (mounted) {
            setState(() => _isLoading = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Row(children: [Icon(Icons.warning, color: Colors.white), SizedBox(width: 10), Expanded(child: Text('Ya existe un usuario con este Nombre.'))]),
                backgroundColor: Colors.orange.shade800,
              ),
            );
          }
          return;
        }

        // 🚀 SEGURIDAD: Todos nacen como miembros básicos. El Admin da los permisos en el Dashboard.
        UserRole assignedRole = UserRole.miembro;

        await _authService.registerUser(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          calling: _callingController.text.trim().isEmpty ? 'Pendiente' : _callingController.text.trim(), // Si lo dejan vacío, dice 'Pendiente'
          organization: _selectedOrganization!,
          ward: _selectedWard!,
          role: assignedRole,
          username: _usernameController.text.trim().toLowerCase(),
          phoneNumber: _phoneController.text.trim(),
          birthDate: _selectedBirthDate,
        );

        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cuenta creada. Espera aprobación de la Estaca.'), backgroundColor: Colors.green));
        }

      } catch (e) {
        if (mounted) showErrorDialog(context, 'Error de Registro', e.toString());
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Solicitud de Acceso')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Datos Personales', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 15),

                  Row(children: [
                    Expanded(child: TextFormField(controller: _firstNameController, decoration: const InputDecoration(labelText: 'Nombres', border: OutlineInputBorder()), validator: (v) => v!.isEmpty ? 'Requerido' : null)),
                    const SizedBox(width: 10),
                    Expanded(child: TextFormField(controller: _lastNameController, decoration: const InputDecoration(labelText: 'Apellidos', border: OutlineInputBorder()), validator: (v) => v!.isEmpty ? 'Requerido' : null)),
                  ]),
                  const SizedBox(height: 15),

                  TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(labelText: 'Celular / WhatsApp', border: OutlineInputBorder(), prefixIcon: Icon(Icons.phone_android), helperText: 'Para contacto del barrio'),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 15),

                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime(2000),
                        firstDate: DateTime(1920),
                        lastDate: DateTime.now(),
                        locale: const Locale('es', 'ES'),
                      );
                      if (picked != null) setState(() => _selectedBirthDate = picked);
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Fecha de Nacimiento',
                        prefixIcon: Icon(Icons.cake),
                        border: OutlineInputBorder(),
                        helperText: 'Para el recordatorio de cumpleaños',
                      ),
                      child: Text(
                        _selectedBirthDate == null
                            ? 'Toca para seleccionar'
                            : DateFormat('dd/MM/yyyy').format(_selectedBirthDate!),
                        style: TextStyle(color: _selectedBirthDate == null ? Colors.grey : Colors.black87),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),

                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Barrio',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.location_city),
                    ),
                    value: _selectedWard,
                    items: kWardsList.map((ward) => DropdownMenuItem(value: ward, child: Text(ward))).toList(),
                    onChanged: (val) => setState(() => _selectedWard = val),
                    validator: (v) => v == null ? 'Selecciona tu barrio' : null,
                  ),
                  const SizedBox(height: 15),

                  // 🚀 ÚNICO DROPBOX DE ORGANIZACIÓN
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Organización Principal', border: OutlineInputBorder(), prefixIcon: Icon(Icons.group)),
                    value: _selectedOrganization,
                    items: kOrganizationsList.map((org) => DropdownMenuItem(value: org, child: Text(org))).toList(),
                    onChanged: (val) => setState(() => _selectedOrganization = val),
                    validator: (v) => v == null ? 'Selecciona tu organización' : null,
                  ),
                  const SizedBox(height: 15),

                  // 🚀 CAMPO DE TEXTO SIMPLE PARA LLAMAMIENTO
                  TextFormField(
                    controller: _callingController,
                    decoration: const InputDecoration(
                        labelText: 'Llamamiento Actual (Opcional)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.badge),
                        hintText: 'Ej: Consultor, Presidente, Maestro...'
                    ),
                  ),
                  const SizedBox(height: 25),

                  const Text('Datos de Cuenta', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 15),

                  TextFormField(
                    controller: _usernameController,
                    decoration: const InputDecoration(labelText: 'Usuario', prefixIcon: Icon(Icons.person), border: OutlineInputBorder()),
                    validator: (v) => v!.isEmpty ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 15),

                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(labelText: 'Correo Electrónico', prefixIcon: Icon(Icons.email), border: OutlineInputBorder()),
                    validator: (v) => !v!.contains('@') ? 'Correo inválido' : null,
                  ),
                  const SizedBox(height: 15),

                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Contraseña',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off), onPressed: () => setState(() => _obscurePassword = !_obscurePassword)),
                    ),
                    validator: (v) => v!.length < 6 ? 'Mínimo 6 caracteres' : null,
                  ),

                  const SizedBox(height: 30),

                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ElevatedButton(
                        onPressed: _register,
                        style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                        child: const Text('Solicitar Registro', style: TextStyle(fontSize: 18)),
                      ),
                      const SizedBox(height: 15),

                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(builder: (_) => const LoginScreen()),
                          );
                        },
                        child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}