import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../auth_service.dart';
import 'registration_screen.dart'; // Para navegar de vuelta al registro
import 'package:gestor_lds/core/utils/alert_utils.dart';
import 'package:package_info_plus/package_info_plus.dart';

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
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );
        // Si el login es exitoso, el StreamBuilder en main.dart hará la navegación.

      } on FirebaseException catch (e) {
        // CATCH 1: Errores de Firebase (Contraseña mal, usuario no existe)
        if (mounted) {
          showErrorDialog(
              context,
              'Error de Acceso',
              _mapFirebaseError(e.code) // O usa e.message si prefieres el texto técnico
          );
        }
      } catch (e) {
        // CATCH 2: Errores inesperados (Código roto, null pointer, etc)
        if (mounted) {
          showErrorDialog(
              context,
              'Error Desconocido',
              'Ocurrió un problema inesperado: $e'
          );
        }
      } finally {
        if (mounted) setState(() { _isLoading = false; });
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
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: SizedBox(
              width: double.maxFinite,
                  child: Column(
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
          ),
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
      backgroundColor: Colors.grey[100], // Fondo gris suave fuera de la tarjeta
      appBar: AppBar(
        title: Image.asset(
          'assets/images/logont.png', // Usamos el mismo logo del PDF
          height: 40,               // Altura controlada para que no deforme la barra
          color: Colors.white,      // <--- EL TRUCO: Esto lo pinta de blanco puro
          fit: BoxFit.contain,      // Asegura que se vea completo
        ),
        centerTitle: true, // Para que quede centrado
      ),
      // CENTRAMOS TODO EL CONTENIDO
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),

          // RESTRICCIÓN DE ANCHO (Máximo 450px para que parezca app móvil en PC)
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 450),

              // TARJETA BLANCA FLOTANTE
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(24.0), // Más espacio interno
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

                          // 1. CAMPO EMAIL: Configurado para "Siguiente"
                          _buildTextField(
                            _emailController,
                            'Correo Electrónico',
                            false,
                            // Esto hace que el teclado muestre la flecha de "Siguiente"
                            // en lugar de "Intro" o "Nueva línea".
                            action: TextInputAction.next,
                          ),

                          // 2. CAMPO PASSWORD: Configurado para "Enviar/Hecho"
                          _buildTextField(
                            _passwordController,
                            'Contraseña',
                            true,
                            // Esto hace que el teclado muestre un "Check" o "Ir"
                            action: TextInputAction.done,
                            // Esta es la clave: Al presionar Enter, se llama a _login()
                            onSubmitted: (_) => _login(),
                          ),

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
                          Padding(
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

                                const Text(
                                  'Versión 1.2.4',
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
            ),
          ),
        ),
      );
  }

  // Utiliza el mismo widget auxiliar que creaste en registration_screen.dart
  Widget _buildTextField(
      TextEditingController controller,
      String label,
      bool isPassword, {
        TextInputAction? action, // Nuevo parámetro opcional
        Function(String)? onSubmitted, // Nuevo parámetro opcional
      }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword,
        textInputAction: action, // Configura la tecla Enter (Siguiente/Enviar)
        onFieldSubmitted: onSubmitted, // Ejecuta la acción al dar Enter
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

  // Función auxiliar para traducir errores de Firebase a español
  String _mapFirebaseError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No existe una cuenta con este correo.';
      case 'wrong-password':
        return 'La contraseña es incorrecta.';
      case 'invalid-email':
        return 'El formato del correo no es válido.';
      case 'user-disabled':
        return 'Esta cuenta ha sido inhabilitada.';
      case 'too-many-requests':
        return 'Demasiados intentos fallidos. Intenta más tarde.';
      case 'network-request-failed':
        return 'Error de conexión. Revisa tu internet.';
      default:
        return 'Error de autenticación: $code';
    }
  }

}