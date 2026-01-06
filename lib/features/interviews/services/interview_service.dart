import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gestor_lds/features/interviews/models/interview_model.dart';

class InterviewService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String _collection = 'interview_slots';

  // 1. CREAR UN CUPO (Solo Obispado)
  Future<void> createSlot({
    required DateTime start,
    required int durationMinutes,
    required String adminId,
    required String role,
  }) async {
    final endTime = start.add(Duration(minutes: durationMinutes));

    await _db.collection(_collection).add({
      'startTime': Timestamp.fromDate(start),
      'endTime': Timestamp.fromDate(endTime),
      'isReserved': false,
      'memberId': null,
      'memberName': null,
      'note': null,
      'createdBy': adminId,
      'interviewerRole': role,
    });
  }

  // 2. LEER CUPOS DISPONIBLES (Para que el miembro elija)
  // Filtramos solo los futuros y que NO estén reservados
  Stream<List<InterviewModel>> getAvailableSlots() {
    final now = DateTime.now();
    return _db
        .collection(_collection)
        .where('startTime', isGreaterThan: Timestamp.fromDate(now)) // Solo futuros
        .where('isReserved', isEqualTo: false) // Solo libres
        .orderBy('startTime')
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => InterviewModel.fromMap(doc.data(), doc.id))
        .toList());
  }

  // 3. LEER TODOS LOS CUPOS (Para que el Obispado vea su agenda)
  Stream<List<InterviewModel>> getAllSlots() {
    final now = DateTime.now(); // O podrías mostrar desde inicio de mes
    return _db
        .collection(_collection)
        .where('startTime', isGreaterThan: Timestamp.fromDate(now))
        .orderBy('startTime')
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => InterviewModel.fromMap(doc.data(), doc.id))
        .toList());
  }

  // 4. RESERVAR UN CUPO (El miembro hace click)
  Future<void> reserveSlot({
    required String slotId,
    required String userId,
    required String userName,
    required String reason,
  }) async {
    await _db.collection(_collection).doc(slotId).update({
      'isReserved': true,
      'memberId': userId,
      'memberName': userName,
      'note': reason,
    });
  }

  // 5. CANCELAR RESERVA (Liberar el cupo)
  Future<void> cancelReservation(String slotId) async {
    await _db.collection(_collection).doc(slotId).update({
      'isReserved': false,
      'memberId': null,
      'memberName': null,
      'note': null,
    });
  }

  // 6. BORRAR CUPO (Obispado elimina el horario)
  Future<void> deleteSlot(String slotId) async {
    await _db.collection(_collection).doc(slotId).delete();
  }

  // 7. VER MIS CITAS (Lo que ha reservado el usuario actual)
  Stream<List<InterviewModel>> getMyAppointments(String userId) {
    // Nota: Esto requerirá crear un índice nuevo en Firebase: memberId ASC, startTime ASC
    return _db
        .collection(_collection)
        .where('memberId', isEqualTo: userId)
        .orderBy('startTime')
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => InterviewModel.fromMap(doc.data(), doc.id))
        .toList());
  }

}
