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
        .orderBy('apellidos') // Orden alfabético
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => UserModel.fromMap(doc.data(), doc.id))
        .toList());
  }

  // 2. STREAM DE ACTIVOS
  Stream<List<UserModel>> streamActiveUsers() {
    return streamUsersByApproval(true);
  }

  // 3. ACTUALIZACIÓN MASIVA DE ACCESO (CORREGIDO)
  Future<void> updateUserAccess({
    required String uid,
    required UserRole role,
    required bool isApproved,
    required String calling,
    // --- NUEVO PARÁMETRO ---
    bool? isActive, // <--- Agregado para recibir el estado de la UI
    String? phoneNumber,
  }) async {

    // Preparamos los datos
    final Map<String, dynamic> data = {
      'role': role.toString().split('.').last,
      'isApproved': isApproved,
      'calling': calling,
      'phoneNumber': phoneNumber,
    };

    // Si nos enviaron el estado (Activo/Inactivo), lo agregamos al mapa
    if (isActive != null) {
      data['isActive'] = isActive;
    }

    // Actualizamos en Firestore
    await _db.collection(_collection).doc(uid).update(data);
  }

  // 4. ACTUALIZAR PERFIL PERSONAL
  Future<void> updateUserProfile({
    required String uid,
    required String nombres,
    required String apellidos,
    required String calling,
    String? phoneNumber,
    DateTime? birthDate,
  }) async {
    await _db.collection(_collection).doc(uid).update({
      'nombres': nombres,
      'apellidos': apellidos,
      'calling': calling,
      'phoneNumber': phoneNumber,
      'birthDate': birthDate != null ? Timestamp.fromDate(birthDate) : null,
    });
  }

  // 5. VERIFICAR DUPLICADOS
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

  // 6. ELIMINAR USUARIO
  Future<void> deleteUser(String uid) async {
    await _db.collection(_collection).doc(uid).delete();
  }
}