import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gestor_lds/features/activities/models/activity_model.dart';

class ActivityService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String _collection = 'activities';

  // 1. CREAR (Generando ID correctamente)
  Future<void> saveActivity(ActivityModel activity) async {
    // Generamos la referencia primero para obtener el ID único
    final docRef = _db.collection(_collection).doc();

    // Creamos una nueva instancia del modelo con el ID real de Firestore
    final newActivity = ActivityModel(
      id: docRef.id,
      title: activity.title,
      description: activity.description,
      date: activity.date,
      time: activity.time,
      location: activity.location,
      organization: activity.organization,
    );

    // Guardamos usando .set()
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

  // --- NUEVAS CONSULTAS PARA LAS PESTAÑAS ---

  // A. PRÓXIMAS ACTIVIDADES (Desde hoy en adelante)
  Stream<List<ActivityModel>> getUpcomingActivities() {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);

    return _db
        .collection(_collection)
        .where('date', isGreaterThanOrEqualTo: todayStart)
        .orderBy('date', descending: false) // Ascendente: La más cercana primero
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => ActivityModel.fromMap(doc.data(), doc.id))
        .toList());
  }

  // B. HISTORIAL (Pasadas, con filtro de fecha límite)
  Stream<List<ActivityModel>> getHistoryActivities(DateTime limitDate) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);

    return _db
        .collection(_collection)
        .where('date', isLessThan: todayStart) // Solo pasadas
        .where('date', isGreaterThanOrEqualTo: limitDate) // Filtro usuario
        .orderBy('date', descending: true) // Descendente: La más reciente primero
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => ActivityModel.fromMap(doc.data(), doc.id))
        .toList());
  }
}