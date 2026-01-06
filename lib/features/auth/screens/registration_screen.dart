import 'package:flutter/material.dart';
import 'package:gestor_lds/core/constants/callings_list.dart';
import 'package:gestor_lds/features/auth/auth_service.dart';
import 'package:gestor_lds/features/auth/models/user_model.dart';
import 'package:gestor_lds/core/utils/alert_utils.dart';
// 1. IMPORTAMOS EL SERVICIO DE USUARIOS
import 'package:gestor_lds/features/auth/services/user_service.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controladores
  final _nombresController = TextEditingController();
  final _apellidosController = TextEditingController();
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();

  // Estado de Selección
  String? _selectedOrganization;
  String? _selectedCalling;
  bool _obscurePassword = true;
  bool _isLoading = false;

  final AuthService _authService = AuthService();
  // Instancia del servicio de usuario para validaciones
  final UserService _userService = UserService();

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        // --- 2. VALIDACIÓN DE DUPLICADOS ---
        // Antes de llamar a Firebase Auth, verificamos si el nombre ya existe en Firestore
        final bool alreadyExists = await _userService.checkDuplicateUser(
            _nombresController.text.trim(),
            _apellidosController.text.trim()
        );

        if (alreadyExists) {
          // Si existe, detenemos la carga y mostramos alerta
          if (mounted) {
            setState(() => _isLoading = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.white),
                    SizedBox(width: 10),
                    Expanded(child: Text('Ya existe un usuario registrado con este Nombre y Apellido.')),
                  ],
                ),
                backgroundColor: Colors.orange.shade800,
                duration: const Duration(seconds: 4),
              ),
            );
          }
          return; // DETENEMOS EL PROCESO AQUÍ
        }
        // -----------------------------------

        UserRole assignedRole = UserRole.lider;

        if (_selectedOrganization == 'Obispado') {
          assignedRole = UserRole.obispado;
        } else if (_selectedOrganization == 'Barrio') {
          assignedRole = UserRole.miembro;
        }

        await _authService.registerUser(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          nombres: _nombresController.text.trim(),
          apellidos: _apellidosController.text.trim(),
          calling: _selectedCalling!,
          organization: _selectedOrganization!,
          role: assignedRole,
          username: _usernameController.text.trim().toLowerCase(),
          phoneNumber: _phoneController.text.trim(),
        );

        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cuenta creada. Espera aprobación del Obispo.')),
          );
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
    final organizations = kLdsStructure.keys.toList();
    final callings = _selectedOrganization != null
        ? kLdsStructure[_selectedOrganization] ?? []
        : [];

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
                    Expanded(child: TextFormField(controller: _nombresController, decoration: const InputDecoration(labelText: 'Nombres', border: OutlineInputBorder()), validator: (v) => v!.isEmpty ? 'Requerido' : null)),
                    const SizedBox(width: 10),
                    Expanded(child: TextFormField(controller: _apellidosController, decoration: const InputDecoration(labelText: 'Apellidos', border: OutlineInputBorder()), validator: (v) => v!.isEmpty ? 'Requerido' : null)),
                  ]),
                  const SizedBox(height: 15),

                  TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Celular / WhatsApp',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.phone_android),
                      helperText: 'Para contacto del barrio',
                    ),
                    keyboardType: TextInputType.phone,
                    validator: (v) {
                      if (v != null && v.isNotEmpty && v.length < 9) return 'Número muy corto';
                      return null;
                    },
                  ),
                  const SizedBox(height: 15),

                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Organización', border: OutlineInputBorder()),
                    value: _selectedOrganization,
                    items: organizations.map((org) => DropdownMenuItem(value: org, child: Text(org))).toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedOrganization = val;
                        _selectedCalling = null;
                      });
                    },
                    validator: (v) => v == null ? 'Selecciona tu organización' : null,
                  ),
                  const SizedBox(height: 15),

                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Llamamiento Actual', border: OutlineInputBorder()),
                    value: _selectedCalling,
                    items: callings.map<DropdownMenuItem<String>>((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                    onChanged: (val) => setState(() => _selectedCalling = val),
                    validator: (v) => v == null ? 'Selecciona tu llamamiento' : null,
                    disabledHint: const Text('Primero elige Organización'),
                  ),
                  const SizedBox(height: 25),

                  const Text('Datos de Cuenta', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 15),

                  TextFormField(
                    controller: _usernameController,
                    decoration: const InputDecoration(labelText: 'Usuario (Ej: familia_perez)', prefixIcon: Icon(Icons.person), border: OutlineInputBorder()),
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
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
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
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancelar / Volver', style: TextStyle(color: Colors.grey)),
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