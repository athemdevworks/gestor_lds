import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gestor_lds/features/meetings/utils/meeting_types.dart';

class MeetingModel {
  // Datos comunes a todas las reuniones
  final String id;
  final MeetingType type;
  final DateTime date;
  final String time;
  final String presidedBy;
  final String directedBy;

  // Datos para reuniones de Liderazgo (Obispado/Consejo)
  final String? agendaTopics;
  final List<String>? commitments; // Lista de compromisos (ej: "Hna. Pérez visitar a Hno. Gómez")

  MeetingModel({
    required this.id,
    required this.type,
    required this.date,
    required this.time,
    required this.presidedBy,
    required this.directedBy,
    this.agendaTopics,
    this.commitments,
  });

  // Constructor para crear el objeto desde un mapa de Firestore
  factory MeetingModel.fromMap(Map<String, dynamic> data) {
    // Convierte el String del tipo de reunión de vuelta al Enum
    MeetingType typeEnum = MeetingType.values.firstWhere(
          (e) => e.toString() == 'MeetingType.${data['type']}',
      orElse: () => MeetingType.other,
    );

    return MeetingModel(
      id: data['id'] as String,
      type: typeEnum,
      date: (data['date'] as Timestamp).toDate(),
      time: data['time'] as String,
      presidedBy: data['presidedBy'] as String,
      directedBy: data['directedBy'] as String,

      // Datos opcionales (pueden ser nulos en Firestore)
      agendaTopics: data['agendaTopics'] as String?,
      // Aseguramos que commitments sea una lista de Strings
      commitments: data['commitments'] != null ? List<String>.from(data['commitments']) : null,
    );
  }

  // Método para convertir el objeto a un mapa para guardarlo en Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.name, // Guardamos solo el nombre del Enum (Ej: 'bishopric')
      'date': Timestamp.fromDate(date), // Guardamos como Timestamp
      'time': time,
      'presidedBy': presidedBy,
      'directedBy': directedBy,
      'agendaTopics': agendaTopics,
      'commitments': commitments,
      'createdAt': FieldValue.serverTimestamp(), // Para ordenar por creación
    };
  }
}