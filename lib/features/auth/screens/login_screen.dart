import 'package:flutter/material.dart';
import '../auth_service.dart';
import 'registration_screen.dart';
import 'package:gestor_lds/core/utils/alert_utils.dart';

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
  bool _obscurePassword = true;

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() { _isLoading = true; });

      try {
        String input = _emailController.text.trim();
        String password = _passwordController.text.trim();
        String? emailToUse;

        // 1. Lógica: ¿Es correo o usuario?
        if (input.contains('@')) {
          emailToUse = input;
        } else {
          // Buscamos el correo asociado al usuario
          emailToUse = await _authService.getEmailFromUsername(input.toLowerCase()); // Sugiero lowercase para usuarios

          if (emailToUse == null) {
            // Lanzamos error directo como String para que el catch lo agarre
            throw 'No se encontró el nombre de usuario "$input".';
          }
        }

        // 2. Login (AuthService ya lanzará la excepción traducida si falla)
        await _authService.signInWithEmailAndPassword(emailToUse, password);

        // Si pasa, el AuthWrapper se encargará de redirigir al Home

      } catch (e) {
        // 3. Capturamos CUALQUIER error (que ya viene traducido del servicio)
        if (mounted) {
          showErrorDialog(context, 'Error de Acceso', e.toString());
        }
      } finally {
        if (mounted) setState(() { _isLoading = false; });
      }
    }
  }

  void _showResetPasswordDialog() {
    final resetEmailController = TextEditingController(text:
    _emailController.text.contains('@') ? _emailController.text : ''
    );

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
                const Text('Ingresa tu correo. Te enviaremos un enlace para crear una nueva contraseña.'),
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
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Correo enviado. Revisa tu bandeja.')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e.toString())), // Error traducido
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
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Image.asset(
          'assets/images/logont.png',
          height: 40,
          color: Colors.white,
          fit: BoxFit.contain,
        ),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 450),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
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

                      TextFormField(
                        controller: _emailController,
                        textInputAction: TextInputAction.next,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Correo o Nombre de Usuario',
                          prefixIcon: Icon(Icons.person),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Ingresa tu usuario o correo';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 20),

                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _login(),
                        decoration: InputDecoration(
                          labelText: 'Contraseña',
                          prefixIcon: const Icon(Icons.lock_outline),
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: Colors.grey,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor ingresa tu contraseña';
                          }
                          return null;
                        },
                      ),

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
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(builder: (context) => const RegistrationScreen()),
                          );
                        },
                        child: const Text('¿No tienes cuenta? Solicita acceso aquí.'),
                      ),
                      const SizedBox(height: 40),
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
                              'Desarrollado por ATHEM DevWorks © 2026', // Actualicé el año ;)
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                            Text(
                              'Versión 1.6.2',
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
}