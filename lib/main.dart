import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // El archivo generado por FlutterFire
import 'package:gestor_lds/features/auth/screens/login_screen.dart';

// Importamos nuestras features
import 'package:gestor_lds/features/auth/auth_service.dart';
import 'package:gestor_lds/features/auth/screens/registration_screen.dart';

void main() async {
  // 1. Aseguramos que el motor de Flutter esté listo antes de llamar código nativo
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Inicializamos Firebase con la configuración generada para Web y Android
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 3. Ejecutamos la aplicación
  runApp(const GestorLDSApp());
}

class GestorLDSApp extends StatelessWidget {
  const GestorLDSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GestorLDS',
      debugShowCheckedModeBanner: false, // Quitamos la etiqueta "Debug"
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo), // Color serio para LDS
        useMaterial3: true,
      ),
      // 4. El "home" decide qué pantalla mostrar basado en el estado del usuario
      home: const AuthWrapper(),
    );
  }
}

// Widget que escucha los cambios de autenticación (Login/Logout)
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return StreamBuilder(
      stream: authService.userStream, // Escuchamos: ¿Hay usuario logueado?
      builder: (context, snapshot) {
        // Estado A: Cargando (Verificando si hay sesión guardada)
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Estado B: Hay error
        if (snapshot.hasError) {
          return const Scaffold(
            body: Center(child: Text("Error de autenticación")),
          );
        }

        // Estado C: Usuario Logueado (Tiene datos)
        if (snapshot.hasData) {
          // TODO: Aquí pondremos el Dashboard real luego.
          // Por ahora, una pantalla temporal para verificar que entraste.
          return Scaffold(
            appBar: AppBar(
              title: const Text("Bienvenido Líder"),
              actions: [
                IconButton(
                  icon: const Icon(Icons.logout),
                  onPressed: () async {
                    await authService.signOut(); // Necesitaremos agregar este metodo en AuthService
                  },
                )
              ],
            ),
            body: const Center(
              child: Text("¡Has iniciado sesión correctamente!"),
            ),
          );
        }

        // Estado D: No hay usuario (Logout) -> Mostrar Pantalla de Login
        return const LoginScreen(); // <-- ¡CAMBIADO A LOGIN!
      },
    );
  }

}