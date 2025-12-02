import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gestor_lds/features/auth/models/user_model.dart'; // Crearemos esto en el siguiente paso

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // 1. Registro (Crea el usuario en Auth y en Firestore con status: pending)
  Future<User?> registerWithEmailAndPassword(
      String email,
      String password,
      String username,
      String nombres,
      String apellidos,
      String calling, // Ahora se usa 'calling'
      ) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = userCredential.user;

      if (user != null) {
        // CORRECCIÓN: Se inicializa UserModel con todos los campos requeridos
        final newUser = UserModel(
          uid: user.uid,
          email: email,
          username: username, // <-- ¡CORREGIDO!
          nombres: nombres, // <-- ¡CORREGIDO!
          apellidos: apellidos, // <-- ¡CORREGIDO!
          role: UserRole.pending, // <-- ¡CORREGIDO! Usamos el ENUM
          status: 'pending', // Usamos String para el status
          calling: calling, // <-- ¡CORREGIDO!
        );

        await _db.collection('users').doc(user.uid).set(newUser.toMap());

        return user;
      }
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message);
    }
    return null;
  }

  // 2. Login (Solo Auth, la verificación de status/rol se hace en la UI)
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

  // 3. Obtener el Stream de estado (útil para la navegación)
  Stream<User?> get userStream => _auth.authStateChanges();

  // 4. Cerrar Sesión
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // 5. RECUPERAR CONTRASEÑA
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message);
    }
  }
}