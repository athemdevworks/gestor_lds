import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gestor_lds/features/auth/models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- 1. STREAM DE AUTENTICACIÓN (Para el primer StreamBuilder del main.dart) ---
  // Detecta si hay sesión de Firebase abierta o cerrada
  Stream<User?> get userStream => _auth.authStateChanges();

  // --- 2. STREAM DE DATOS DEL USUARIO (Para el segundo StreamBuilder del main.dart) ---
  // Escucha cambios en el documento del usuario (ej: si el Obispo cambia isApproved)
  Stream<UserModel?> getUserData(String uid) {
    return _db.collection('users').doc(uid).snapshots().map((snapshot) {
      if (snapshot.exists) {
        return UserModel.fromMap(snapshot.data()!, snapshot.id);
      }
      return null;
    });
  }

  // --- 3. INICIAR SESIÓN ---
  Future<User?> signInWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password
      );
      return result.user;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Ocurrió un error inesperado al iniciar sesión.';
    }
  }

  // --- 4. REGISTRO ---
  Future<User?> registerUser({
    required String email,
    required String password,
    required String username,
    required String nombres,
    required String apellidos,
    required String calling,
    required String organization,
    required UserRole role,
    String? phoneNumber,
    DateTime? birthDate, // <--- NUEVO CAMPO AGREGADO
  }) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = userCredential.user;

      if (user != null) {
        final newUser = UserModel(
          uid: user.uid,
          email: email,
          username: username,
          nombres: nombres,
          apellidos: apellidos,
          calling: calling,
          organization: organization,
          role: role,
          isApproved: false, // Siempre nace desaprobado
          phoneNumber: phoneNumber,
          birthDate: birthDate, // <--- LO GUARDAMOS EN EL MODELO
        );

        // Al llamar a toMap(), el UserModel se encarga de convertir DateTime a Timestamp
        await _db.collection('users').doc(user.uid).set(newUser.toMap());
        return user;
      }
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Error al registrar usuario: $e';
    }
    return null;
  }

  // --- 5. RECUPERAR CONTRASEÑA ---
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // --- 6. BUSCAR EMAIL POR USUARIO ---
  Future<String?> getEmailFromUsername(String username) async {
    try {
      final querySnapshot = await _db
          .collection('users')
          .where('username', isEqualTo: username)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs.first.data()['email'] as String?;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // --- 7. CERRAR SESIÓN ---
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // --- 8. MANEJO DE ERRORES (Traducción) ---
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No existe ninguna cuenta con este correo.';
      case 'wrong-password':
        return 'La contraseña es incorrecta.';
      case 'invalid-email':
        return 'El formato del correo no es válido.';
      case 'user-disabled':
        return 'Esta cuenta ha sido inhabilitada.';
      case 'too-many-requests':
        return 'Demasiados intentos. Espera unos minutos.';
      case 'email-already-in-use':
        return 'Este correo ya está registrado.';
      case 'network-request-failed':
        return 'Sin internet. Verifica tu conexión.';
      case 'invalid-credential':
        return 'La contraseña es incorrecta.';
      default:
        return 'Error de autenticación: ${e.message}';
    }
  }
}