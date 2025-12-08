import 'package:cloud_firestore/cloud_firestore.dart'; // Necesario para leer la DB
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'firebase_options.dart';
import 'package:flutter_localizations/flutter_localizations.dart'; // <-- ¡NUEVO!
import 'package:flutter/cupertino.dart'; // <-- Necesario para el delegate de Cupertino

// Importamos las pantallas
import 'package:gestor_lds/features/auth/auth_service.dart';
import 'package:gestor_lds/features/auth/screens/registration_screen.dart';
import 'package:gestor_lds/features/auth/screens/login_screen.dart';
import 'package:gestor_lds/features/auth/screens/pending_access_screen.dart'; // Nueva
import 'package:gestor_lds/features/dashboard/home_screen.dart'; // Nueva
import 'package:gestor_lds/features/auth/repositories/user_repository.dart';
import 'package:gestor_lds/features/auth/models/user_model.dart';

void main() async {
  // 1. Aseguramos que el motor de Flutter esté listo
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Inicializamos los datos de localización para español
  await initializeDateFormatting('es_ES', null);; // <-- ¡LÍNEA AÑADIDA!

  // 3. Inicializamos Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 4. Ejecutamos la aplicación
  runApp(const GestorLDSApp());
}

class GestorLDSApp extends StatelessWidget {
  const GestorLDSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GestorLDS',
      debugShowCheckedModeBanner: false,
// --- NUEVO TEMA (REBRANDING v1.2.3) ---
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white, // Fondo Blanco (#FFFFFF)

        // Esquema de Colores
        colorScheme: const ColorScheme(
          brightness: Brightness.light,
          primary: Color(0xFF164772),       // Azul Institucional (#164772)
          onPrimary: Colors.white,          // Texto sobre azul
          secondary: Colors.black,          // Color Secundario (#000000)
          onSecondary: Colors.white,
          error: Colors.red,
          onError: Colors.white,
          background: Colors.white,         // Fondo (#FFFFFF)
          onBackground: Colors.black,
          surface: Colors.white,            // Superficie de tarjetas
          onSurface: Colors.black,
          outline: Color(0xFF999999),       // Neutro (#999999) para bordes
        ),

        // Estilo de AppBars (Barras superiores)
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF164772), // Azul
          foregroundColor: Colors.white,      // Texto Blanco
          elevation: 0,
          centerTitle: true,
        ),

        // Estilo de Botones Elevados
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF164772), // Botones Azules
            foregroundColor: Colors.white,            // Texto Blanco
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),

        // Estilo de Inputs (Cajas de texto)
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF999999)), // Borde Neutro
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF164772), width: 2), // Borde Azul
          ),

          labelStyle: const TextStyle(color: Color(0xFF999999)),
        ),
      ),
      locale: const Locale('es'), // Idioma por defecto
      supportedLocales: const [
        Locale('es'), // Soportar español
        Locale('en'), // Soportar inglés (por si acaso)
      ],

      // AÑADE ESTA SECCIÓN CRÍTICA:
      localizationsDelegates: const [
        // Delegado de Material Design (para TextField, botones, etc.)
        GlobalMaterialLocalizations.delegate,
        // Delegado de Widgets (para orientación de texto)
        GlobalWidgetsLocalizations.delegate,
        // Delegado de Cupertino (para estilos de iOS, aunque estemos en Android/Web)
        GlobalCupertinoLocalizations.delegate,
      ],

      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final userRepository = UserRepository(); // Instancia del nuevo repositorio

    // 1. PRIMER STREAM: Escucha Autenticación (Login/Logout)
    return StreamBuilder<User?>(
      stream: authService.userStream,
      builder: (context, snapshotAuth) {

        // Cargando Auth...
        if (snapshotAuth.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        // Si NO hay usuario logueado -> Pantalla de Login
        if (!snapshotAuth.hasData) {
          return const LoginScreen();
        }

        // 2. SEGUNDO STREAM: Escucha el Modelo de Usuario (Role y Status)
        return StreamBuilder<UserModel?>(
          stream: userRepository.streamCurrentUserModel(),
          builder: (context, snapshotModel) {

            // Cargando datos del perfil...
            if (snapshotModel.connectionState == ConnectionState.waiting) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }

            // Si el modelo NO existe o hubo un error (debería existir si el registro fue exitoso)
            if (!snapshotModel.hasData || snapshotModel.hasError) {
              // Podríamos forzar un logout aquí para limpiar la sesión
              return const Scaffold(body: Center(child: Text("Error: Perfil de usuario incompleto. Intente de nuevo.")));
            }

            final UserModel userModel = snapshotModel.data!;

            // LÓGICA DE REDIRECCIÓN FINAL
            if (userModel.status == 'active') {
              // Si está activo, lo mandamos al menú principal
              return HomeScreen(user: userModel);
            } else {
              // Si está pendiente, lo mandamos a la sala de espera
              return const PendingAccessScreen();
            }
          },
        );
      },
    );
  }
}