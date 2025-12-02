import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart'; // Tu modelo de usuario

class UserService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // 1. OBTENER STREAM DE TODOS LOS USUARIOS ACTIVOS (Ordenados por apellidos)
  Stream<List<UserModel>> streamActiveUsers() {
    return _db.collection('users')
        .where('status', isEqualTo: 'active') // SOLO usuarios aprobados
        .orderBy('apellidos')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => UserModel.fromMap(doc.data())).toList());
  }

  // 2. OBTENER USUARIOS POR ESTADO (Para la pantalla de admin)
  Stream<List<UserModel>> streamUsersByStatus(String status) {
    return _db.collection('users')
        .where('status', isEqualTo: status)
        .orderBy('apellidos') // Aprovechamos el índice que ya creaste
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => UserModel.fromMap(doc.data())).toList());
  }

  // 3. ACTUALIZAR ROL Y ESTADO (Aprobar / Cambiar llamamiento)
  Future<void> updateUserAccess(String uid, UserRole newRole, String newStatus, String newCalling) async {
    await _db.collection('users').doc(uid).update({
      'role': newRole.name,
      'status': newStatus,
      'calling': newCalling, // También permitimos corregir el llamamiento
    });
  }

}