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
      // Asegúrate de que tu modelo tenga este campo o elimínalo si no lo usas
      // meetingId: meetingId,

      description: description,

      // Nota: Si en tu modelo le pusiste 'assignedTo', cambia esto aquí:
      assignedTo: assignedToUid,

      // Nota: Si en tu modelo le pusiste 'responsibleName', cambia esto aquí:
      responsibleName: assignedToName,

      dueDate: dueDate,
      agendaItemId: agendaItemId,
      // agendaItemTopic: agendaItemTopic, // Si tu modelo no tiene esto, coméntalo

      isCompleted: false, // Valor por defecto
    );

    await docRef.set(newCommitment.toMap());
  }

  // 2. OBTENER COMPROMISOS ASIGNADOS A UN LÍDER
  Stream<List<CommitmentModel>> getCommitmentsForUser(String userId) {
    return _db.collection(_collectionName)
        .where('assignedTo', isEqualTo: userId) // Ojo: verifica si en BD es 'assignedTo' o 'assignedToUid'
        .orderBy('dueDate', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        // --- CORRECCIÓN AQUÍ ---
        // Pasamos los datos Y el ID por separado
        return CommitmentModel.fromMap(doc.data(), doc.id);
        // -----------------------
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
    // Ojo: verifica si tu modelo/BD usa 'meetingId'.
    // Si no lo guardamos en el modelo anterior, esta consulta podría no traer nada
    // a menos que el campo exista en Firebase.
        .where('meetingId', isEqualTo: meetingId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        // --- CORRECCIÓN AQUÍ ---
        return CommitmentModel.fromMap(doc.data(), doc.id);
        // -----------------------
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