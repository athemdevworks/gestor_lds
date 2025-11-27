import 'package:flutter/material.dart';
import '../auth_service.dart';

class PendingAccessScreen extends StatelessWidget {
  const PendingAccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_clock, size: 80, color: Colors.orange),
              const SizedBox(height: 20),
              const Text(
                'Solicitud en Revisión',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text(
                'Tu cuenta ha sido creada, pero requiere aprobación de un miembro del Obispado para acceder a la información del Barrio.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                icon: const Icon(Icons.logout),
                label: const Text('Cerrar Sesión'),
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