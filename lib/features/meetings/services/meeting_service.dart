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
    // 🚀 NUEVO DNI GEOGRÁFICO REQUERIDO
    required String ward,
    String? organization,

    // --- NUEVOS CAMPOS v1.10 ---
    String? openingHymn,
    String? openingPrayer,
    String? closingHymn,
    String? closingPrayer,
    // ---------------------------

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
      ward: ward, // 🚀 GUARDANDO JURISDICCIÓN
      organization: organization,

      // --- PASAR AL MODELO ---
      openingHymn: openingHymn,
      openingPrayer: openingPrayer,
      closingHymn: closingHymn,
      closingPrayer: closingPrayer,
      // -----------------------

      sacramentAgenda: sacramentAgenda,
      agendaItems: agendaItems,
      commitments: commitments,
    );

    await docRef.set(newMeeting.toMap());
  }

  // A. OBTENER PRÓXIMAS REUNIONES (Desde Hoy en adelante)
  Stream<List<MeetingModel>> getUpcomingMeetings() {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);

    return _db
        .collection(_collectionName)
        .where('date', isGreaterThanOrEqualTo: todayStart)
        .orderBy('date', descending: false)
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
        .where('date', isLessThan: todayStart)
        .where('date', isGreaterThanOrEqualTo: limitDate)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => MeetingModel.fromMap(doc.data(), doc.id))
        .toList());
  }

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
    // 🚀 NUEVO DNI GEOGRÁFICO REQUERIDO
    required String ward,
    String? organization,

    // --- NUEVOS CAMPOS v1.10 ---
    String? openingHymn,
    String? openingPrayer,
    String? closingHymn,
    String? closingPrayer,
    // ---------------------------

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
      ward: ward, // 🚀 ACTUALIZANDO JURISDICCIÓN
      organization: organization,

      // --- PASAR AL MODELO ---
      openingHymn: openingHymn,
      openingPrayer: openingPrayer,
      closingHymn: closingHymn,
      closingPrayer: closingPrayer,
      // -----------------------

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

  // ==========================================
  // 📊 ESTADÍSTICAS Y MINERÍA DE DATOS
  // ==========================================

  /// Extrae y cuenta todos los himnos cantados en un AÑO específico (Filtro por Barrio)
  Future<List<MapEntry<String, List<DateTime>>>> getYearlyHymnRanking(int year, String targetWard) async {
    final startDate = DateTime(year, 1, 1);
    final endDate = DateTime(year + 1, 1, 1);

    // 🚀 AÑADIMOS EL FILTRO GEOGRÁFICO A LA CONSULTA
    Query query = _db
        .collection(_collectionName)
        .where('date', isGreaterThanOrEqualTo: startDate)
        .where('date', isLessThan: endDate);

    if (targetWard != 'Todos') {
      query = query.where('ward', isEqualTo: targetWard);
    }

    final snapshot = await query.get();

    final meetings = snapshot.docs
        .map((doc) => MeetingModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList();

    final Map<String, List<DateTime>> hymnDates = {};

    void addHymn(String? hymn, DateTime meetingDate) {
      if (hymn != null && hymn.trim().isNotEmpty && hymn.toLowerCase() != 'por definir') {
        String cleanHymn = hymn.trim().toUpperCase().replaceAll(RegExp(r'\s+'), ' ');
        hymnDates.putIfAbsent(cleanHymn, () => []);
        hymnDates[cleanHymn]!.add(meetingDate);
      }
    }

    for (var meeting in meetings) {
      if (meeting.type == MeetingType.sacramental && meeting.sacramentAgenda != null) {
        addHymn(meeting.sacramentAgenda!.openingHymn, meeting.date);
        addHymn(meeting.sacramentAgenda!.sacramentHymn, meeting.date);
        addHymn(meeting.sacramentAgenda!.intermediateHymn, meeting.date);
        addHymn(meeting.sacramentAgenda!.closingHymn, meeting.date);
      } else {
        addHymn(meeting.openingHymn, meeting.date);
        addHymn(meeting.closingHymn, meeting.date);
      }
    }

    var sortedRanking = hymnDates.entries.toList()
      ..sort((a, b) {
        int numA = int.tryParse(a.key.split('.').first.trim()) ?? 9999;
        int numB = int.tryParse(b.key.split('.').first.trim()) ?? 9999;
        if (numA == numB) return a.key.compareTo(b.key);
        return numA.compareTo(numB);
      });

    return sortedRanking.map((entry) {
      String titleCase = entry.key.split(' ').map((word) {
        if (word.isEmpty) return word;
        return word[0].toUpperCase() + word.substring(1).toLowerCase();
      }).join(' ');

      entry.value.sort((a, b) => a.compareTo(b));
      return MapEntry(titleCase, entry.value);
    }).toList();
  }

  // ==========================================
  // 🗣️ HISTORIAL DE DISCURSANTES
  // ==========================================

  /// Extrae el historial de todos los discursantes en un AÑO específico (Filtro por Barrio)
  Future<List<MapEntry<String, List<Map<String, dynamic>>>>> getYearlySpeakerHistory(int year, String targetWard) async {
    final startDate = DateTime(year, 1, 1);
    final endDate = DateTime(year + 1, 1, 1);

    // 🚀 AÑADIMOS EL FILTRO GEOGRÁFICO A LA CONSULTA
    Query query = _db
        .collection(_collectionName)
        .where('date', isGreaterThanOrEqualTo: startDate)
        .where('date', isLessThan: endDate)
        .where('type', isEqualTo: MeetingType.sacramental.name);

    if (targetWard != 'Todos') {
      query = query.where('ward', isEqualTo: targetWard);
    }

    final snapshot = await query.get();

    final meetings = snapshot.docs
        .map((doc) => MeetingModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList();

    final Map<String, List<Map<String, dynamic>>> speakerHistory = {};

    void addSpeaker(String? name, String? topic, DateTime date) {
      if (name != null && name.trim().isNotEmpty && name.toLowerCase() != 'por definir') {
        String cleanName = name.trim().split(' ').map((word) {
          if (word.isEmpty) return word;
          return word[0].toUpperCase() + word.substring(1).toLowerCase();
        }).join(' ');

        String finalTopic = (topic != null && topic.trim().isNotEmpty)
            ? topic.trim()
            : 'Tema Libre / No especificado';

        speakerHistory.putIfAbsent(cleanName, () => []);
        speakerHistory[cleanName]!.add({
          'date': date,
          'topic': finalTopic,
        });
      }
    }

    for (var meeting in meetings) {
      if (meeting.sacramentAgenda != null && !meeting.sacramentAgenda!.isFastAndTestimony) {
        final agenda = meeting.sacramentAgenda!;
        addSpeaker(agenda.firstSpeakerName, agenda.firstSpeakerTopic, meeting.date);
        addSpeaker(agenda.secondSpeakerName, agenda.secondSpeakerTopic, meeting.date);

        if (agenda.hasThirdSpeaker) {
          addSpeaker(agenda.thirdSpeakerName, agenda.thirdSpeakerTopic, meeting.date);
        }
      }
    }

    var sortedRanking = speakerHistory.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    for (var entry in sortedRanking) {
      entry.value.sort((a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));
    }

    return sortedRanking;
  }
}