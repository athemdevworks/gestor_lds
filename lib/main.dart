import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart'; // <--- RECOMENDADO: Manejo de estado
import 'firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// Importamos las pantallas y servicios
import 'package:gestor_lds/features/auth/services/auth_service.dart';
import 'package:gestor_lds/features/auth/screens/login_screen.dart';
import 'package:gestor_lds/features/auth/screens/pending_access_screen.dart';
import 'package:gestor_lds/features/dashboard/screens/home_screen.dart';
import 'package:gestor_lds/features/auth/models/user_model.dart';

// 🚀 NUEVA IMPORTACIÓN: Agregamos la pantalla de estadísticas para las rutas
import 'package:gestor_lds/features/statistics/screens/manager_dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es_ES', null);

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const GestorLDSApp());
}

class GestorLDSApp extends StatelessWidget {
  const GestorLDSApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Usamos MultiProvider para inyectar el AuthService en toda la app
    return MultiProvider(
      providers: [
        Provider<AuthService>(create: (_) => AuthService()),
      ],
      child: MaterialApp(
        title: 'GestorLDS',
        debugShowCheckedModeBanner: false,

        // --- TEMA (REBRANDING v1.2.3) ---
        theme: ThemeData(
          useMaterial3: true,
          scaffoldBackgroundColor: Colors.white,
          colorScheme: const ColorScheme(
            brightness: Brightness.light,
            primary: Color(0xFF22539A),
            onPrimary: Colors.white,
            secondary: Colors.black,
            onSecondary: Colors.white,
            error: Colors.red,
            onError: Colors.white,
            surface: Colors.white,
            onSurface: Colors.black,
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF22539A),
            foregroundColor: Colors.white,
            elevation: 0,
            centerTitle: true,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF22539A),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF999999)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF22539A), width: 2),
            ),
            labelStyle: const TextStyle(color: Color(0xFF999999)),
          ),
        ),

        // --- LOCALIZACIÓN ---
        locale: const Locale('es'),
        supportedLocales: const [Locale('es'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],

        home: const AuthWrapper(),

        // 🚀 MAPA DE RUTAS: Aquí le decimos a Flutter qué pantalla cargar al pedir una ruta
        routes: {
          '/statistics': (context) => const ManagerDashboardScreen(),
        },
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // Obtenemos la instancia de AuthService desde el Provider
    final authService = Provider.of<AuthService>(context, listen: false);

    // 1. PRIMER STREAM: Escucha Autenticación de Firebase (Login/Logout)
    return StreamBuilder<User?>(
      stream: authService.userStream,
      builder: (context, snapshotAuth) {

        // Cargando Auth...
        if (snapshotAuth.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        // Si NO hay usuario logueado en Firebase -> Pantalla de Login
        if (!snapshotAuth.hasData) {
          return const LoginScreen();
        }

        // 2. SEGUNDO STREAM: Escucha los Datos del Usuario en Firestore
        // Usamos el método getUserData que agregamos al AuthService
        return StreamBuilder<UserModel?>(
          stream: authService.getUserData(snapshotAuth.data!.uid),
          builder: (context, snapshotModel) {

            // Cargando datos del perfil...
            if (snapshotModel.connectionState == ConnectionState.waiting) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }

            final UserModel? userModel = snapshotModel.data;

            // CASO: Usuario logueado en Auth pero sin documento en Firestore
            // o documento aún cargando (raro, pero posible)
            if (userModel == null) {
              // Podrías mostrar un error o un loading.
              // Si es null mucho tiempo, significa inconsistencia en DB.
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }

            // CASO: Usuario existe pero NO está aprobado
            if (!userModel.isApproved) {
              return const PendingAccessScreen();
            }

            // CASO: Usuario Aprobado -> Home
            return HomeScreen(user: userModel);
          },
        );
      },
    );
  }
}