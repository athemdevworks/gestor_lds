import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gestor_lds/features/meetings/models/meeting_model.dart';
import 'package:gestor_lds/features/meetings/utils/meeting_types.dart';

class MeetingService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const String _collectionName = 'meetings'; // El nombre de la colección

  // 1. CREAR / GUARDAR una nueva reunión
  Future<void> saveMeeting({
    required MeetingType type,
    required DateTime date,
    required String time,
    required String presidedBy,
    required String directedBy,
    String? agendaTopics,
    List<String>? commitments,
  }) async {
    // 1. Creamos una referencia al documento para obtener el ID antes de guardar
    final docRef = _db.collection(_collectionName).doc();

    // 2. Creamos el objeto MeetingModel
    final newMeeting = MeetingModel(
      id: docRef.id, // Asignamos el ID del documento al modelo
      type: type,
      date: date,
      time: time,
      presidedBy: presidedBy,
      directedBy: directedBy,
      agendaTopics: agendaTopics,
      commitments: commitments,
    );

    // 3. Guardamos el mapa en Firestore
    await docRef.set(newMeeting.toMap());
  }

  // 2. OBTENER todas las reuniones (en stream para reactividad)
  Stream<List<MeetingModel>> getMeetings() {
    return _db
        .collection(_collectionName)
    // Ordenamos por fecha, las más recientes primero
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        // Mapeamos cada documento al MeetingModel
        return MeetingModel.fromMap(doc.data());
      }).toList();
    });
  }

// TODO: Añadir funciones para actualizar y eliminar
}