import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gestor_lds/features/auth/models/user_model.dart';

class UserService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String _collection = 'users';

  // 1. LISTAR USUARIOS POR ESTADO DE APROBACIÓN (Optimizado con Stream)
  // Usado en: UserManagementScreen
  Stream<List<UserModel>> streamUsersByApproval(bool isApproved) {
    return _db
        .collection(_collection)
        .where('isApproved', isEqualTo: isApproved) // Filtra en el servidor
        .orderBy('apellidos') // Ordena alfabéticamente
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        // Mapeo seguro
        return UserModel.fromMap(doc.data());
      }).toList();
    });
  }

  // 2. ACTUALIZAR PERMISO DE ACCESO (ADMIN)
  // Usado en: UserManagementScreen (Diálogo de edición)
  Future<void> updateUserAccess({
    required String uid,
    required UserRole role,
    required bool isApproved,
    required String calling,
  }) async {
    try {
      await _db.collection(_collection).doc(uid).update({
        'role': role.name,
        'isApproved': isApproved,
        'calling': calling,
      });
    } catch (e) {
      throw Exception('Error actualizando permisos: $e');
    }
  }

  // 3. ACTUALIZAR PERFIL PERSONAL
  // Usado en: ProfileScreen
  Future<void> updateUserProfile({
    required String uid,
    required String nombres,
    required String apellidos,
    required String calling,
  }) async {
    try {
      await _db.collection(_collection).doc(uid).update({
        'nombres': nombres,
        'apellidos': apellidos,
        'calling': calling,
        // Nota: No actualizamos 'organization' aquí para evitar inconsistencias de seguridad,
        // pero podrías agregarlo si lo necesitas.
      });
    } catch (e) {
      throw Exception('Error actualizando perfil: $e');
    }
  }

  // 4. OBTENER DATOS DE UN SOLO USUARIO (Future)
  // Útil si necesitas consultar datos sin stream
  Future<UserModel?> getUserById(String uid) async {
    final doc = await _db.collection(_collection).doc(uid).get();
    if (doc.exists) {
      return UserModel.fromMap(doc.data()!);
    }
    return null;
  }

  // 5. HELPER: OBTENER SOLO USUARIOS ACTIVOS
  // Este es el método que busca el NewCommitmentModal
  Stream<List<UserModel>> streamActiveUsers() {
    return streamUsersByApproval(true);
  }

}