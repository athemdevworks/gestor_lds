import 'package:cloud_firestore/cloud_firestore.dart';

class CommitmentModel {
  final String id;
  final String meetingId;
  final String description;
  final String assignedToUid;
  final String assignedToName;
  final DateTime dueDate;
  final bool isCompleted;
  final DateTime createdAt;

  // NUEVOS CAMPOS (Opcionales)
  final String? agendaItemId;    // ID del punto de agenda
  final String? agendaItemTopic; // Nombre del punto de agenda

  CommitmentModel({
    required this.id,
    required this.meetingId,
    required this.description,
    required this.assignedToUid,
    required this.assignedToName,
    required this.dueDate,
    this.isCompleted = false,
    required this.createdAt,

    // Añadimos al constructor
    this.agendaItemId,
    this.agendaItemTopic,
  });

  // Convertir de Firestore (Mapeo)
  factory CommitmentModel.fromMap(Map<String, dynamic> data) {
    return CommitmentModel(
      id: data['id'] as String,
      meetingId: data['meetingId'] as String,
      description: data['description'] as String,
      assignedToUid: data['assignedToUid'] as String,
      assignedToName: data['assignedToName'] as String,
      dueDate: (data['dueDate'] as Timestamp).toDate(),
      isCompleted: data['isCompleted'] as bool,
      createdAt: (data['createdAt'] as Timestamp).toDate(),

      // Mapear los nuevos campos (pueden ser null)
      agendaItemId: data['agendaItemId'] as String?,
      agendaItemTopic: data['agendaItemTopic'] as String?,
    );
  }

  // Convertir a Mapa para Firestore (Guardado)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'meetingId': meetingId,
      'description': description,
      'assignedToUid': assignedToUid,
      'assignedToName': assignedToName,
      'dueDate': Timestamp.fromDate(dueDate),
      'isCompleted': isCompleted,
      'createdAt': Timestamp.fromDate(createdAt),

      // Guardar los nuevos campos
      'agendaItemId': agendaItemId,
      'agendaItemTopic': agendaItemTopic,
    };
  }
}