import 'package:cloud_firestore/cloud_firestore.dart';

class CommitmentModel {
  final String id;
  final String description;
  final DateTime dueDate;
  final String assignedTo;       // UID del responsable
  final String? responsibleName; // Nombre legible (ej: "Juan Pérez")
  final String? meetingId;       // ID de la reunión donde se creó
  final String? agendaItemId;    // ID del punto de agenda
  final String? agendaItemTopic; // Título del punto de agenda (ej: "Planeamiento Barrio")
  final bool isCompleted;

  CommitmentModel({
    required this.id,
    required this.description,
    required this.dueDate,
    required this.assignedTo,
    this.responsibleName,
    this.meetingId,
    this.agendaItemId,
    this.agendaItemTopic, // <--- CAMPO AGREGADO
    this.isCompleted = false,
  });

  // 1. MAPEO DE LECTURA (Firestore -> App)
  factory CommitmentModel.fromMap(Map<String, dynamic> map, String id) {
    return CommitmentModel(
      id: id,
      description: map['description'] ?? '',

      // Manejo seguro de fechas
      dueDate: map['dueDate'] is Timestamp
          ? (map['dueDate'] as Timestamp).toDate()
          : DateTime.now(),

      // Mapeo de campos opcionales con nombres consistentes
      assignedTo: map['assignedTo'] ?? map['assignedToUid'] ?? '', // Soporta ambos nombres por si acaso
      responsibleName: map['responsibleName'] ?? map['assignedToName'],
      meetingId: map['meetingId'],
      agendaItemId: map['agendaItemId'],
      agendaItemTopic: map['agendaItemTopic'], // <--- LECTURA AGREGADA

      isCompleted: map['isCompleted'] ?? false,
    );
  }

  // 2. MAPEO DE ESCRITURA (App -> Firestore)
  Map<String, dynamic> toMap() {
    return {
      'description': description,
      'dueDate': Timestamp.fromDate(dueDate),
      'assignedTo': assignedTo,
      'responsibleName': responsibleName,
      'meetingId': meetingId,
      'agendaItemId': agendaItemId,
      'agendaItemTopic': agendaItemTopic, // <--- ESCRITURA AGREGADA
      'isCompleted': isCompleted,
    };
  }
}