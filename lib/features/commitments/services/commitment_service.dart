import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gestor_lds/features/commitments/models/commitment_model.dart';

class CommitmentService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const String _collectionName = 'commitments';

// 1. CREAR / AGREGAR un compromiso desde una reunión
  Future<void> addCommitment({
    required String meetingId,
    required String description,
    required String assignedToUid,
    required String assignedToName,
    required DateTime dueDate,
    // AÑADE ESTOS DOS PARÁMETROS:
    String? agendaItemId,
    String? agendaItemTopic,
  }) async {
    final docRef = _db.collection(_collectionName).doc();

    final newCommitment = CommitmentModel(
      id: docRef.id,
      meetingId: meetingId,
      description: description,
      assignedToUid: assignedToUid,
      assignedToName: assignedToName,
      dueDate: dueDate,

      // PASA LOS DATOS AL MODELO:
      agendaItemId: agendaItemId,
      agendaItemTopic: agendaItemTopic,

      createdAt: DateTime.now(),
    );

    await docRef.set(newCommitment.toMap());
  }

  // 2. OBTENER COMPROMISOS ASIGNADOS A UN LÍDER (para el dashboard)
  Stream<List<CommitmentModel>> getCommitmentsForUser(String userId) {
    return _db.collection(_collectionName)
        .where('assignedToUid', isEqualTo: userId)
        .orderBy('dueDate', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => CommitmentModel.fromMap(doc.data())).toList();
    });
  }

  // 3. MARCAR COMO COMPLETADO
  Future<void> toggleCompletion(String commitmentId, bool isCompleted) async {
    await _db.collection(_collectionName).doc(commitmentId).update({
      'isCompleted': isCompleted,
    });
  }
}