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

  // 1.5 CREAR BLOQUE DE CUPOS (Ej: De 10:00 a 12:00 cada 15 min)
  Future<void> createSlotBlock({
    required DateTime startTime, // Ej: 10:00 AM
    required DateTime endTime,   // Ej: 12:00 PM
    required int durationMinutes,// Ej: 15 minutos
    required String adminId,
    required String role,
  }) async {
    final batch = _db.batch(); // Inicia un paquete de escrituras
    DateTime currentStart = startTime;

    // Mientras la hora actual no supere la hora de fin seleccionada...
    while (currentStart.isBefore(endTime)) {
      final currentEnd = currentStart.add(Duration(minutes: durationMinutes));

      // Seguridad: No crear un turno si se pasa de la hora de cierre
      if (currentEnd.isAfter(endTime)) break;

      final docRef = _db.collection(_collection).doc(); // Genera un ID automático

      // Agrega este turno al paquete
      batch.set(docRef, {
        'startTime': Timestamp.fromDate(currentStart),
        'endTime': Timestamp.fromDate(currentEnd),
        'isReserved': false,
        'memberId': null,
        'memberName': null,
        'note': null,
        'createdBy': adminId,
        'interviewerRole': role,
      });

      currentStart = currentEnd; // Avanza al siguiente turno
    }

    // Sube los 5, 10 o 20 turnos a Firebase en una sola petición ultra rápida
    await batch.commit();
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
