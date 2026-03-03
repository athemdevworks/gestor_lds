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

  /// Extrae y cuenta todos los himnos cantados en un AÑO específico
  Future<List<MapEntry<String, int>>> getYearlyHymnRanking(int year) async {
    // 1. Definir el rango de TODO el año
    final startDate = DateTime(year, 1, 1);
    final endDate = DateTime(year + 1, 1, 1); // Primer día del año siguiente

    // 2. Traer todas las reuniones de ese año
    final snapshot = await _db
        .collection(_collectionName)
        .where('date', isGreaterThanOrEqualTo: startDate)
        .where('date', isLessThan: endDate)
        .get();

    final meetings = snapshot.docs
        .map((doc) => MeetingModel.fromMap(doc.data(), doc.id))
        .toList();

    // 3. Diccionario para contar los himnos
    final Map<String, int> hymnCounts = {};

    void addHymn(String? hymn) {
      if (hymn != null && hymn.trim().isNotEmpty && hymn.toLowerCase() != 'por definir') {
        // NORMALIZACIÓN DE DATOS (Para evitar duplicados)
        // 1. Quitar espacios extra al inicio y final
        // 2. Convertir todo a mayúsculas para igualar "Dios Vive" con "DIOS VIVE"
        // 3. Eliminar dobles espacios internos
        String cleanHymn = hymn.trim().toUpperCase().replaceAll(RegExp(r'\s+'), ' ');

        hymnCounts[cleanHymn] = (hymnCounts[cleanHymn] ?? 0) + 1;
      }
    }

    // 4. Escanear cada reunión y extraer los himnos
    for (var meeting in meetings) {
      // Himnos de Liderazgo
      addHymn(meeting.openingHymn);
      addHymn(meeting.closingHymn);

      // Himnos Sacamentales
      if (meeting.sacramentAgenda != null) {
        addHymn(meeting.sacramentAgenda!.openingHymn);
        addHymn(meeting.sacramentAgenda!.sacramentHymn);
        addHymn(meeting.sacramentAgenda!.intermediateHymn);
        addHymn(meeting.sacramentAgenda!.closingHymn);
      }
    }


    // 5. Ordenar por NÚMERO DE HIMNO (de menor a mayor)
    var sortedRanking = hymnCounts.entries.toList()
      ..sort((a, b) {
        // Extraemos el número que está antes del punto. Ej: "199. DIOS VIVE" -> 199
        int numA = int.tryParse(a.key.split('.').first.trim()) ?? 9999;
        int numB = int.tryParse(b.key.split('.').first.trim()) ?? 9999;

        // Si no tienen número o son iguales, desempata alfabéticamente
        if (numA == numB) {
          return a.key.compareTo(b.key);
        }
        return numA.compareTo(numB); // Orden ascendente (1, 2, 3...)
      });

    // Formatear a Title Case (Ej: "199. Dios Vive")
    return sortedRanking.map((entry) {
      String titleCase = entry.key.split(' ').map((word) {
        if (word.isEmpty) return word;
        return word[0].toUpperCase() + word.substring(1).toLowerCase();
      }).join(' ');
      return MapEntry(titleCase, entry.value);
    }).toList();
  }
}