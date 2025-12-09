import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gestor_lds/features/activities/models/activity_model.dart';

class ActivityService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String _collection = 'activities';

  // 1. CREAR
  Future<void> saveActivity(ActivityModel activity) async {
    await _db.collection(_collection).add(activity.toMap());
  }

  // 2. LEER (Stream ordenado por fecha)
  Stream<List<ActivityModel>> getActivities() {
    return _db
        .collection(_collection)
        .orderBy('date', descending: false) // Las más próximas primero
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => ActivityModel.fromMap(doc.data(), doc.id))
        .toList());
  }

  // 3. ACTUALIZAR
  Future<void> updateActivity(ActivityModel activity) async {
    await _db.collection(_collection).doc(activity.id).update(activity.toMap());
  }

  // 4. ELIMINAR
  Future<void> deleteActivity(String id) async {
    await _db.collection(_collection).doc(id).delete();
  }
}