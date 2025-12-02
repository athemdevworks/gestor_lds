import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart'; // Tu modelo de usuario

class UserService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Obtiene un Stream de todos los usuarios activos, ordenados por apellido
  Stream<List<UserModel>> streamActiveUsers() {
    return _db.collection('users')
        .where('status', isEqualTo: 'active') // SOLO usuarios aprobados
        .orderBy('apellidos')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => UserModel.fromMap(doc.data())).toList());
  }
}