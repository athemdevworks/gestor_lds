import 'package:flutter/material.dart';
import 'package:gestor_lds/features/auth/services/auth_service.dart';

class PendingAccessScreen extends StatelessWidget {
  const PendingAccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const Color brandBlue = Color(0xFF22539A);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Acceso Restringido', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: brandBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 🚀 Ícono más elegante y representativo
              Icon(
                Icons.admin_panel_settings_rounded,
                size: 100,
                color: Colors.orange.shade400,
              ),
              const SizedBox(height: 24),

              const Text(
                'Cuenta en Revisión',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: brandBlue,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              const Text(
                'Tu solicitud ha sido registrada exitosamente. Por motivos de seguridad y privacidad, un administrador debe verificar tu identidad y asignarte permisos antes de que puedas acceder al directorio.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.black54,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 40),

              // 🚀 Botón de salida con estilo destructivo (Outlined)
              OutlinedButton.icon(
                icon: const Icon(Icons.logout),
                label: const Text('Cerrar Sesión y Salir'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red.shade700,
                  side: BorderSide(color: Colors.red.shade300),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () async {
                  await AuthService().signOut();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}