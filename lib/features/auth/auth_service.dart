import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gestor_lds/features/auth/models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // 1. Registro (Actualizado para el nuevo UserModel en Español)
  Future<User?> registerUser({
    required String email,
    required String password,
    required String username,
    required String nombres,
    required String apellidos,
    required String calling,
    required String organization, // <--- NUEVO
    required UserRole role,       // <--- NUEVO (Enum)
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
          organization: organization, // Guardamos la organización
          role: role,                 // Guardamos el rol (obispado, lider, etc.)
          isApproved: false,          // Por defecto NO aprobado
        );

        await _db.collection('users').doc(user.uid).set(newUser.toMap());
        return user;
      }
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message);
    }
    return null;
  }

  // 2. Login
  Future<User?> signInWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message);
    }
  }

  // 3. Stream de Usuario
  Stream<User?> get userStream => _auth.authStateChanges();

  // 4. Cerrar Sesión
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // 5. Recuperar Contraseña
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // 6. Buscar email por usuario
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

  // 7. OBTENER DATOS COMPLETOS DEL USUARIO (Para el AuthWrapper)
  Stream<UserModel?> getUserData(String uid) {
    return _db.collection('users').doc(uid).snapshots().map((snapshot) {
      if (snapshot.exists) {
        return UserModel.fromMap(snapshot.data()!);
      }
      return null;
    });
  }


}