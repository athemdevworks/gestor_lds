import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gestor_lds/features/auth/models/user_model.dart';

class UserService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String _collection = 'users';

  // 1. STREAM UNIFICADO POR ESTADO
  Stream<List<UserModel>> streamUsersByApproval(bool isApproved) {
    return _db
        .collection(_collection)
        .where('isApproved', isEqualTo: isApproved)
        .orderBy('lastName')
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => UserModel.fromMap(doc.data(), doc.id))
        .toList());
  }

  // 2. STREAM DE ACTIVOS
  Stream<List<UserModel>> streamActiveUsers() {
    return streamUsersByApproval(true);
  }

  // 3. ACTUALIZACIÓN MASIVA DE ACCESO (🚀 Adaptado a Listas y 'phone')
  Future<void> updateUserAccess({
    required String uid,
    required UserRole role,
    required bool isApproved,
    required List<String> callings,             // 🚀 AHORA ES LISTA
    required List<String> callingOrganizations, // 🚀 NUEVA LISTA DE ÁREAS
    bool? isActive,
    String? phone,                              // 🚀 ACTUALIZADO A 'phone'
  }) async {

    final Map<String, dynamic> data = {
      'role': role.name,
      'isApproved': isApproved,
      'callings': callings,                         // 🚀 Guarda la lista
      'callingOrganizations': callingOrganizations, // 🚀 Guarda la lista
      'phone': phone,                               // 🚀 Guarda el teléfono
    };

    if (isActive != null) {
      data['isActive'] = isActive;
    }

    await _db.collection(_collection).doc(uid).update(data);
  }

  // 4. ACTUALIZAR PERFIL PERSONAL (🚀 Sin 'calling' y con 'phone')
  Future<void> updateUserProfile({
    required String uid,
    required String nombres,
    required String apellidos,
    required String? phone, // 🚀 ACTUALIZADO A 'phone'
    DateTime? birthDate,
    // 🚀 ELIMINADO EL 'calling' PORQUE YA NO SE EDITA DESDE EL PERFIL
  }) async {
    await _db.collection(_collection).doc(uid).update({
      'firstName': nombres,
      'lastName': apellidos,
      'phone': phone,           // 🚀 GUARDAMOS 'phone'
      'birthDate': birthDate != null ? Timestamp.fromDate(birthDate) : null,
    });
  }

  // 5. VERIFICAR DUPLICADOS
  Future<bool> checkDuplicateUser(String nombres, String apellidos) async {
    try {
      final query = await _db.collection(_collection)
          .where('firstName', isEqualTo: nombres.trim())
          .where('lastName', isEqualTo: apellidos.trim())
          .limit(1)
          .get();

      return query.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // 6. ELIMINAR USUARIO
  Future<void> deleteUser(String uid) async {
    await _db.collection(_collection).doc(uid).delete();
  }

  // ==============================================================
  // 7. APROBAR Y CHANCAR NOMBRES (EL VAR) - 🚀 Adaptado a Listas
  // ==============================================================
  Future<void> approveAndSyncName({
    required String uid,
    required String newFirstName,
    required String newLastName,
    required UserRole role,
    required List<String> callings,             // 🚀 AHORA ES LISTA
    required List<String> callingOrganizations, // 🚀 NUEVA LISTA
    String? phone,                              // 🚀 ACTUALIZADO A 'phone'
  }) async {
    try {
      await _db.collection(_collection).doc(uid).update({
        'firstName': newFirstName,
        'lastName': newLastName,
        'role': role.name,
        'isApproved': true,
        'isActive': true,
        'callings': callings,
        'callingOrganizations': callingOrganizations,
        'phone': phone,
      });
    } catch (e) {
      throw 'No se pudo aprobar y actualizar el nombre: $e';
    }
  }
}