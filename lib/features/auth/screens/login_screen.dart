import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../auth_service.dart';
import 'registration_screen.dart'; // Para navegar de vuelta al registro

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() { _isLoading = true; });

      try {
        await _authService.signInWithEmailAndPassword(
          _emailController.text,
          _passwordController.text,
        );
        // Si el login de Auth tiene éxito, el StreamBuilder en main.dart lo detectará.

      } on FirebaseException catch (e) {
        // Manejo de errores de login (credenciales incorrectas, etc.)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error de acceso: ${e.message}')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error desconocido: $e')),
        );
      } finally {
        setState(() { _isLoading = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Iniciar Sesión')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Acceso de Líderes',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),

                _buildTextField(_emailController, 'Correo Electrónico', false),
                _buildTextField(_passwordController, 'Contraseña', true),

                const SizedBox(height: 30),
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                  onPressed: _login,
                  child: const Text('Iniciar Sesión'),
                ),

                const SizedBox(height: 10),
                TextButton(
                  onPressed: () {
                    // Navegar a la pantalla de registro
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (context) => const RegistrationScreen()),
                    );
                  },
                  child: const Text('¿No tienes cuenta? Solicita acceso aquí.'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Utiliza el mismo widget auxiliar que creaste en registration_screen.dart
  Widget _buildTextField(TextEditingController controller, String label, bool isPassword) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword,
        decoration: InputDecoration(
          labelText: label,
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