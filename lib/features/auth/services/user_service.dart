import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gestor_lds/features/auth/models/user_model.dart';

class UserService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String _collection = 'users';

  // 1. STREAM UNIFICADO POR ESTADO (Para tus Tabs de Pendientes/Aprobados)
  Stream<List<UserModel>> streamUsersByApproval(bool isApproved) {
    return _db
        .collection(_collection)
        .where('isApproved', isEqualTo: isApproved)
        .orderBy('apellidos') // Orden alfabético
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => UserModel.fromMap(doc.data(), doc.id))
        .toList());
  }

  // 2. STREAM DE ACTIVOS (Para Dropdowns y Modales de Compromisos)
  Stream<List<UserModel>> streamActiveUsers() {
    return streamUsersByApproval(true); // Reutilizamos la lógica
  }

  // 3. ACTUALIZACIÓN MASIVA DE ACCESO (Para tu _EditUserDialog)
  Future<void> updateUserAccess({
    required String uid,
    required UserRole role,
    required bool isApproved,
    required String calling,
    String? phoneNumber,
  }) async {
    await _db.collection(_collection).doc(uid).update({
      'role': role.toString().split('.').last, // Convertimos Enum a String
      'isApproved': isApproved,
      'calling': calling,
      'phoneNumber': phoneNumber,
    });
  }

  // 4. ACTUALIZAR PERFIL PERSONAL (Para ProfileScreen)
  Future<void> updateUserProfile({
    required String uid,
    required String nombres,
    required String apellidos,
    required String calling,
    String? phoneNumber,
    DateTime? birthDate, // <--- 1. Recibimos el dato
  }) async {
    await _db.collection(_collection).doc(uid).update({
      'nombres': nombres,
      'apellidos': apellidos,
      'calling': calling,
      'phoneNumber': phoneNumber,
      'birthDate': birthDate != null ? Timestamp.fromDate(birthDate) : null,
    });
  }

  // 5. VERIFICAR DUPLICADOS (Para Registro)
  Future<bool> checkDuplicateUser(String nombres, String apellidos) async {
    try {
      final query = await _db.collection(_collection)
          .where('nombres', isEqualTo: nombres.trim())
          .where('apellidos', isEqualTo: apellidos.trim())
          .limit(1)
          .get();

      return query.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // 6. ELIMINAR USUARIO (Por si acaso lo necesitas)
  Future<void> deleteUser(String uid) async {
    await _db.collection(_collection).doc(uid).delete();
  }
}