import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:gestor_lds/features/auth/models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- 1. STREAM DE AUTENTICACIÓN ---
  Stream<User?> get userStream => _auth.authStateChanges();

  // --- 2. STREAM DE DATOS DEL USUARIO ---
  Stream<UserModel?> getUserData(String uid) {
    return _db.collection('users').doc(uid).snapshots().map((snapshot) {
      if (snapshot.exists) {
        return UserModel.fromMap(snapshot.data()!, snapshot.id);
      }
      return null;
    });
  }

  // --- 3. INICIAR SESIÓN (BLINDADO 🛡️) ---
  Future<User?> signInWithEmailAndPassword(String identifier, String password) async {
    try {
      String emailToUse = identifier.trim();
      String cleanUsername = identifier.trim().toLowerCase();

      // PASO 1: DETECTAR SI ES UN NOMBRE DE USUARIO
      if (!emailToUse.contains('@')) {
        final docRef = await _db.collection('usernames').doc(cleanUsername).get();
        if (!docRef.exists) {
          throw 'El nombre de usuario no existe.';
        }
        emailToUse = docRef.data()?['email'];
      }

      // PASO 2: AUTENTICAR CON FIREBASE
      UserCredential result = await _auth.signInWithEmailAndPassword(
          email: emailToUse,
          password: password
      );

      // PASO 3: VERIFICACIÓN DE INHABILITACIÓN
      if (result.user != null) {
        final userDoc = await _db.collection('users').doc(result.user!.uid).get();
        if (userDoc.exists) {
          final isActive = userDoc.data()?['isActive'] ?? true;
          if (!isActive) {
            await _auth.signOut();
            throw 'Esta cuenta ha sido inhabilitada por el administrador.';
          }
        }
      }
      return result.user;

    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' || e.code == 'invalid-credential') throw 'Credenciales incorrectas.';
      if (e.code == 'wrong-password') throw 'Contraseña incorrecta.';
      if (e.code == 'too-many-requests') throw 'Cuenta bloqueada temporalmente.';
      throw e.message ?? 'Error de autenticación.';
    } catch (e) {
      throw e.toString();
    }
  }

  // --- 4. REGISTRO ESTÁNDAR (Reclamo de Ficha) ---
  Future<User?> registerUser({
    required String email,
    required String password,
    required String username,
    required String firstName,
    required String lastName,
    required String gender,
    required bool isYSA,
    required String organization, // Su clase dominical (Ej. Cuórum de Élderes)
    required List<String> callingOrganizations, // 🚀 AHORA ES LISTA
    required List<String> callings,             // 🚀 AHORA ES LISTA
    required String ward,
    required UserRole role,
    String? phone,
    DateTime? birthDate,
  }) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = userCredential.user;

      if (user != null) {
        final cleanUsername = username.trim().toLowerCase();

        final newUser = UserModel(
          uid: user.uid,
          email: email,
          username: cleanUsername,
          firstName: firstName,
          lastName: lastName,
          gender: gender,
          isYSA: isYSA,
          organization: organization,
          callingOrganizations: callingOrganizations, // 🚀 Asignamos la lista
          callings: callings,                         // 🚀 Asignamos la lista
          ward: ward,
          role: role,
          isApproved: false,
          isActive: true,
          isRegistered: true,
          phone: phone,
          birthDate: birthDate,
        );

        // Guardamos el perfil en Firestore
        await _db.collection('users').doc(user.uid).set(newUser.toMap());

        // Guardamos el Username para el login inteligente
        await _db.collection('usernames').doc(cleanUsername).set({
          'email': email,
          'uid': user.uid,
        });

        return user;
      }
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Error al registrar usuario: $e';
    }
    return null;
  }

  // --- 5. CONTROL DE ACCESO ---
  Future<void> toggleUserAccess(String uid, bool isActive) async {
    await _db.collection('users').doc(uid).update({
      'isActive': isActive,
    });
  }

  // --- 6. UTILS Y RECUPERACIÓN ---
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  Future<String?> getEmailFromUsername(String username) async {
    try {
      final doc = await _db.collection('usernames').doc(username.trim().toLowerCase()).get();
      if (doc.exists) return doc.data()?['email'];
      return null;
    } catch (e) { return null; }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use': return 'Este correo ya está registrado.';
      case 'weak-password': return 'La contraseña es muy débil.';
      case 'user-disabled': return 'Usuario inhabilitado.';
      case 'user-not-found': return 'Usuario no encontrado.';
      case 'wrong-password': return 'Contraseña incorrecta.';
      default: return 'Error: ${e.message}';
    }
  }
}