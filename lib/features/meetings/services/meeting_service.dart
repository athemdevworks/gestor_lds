import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gestor_lds/features/meetings/models/meeting_model.dart';
import 'package:gestor_lds/features/meetings/utils/meeting_types.dart';
import 'package:gestor_lds/features/meetings/models/sacrament_agenda_model.dart';
import '../models/agenda_item_model.dart';

class MeetingService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const String _collectionName = 'meetings';

  // 1. CREAR / GUARDAR
  Future<void> saveMeeting({
    required MeetingType type,
    required DateTime date,
    required String time,
    required String presidedBy,
    required String directedBy,
    String? organization,
    SacramentAgendaModel? sacramentAgenda,
    List<AgendaItemModel>? agendaItems,
    List<String>? commitments,
  }) async {
    final docRef = _db.collection(_collectionName).doc();

    final newMeeting = MeetingModel(
      id: docRef.id,
      type: type,
      date: date,
      time: time,
      presidedBy: presidedBy,
      directedBy: directedBy,
      organization: organization,
      sacramentAgenda: sacramentAgenda,
      agendaItems: agendaItems,
      commitments: commitments,
    );

    await docRef.set(newMeeting.toMap());
  }

  // --- NUEVOS MÉTODOS DE CONSULTA (Próximas vs Historial) ---

  // A. OBTENER PRÓXIMAS REUNIONES (Desde Hoy en adelante)
  Stream<List<MeetingModel>> getUpcomingMeetings() {
    final now = DateTime.now();
    // Normalizamos a las 00:00:00 horas para no perder reuniones de hoy
    final todayStart = DateTime(now.year, now.month, now.day);

    return _db
        .collection(_collectionName)
        .where('date', isGreaterThanOrEqualTo: todayStart)
        .orderBy('date', descending: false) // La más cercana primero (Ascendente)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => MeetingModel.fromMap(doc.data(), doc.id))
        .toList());
  }

  // B. OBTENER HISTORIAL (Pasadas, con límite de fecha)
  Stream<List<MeetingModel>> getHistoryMeetings(DateTime limitDate) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);

    return _db
        .collection(_collectionName)
        .where('date', isLessThan: todayStart) // Solo pasadas
        .where('date', isGreaterThanOrEqualTo: limitDate) // Límite del filtro (ej: 1 mes)
        .orderBy('date', descending: true) // La más reciente primero
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => MeetingModel.fromMap(doc.data(), doc.id))
        .toList());
  }

  // (Mantenemos el general por si acaso, aunque usaremos los de arriba)
  Stream<List<MeetingModel>> getMeetings() {
    return _db
        .collection(_collectionName)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return MeetingModel.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  // 2. ACTUALIZAR
  Future<void> updateMeeting({
    required String id,
    required MeetingType type,
    required DateTime date,
    required String time,
    required String presidedBy,
    required String directedBy,
    String? organization,
    SacramentAgendaModel? sacramentAgenda,
    List<AgendaItemModel>? agendaItems,
    List<String>? commitments,
  }) async {
    final updatedMeeting = MeetingModel(
      id: id,
      type: type,
      date: date,
      time: time,
      presidedBy: presidedBy,
      directedBy: directedBy,
      organization: organization,
      sacramentAgenda: sacramentAgenda,
      agendaItems: agendaItems,
      commitments: commitments,
    );

    final docRef = _db.collection(_collectionName).doc(id);

    await docRef.set(
        updatedMeeting.toMap(),
        SetOptions(merge: true)
    );
  }

  // 3. ELIMINAR
  Future<void> deleteMeeting(String meetingId) async {
    await _db.collection(_collectionName).doc(meetingId).delete();
  }
}