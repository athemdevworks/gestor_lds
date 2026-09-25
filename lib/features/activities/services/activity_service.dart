import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gestor_lds/features/activities/models/activity_model.dart';

class ActivityService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String _collection = 'activities';

  // 1. CREAR (Generando ID único, guardando unidad y visibilidad)
  Future<void> saveActivity(ActivityModel activity) async {
    final docRef = _db.collection(_collection).doc();

    final newActivity = ActivityModel(
      id: docRef.id,
      title: activity.title,
      description: activity.description,
      date: activity.date,
      time: activity.time,
      location: activity.location,
      organization: activity.organization,
      ward: activity.ward,
      visibility: activity.visibility, // 🚀 'ward', 'stake' o 'leadership'
    );

    await docRef.set(newActivity.toMap());
  }

  // 2. ACTUALIZAR
  Future<void> updateActivity(ActivityModel activity) async {
    await _db.collection(_collection).doc(activity.id).update(activity.toMap());
  }

  // 3. ELIMINAR
  Future<void> deleteActivity(String id) async {
    await _db.collection(_collection).doc(id).delete();
  }

  // --- CONSULTAS CON AISLAMIENTO Y VISIBILIDAD POR ROL ---

  // A. PRÓXIMAS ACTIVIDADES
  Stream<List<ActivityModel>> getUpcomingActivities({
    String? userWard,
    bool isLeader = false,
  }) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);

    return _db
        .collection(_collection)
        .where('date', isGreaterThanOrEqualTo: todayStart)
        .orderBy('date', descending: false)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => ActivityModel.fromMap(doc.data(), doc.id))
          .toList();

      return list.where((a) => _canViewActivity(a, userWard, isLeader)).toList();
    });
  }

  // B. HISTORIAL
  Stream<List<ActivityModel>> getHistoryActivities(
      DateTime limitDate, {
        String? userWard,
        bool isLeader = false,
      }) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);

    return _db
        .collection(_collection)
        .where('date', isLessThan: todayStart)
        .where('date', isGreaterThanOrEqualTo: limitDate)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => ActivityModel.fromMap(doc.data(), doc.id))
          .toList();

      return list.where((a) => _canViewActivity(a, userWard, isLeader)).toList();
    });
  }

  // 🛡️ REGLA DE VISIBILIDAD INSTITUCIONAL
  bool _canViewActivity(ActivityModel a, String? userWard, bool isLeader) {
    // 1. Actividades exclusivas de liderazgo (Sumo Consejo, Obispados, etc.)
    if (a.visibility == 'leadership' && !isLeader) {
      return false;
    }

    // 2. Administrador o Presidencia de Estaca sin barrio fijo ven todo lo permitido para líderes
    if (userWard == null || userWard.trim().isEmpty) {
      return true;
    }

    // 3. Actividades abiertas a la Estaca (Conferencias de Barrio, Conferencia de Estaca, JAS)
    if (a.visibility == 'stake' || a.ward.toLowerCase() == 'estaca') {
      return true;
    }

    // 4. Actividad local estándar: visible solo para los miembros del barrio organizador
    return a.ward.isEmpty || a.ward == userWard;
  }
}