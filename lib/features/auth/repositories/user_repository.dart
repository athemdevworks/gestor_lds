import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gestor_lds/features/auth/models/user_model.dart';

class UserRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // El nombre de la colección debe coincidir con las reglas de seguridad
  static const String _userCollection = 'users';

  // 1. Obtiene el Stream del Modelo de Usuario en tiempo real
  Stream<UserModel?> streamCurrentUserModel() {
    final userId = _auth.currentUser?.uid;

    // Si no hay nadie logueado, retorna un stream vacío
    if (userId == null) {
      return Stream.value(null);
    }

    // Escucha el documento del usuario y lo mapea al objeto UserModel
    return _db.collection(_userCollection)
        .doc(userId)
        .snapshots()
        .map((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        // Usamos el constructor 'fromMap' que creamos
        return UserModel.fromMap(snapshot.data()!);
      }
      return null; // El documento no existe (raro, pero posible)
    });
  }
}