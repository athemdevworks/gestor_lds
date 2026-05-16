import 'package:flutter/material.dart';
import 'package:gestor_lds/features/auth/services/auth_service.dart';
import 'package:gestor_lds/features/auth/screens/registration_screen.dart';
import 'package:gestor_lds/core/utils/alert_utils.dart';
import 'package:flutter_svg/flutter_svg.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final Color _brandBlue = const Color(0xFF22539A); // 🚀 Color corporativo

  // Controladores
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final AuthService _authService = AuthService();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    // Cerramos el teclado para evitar solapamientos
    FocusScope.of(context).unfocus();

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
          emailToUse = await _authService.getEmailFromUsername(input.toLowerCase());
          if (emailToUse == null) {
            throw 'No se encontró el nombre de usuario "$input".';
          }
        }

        // 2. Login
        await _authService.signInWithEmailAndPassword(emailToUse, password);
        // Si pasa, AuthWrapper redirige mágicamente a la Sala de Espera o al Dashboard.

      } catch (e) {
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
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), // 🚀 Dialog más elegante
        title: const Text('Recuperar Contraseña', style: TextStyle(fontWeight: FontWeight.bold)),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Ingresa tu correo electrónico. Te enviaremos un enlace para que puedas crear una nueva contraseña segura.',
                  style: TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: resetEmailController,
                  decoration: const InputDecoration(
                    labelText: 'Correo Electrónico',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email_outlined),
                    isDense: true,
                  ),
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _brandBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              if (resetEmailController.text.isEmpty) return;
              try {
                await _authService.sendPasswordResetEmail(resetEmailController.text.trim());
                if (mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('✅ Correo enviado. Revisa tu bandeja de entrada.'), backgroundColor: Colors.green),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text('Enviar Enlace'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEF2F6), // 🚀 Fondo unificado
      appBar: AppBar(
        backgroundColor: _brandBlue, // 🚀 Usamos la variable local por si el Theme falla
        title: SvgPicture.asset(
          'images/logo-hor.svg',
          height: 45,
          colorFilter: const ColorFilter.mode(
            Colors.white,
            BlendMode.srcIn,
          ),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 450),
            child: Card(
              elevation: 4,
              shadowColor: Colors.black12,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(32.0), // 🚀 Más respiro interior
                child: Form(
                  key: _formKey,
                  child: AutofillGroup(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SvgPicture.asset(
                          'images/glds-isotipo.svg', // Tu logo vertical
                          height: 130,            // 🚀 Aquí controlas qué tan "grande" se ve
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Portal de Acceso', // 🚀 Texto más corporativo
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: _brandBlue),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 30),

                        TextFormField(
                          controller: _emailController,
                          textInputAction: TextInputAction.next,
                          keyboardType: TextInputType.emailAddress,
                          autofillHints: const [AutofillHints.username, AutofillHints.email],
                          decoration: const InputDecoration(
                            labelText: 'Correo o Nombre de Usuario',
                            prefixIcon: Icon(Icons.person),
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          validator: (value) => (value == null || value.isEmpty) ? 'Ingresa tu usuario o correo' : null,
                        ),

                        const SizedBox(height: 20),

                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.done,
                          autofillHints: const [AutofillHints.password],
                          onFieldSubmitted: (_) => _login(),
                          onEditingComplete: _login,
                          decoration: InputDecoration(
                            labelText: 'Contraseña',
                            prefixIcon: const Icon(Icons.lock_outline),
                            border: const OutlineInputBorder(),
                            isDense: true,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                color: Colors.grey,
                              ),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                          ),
                          validator: (value) => (value == null || value.isEmpty) ? 'Por favor ingresa tu contraseña' : null,
                        ),

                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: _showResetPasswordDialog,
                            style: TextButton.styleFrom(foregroundColor: _brandBlue),
                            child: const Text('¿Olvidaste tu contraseña?'),
                          ),
                        ),

                        const SizedBox(height: 20),

                        _isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : ElevatedButton(
                          onPressed: _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _brandBlue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16), // 🚀 Botón más grueso
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('Iniciar Sesión', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),

                        const SizedBox(height: 15),

                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(builder: (context) => const RegistrationScreen()),
                            );
                          },
                          style: TextButton.styleFrom(foregroundColor: Colors.grey.shade700),
                          child: const Text('¿No tienes cuenta? Solicita acceso aquí.'),
                        ),

                        const SizedBox(height: 30),
                        const Divider(),
                        const Padding(
                          padding: EdgeInsets.only(top: 16.0, bottom: 8.0),
                          child: Column(
                            children: [
                              Text('GestorLDS', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                              Text('Desarrollado por ATHEM DevWorks © 2026', style: TextStyle(fontSize: 12, color: Colors.grey)),
                              SizedBox(height: 4),
                              Text('Versión 2.1.2', style: TextStyle(fontSize: 11, color: Colors.grey)),
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
      ),
    );
  }
}
