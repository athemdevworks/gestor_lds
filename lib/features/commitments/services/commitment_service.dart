import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gestor_lds/features/commitments/models/commitment_model.dart';

class CommitmentService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const String _collectionName = 'commitments';

  // 1. CREAR / AGREGAR un compromiso
  Future<void> addCommitment({
    required String meetingId,
    required String description,
    required String assignedToUid,
    required String assignedToName,
    required DateTime dueDate,
    String? agendaItemId,
    String? agendaItemTopic,
  }) async {
    final docRef = _db.collection(_collectionName).doc();

    final newCommitment = CommitmentModel(
      id: docRef.id,

      // --- CORRECCIÓN CRÍTICA 1: ¡DESCOMENTADO! ---
      meetingId: meetingId,
      // -------------------------------------------

      description: description,
      assignedTo: assignedToUid,
      responsibleName: assignedToName,
      dueDate: dueDate,
      agendaItemId: agendaItemId,

      // --- CORRECCIÓN CRÍTICA 2: ¡DESCOMENTADO! ---
      agendaItemTopic: agendaItemTopic,
      // --------------------------------------------

      isCompleted: false,
    );

    await docRef.set(newCommitment.toMap());
  }

  // 2. OBTENER COMPROMISOS ASIGNADOS A UN LÍDER
  Stream<List<CommitmentModel>> getCommitmentsForUser(String userId) {
    return _db.collection(_collectionName)
        .where('assignedTo', isEqualTo: userId)
        .orderBy('dueDate', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return CommitmentModel.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  // 3. MARCAR COMO COMPLETADO
  Future<void> toggleCompletion(String commitmentId, bool isCompleted) async {
    await _db.collection(_collectionName).doc(commitmentId).update({
      'isCompleted': isCompleted,
    });
  }

  // 4. OBTENER COMPROMISOS DE UNA REUNIÓN ESPECÍFICA
  Stream<List<CommitmentModel>> getCommitmentsByMeeting(String meetingId) {
    return _db.collection(_collectionName)
        .where('meetingId', isEqualTo: meetingId) // Ahora sí encontrará coincidencias
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return CommitmentModel.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  // 5. ACTUALIZAR
  Future<void> updateCommitment(CommitmentModel commitment) async {
    await _db.collection(_collectionName).doc(commitment.id).update(commitment.toMap());
  }

  // 6. ELIMINAR
  Future<void> deleteCommitment(String commitmentId) async {
    await _db.collection(_collectionName).doc(commitmentId).delete();
  }
}