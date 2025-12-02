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

  // Función para mostrar el diálogo de recuperación
  void _showResetPasswordDialog() {
    final resetEmailController = TextEditingController(text: _emailController.text);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Recuperar Contraseña'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Ingresa tu correo electrónico. Te enviaremos un enlace para crear una nueva contraseña.'),
            const SizedBox(height: 15),
            TextField(
              controller: resetEmailController,
              decoration: const InputDecoration(labelText: 'Correo Electrónico', border: OutlineInputBorder()),
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (resetEmailController.text.isEmpty) return;

              try {
                await _authService.sendPasswordResetEmail(resetEmailController.text.trim());
                if (mounted) {
                  Navigator.pop(context); // Cerrar diálogo
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Correo de recuperación enviado. Revisa tu bandeja.')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: ${e.toString()}')),
                  );
                }
              }
            },
            child: const Text('Enviar'),
          ),
        ],
      ),
    );
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

                // NUEVO: Botón de Olvidé Contraseña (Alineado a la derecha)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _showResetPasswordDialog,
                    child: const Text('¿Olvidaste tu contraseña?'),
                  ),
                ),

                const SizedBox(height: 20),
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
                const SizedBox(height: 40), // Espacio para separarlo
                const Divider(),
                const Padding(
                  padding: EdgeInsets.only(top: 10.0, bottom: 20.0),
                  child: Column(
                    children: [
                      Text(
                        'GestorLDS',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
                      ),
                      Text(
                        'Desarrollado por ATHEM DevWorks © 2025',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      Text(
                        'Versión 1.0.0', // Puedes cambiar esto manualmente cuando actualices
                        style: TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                    ],
                  ),
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