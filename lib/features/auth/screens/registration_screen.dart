import 'package:flutter/material.dart';
import '../auth_service.dart'; // Importa tu servicio de autenticación
import 'package:gestor_lds/features/auth/screens/login_screen.dart';
import 'package:gestor_lds/core/constants/callings_list.dart'; // Asegúrate de la ruta

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();

  // 1. Controladores para todos los campos de UserModel
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _nombresController = TextEditingController();
  final TextEditingController _apellidosController = TextEditingController();
  final TextEditingController _callingController = TextEditingController();

  final AuthService _authService = AuthService();
  bool _isLoading = false;

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      setState(() { _isLoading = true; });

      try {
        await _authService.registerWithEmailAndPassword(
          _emailController.text,
          _passwordController.text,
          _usernameController.text,
          _nombresController.text,
          _apellidosController.text,
          _callingController.text,
        );

        // Registro exitoso, pero el usuario está PENDIENTE de aprobación.
        // Lo redirigimos a una pantalla de espera.
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registro exitoso. Esperando aprobación del obispado.')),
        );

      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error de registro: ${e.toString()}')),
        );
      } finally {
        setState(() { _isLoading = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registro de Líder')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Solicitud de Acceso',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                // Campos de datos
                _buildTextField(_nombresController, 'Nombres', false),
                _buildTextField(_apellidosController, 'Apellidos', false),
                // --- NUEVO: DROPDOWN CON BÚSQUEDA ---
                Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: LayoutBuilder(
                      builder: (context, constraints) {
                        // Usamos LayoutBuilder para que el Dropdown ocupe todo el ancho
                        return DropdownMenu<String>(
                          width: constraints.maxWidth, // Ancho completo
                          controller: _callingController, // Usamos el mismo controlador
                          label: const Text('Llamamiento'),
                          hintText: 'Escribe para buscar...', // Cambia el texto para que sepan que pueden escribir
                          menuHeight: 300, // Limita la altura y activa el scroll
                          enableFilter: true,
                          requestFocusOnTap: true,
                          dropdownMenuEntries: kLdsCallings.map<DropdownMenuEntry<String>>((String calling) {
                            return DropdownMenuEntry<String>(
                              value: calling,
                              label: calling,
                            );
                          }).toList(),
                          inputDecorationTheme: const InputDecorationTheme(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                          onSelected: (String? calling) {
                            if (calling != null) {
                              _callingController.text = calling;
                            }
                          },
                        );
                      }
                  ),
                ),
                _buildTextField(_usernameController, 'Nombre de Usuario Único', false),

                const Divider(height: 30),

                // Campos de autenticación
                _buildTextField(_emailController, 'Correo Electrónico', false),
                _buildTextField(_passwordController, 'Contraseña', true),

                const SizedBox(height: 30),
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                  onPressed: _register,
                  child: const Text('Solicitar Acceso'),
                ),

                const SizedBox(height: 10), // Nuevo espacio
                TextButton( // Nuevo botón para ir a Login
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (context) => const LoginScreen()),
                    );
                  },
                  child: const Text('¿Ya tienes cuenta? Iniciar Sesión'),
                ),

              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
      TextEditingController controller,
      String label,
      bool isPassword, {
        String? hintText, // <--- NUEVO PARÁMETRO
      }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword,
        decoration: InputDecoration(
          labelText: label,
          hintText: hintText, // <--- USAR AQUÍ
          hintStyle: TextStyle(color: Colors.grey.shade400), // Color suave
          border: const OutlineInputBorder(),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Por favor, ingrese su $label';
          }
          return null;
        },
      ),
    );
  }
}