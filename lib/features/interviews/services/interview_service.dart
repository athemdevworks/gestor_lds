import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gestor_lds/features/interviews/models/interview_model.dart';

class InterviewService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String _collection = 'interview_slots';

  // 1. CREAR UN CUPO INDIVIDUAL (Obispado / Administrador)
  Future<void> createSlot({
    required DateTime start,
    required int durationMinutes,
    required String adminId,
    required String role,
    required String ward,
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
      'ward': ward,
    });
  }

  // 1.5 CREAR BLOQUE DE CUPOS MASIVO (Batch)
  Future<void> createSlotBlock({
    required DateTime startTime,
    required DateTime endTime,
    required int durationMinutes,
    required String adminId,
    required String role,
    required String ward,
  }) async {
    final batch = _db.batch();
    DateTime currentStart = startTime;

    while (currentStart.isBefore(endTime)) {
      final currentEnd = currentStart.add(Duration(minutes: durationMinutes));

      if (currentEnd.isAfter(endTime)) break;

      final docRef = _db.collection(_collection).doc();

      batch.set(docRef, {
        'startTime': Timestamp.fromDate(currentStart),
        'endTime': Timestamp.fromDate(currentEnd),
        'isReserved': false,
        'memberId': null,
        'memberName': null,
        'note': null,
        'createdBy': adminId,
        'interviewerRole': role,
        'ward': ward,
      });

      currentStart = currentEnd;
    }

    await batch.commit();
  }

  // 2. LEER CUPOS DISPONIBLES (Barrio local + Presidencia de Estaca)
  Stream<List<InterviewModel>> getAvailableSlots({String? ward}) {
    final now = DateTime.now();
    return _db
        .collection(_collection)
        .where('startTime', isGreaterThan: Timestamp.fromDate(now))
        .where('isReserved', isEqualTo: false)
        .orderBy('startTime')
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => InterviewModel.fromMap(doc.data(), doc.id))
          .toList();

      if (ward == null || ward.trim().isEmpty) return list;

      // 🚀 Muestra citas de su propio barrio Y citas abiertas por la Estaca
      return list.where((slot) =>
      slot.ward.isEmpty ||
          slot.ward == ward ||
          slot.ward.toLowerCase() == 'estaca').toList();
    });
  }

  // 3. LEER TODOS LOS CUPOS (Para gestión de agenda)
  Stream<List<InterviewModel>> getAllSlots({String? ward, bool isStakeScope = false}) {
    final now = DateTime.now();
    return _db
        .collection(_collection)
        .where('startTime', isGreaterThan: Timestamp.fromDate(now))
        .orderBy('startTime')
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => InterviewModel.fromMap(doc.data(), doc.id))
          .toList();

      if (isStakeScope) {
        // Líderes de estaca gestionan los turnos de 'Estaca'
        return list.where((slot) => slot.ward.toLowerCase() == 'estaca').toList();
      }

      if (ward == null || ward.trim().isEmpty) return list;

      // Obispados gestionan los de su propio barrio
      return list.where((slot) => slot.ward.isEmpty || slot.ward == ward).toList();
    });
  }

  // 4. RESERVAR UN CUPO (El miembro confirma su cita)
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

  // 5. CANCELAR RESERVA (Liberar el turno)
  Future<void> cancelReservation(String slotId) async {
    await _db.collection(_collection).doc(slotId).update({
      'isReserved': false,
      'memberId': null,
      'memberName': null,
      'note': null,
    });
  }

  // 6. BORRAR CUPO POR COMPLETO
  Future<void> deleteSlot(String slotId) async {
    await _db.collection(_collection).doc(slotId).delete();
  }

  // 7. MIS CITAS AGENDADAS (Utiliza el índice memberId + startTime)
  Stream<List<InterviewModel>> getMyAppointments(String userId) {
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