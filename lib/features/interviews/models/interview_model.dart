import 'package:cloud_firestore/cloud_firestore.dart';

class InterviewModel {
  final String id;
  final DateTime startTime; // Inicio de la entrevista
  final DateTime endTime;   // Fin (usualmente 10-15 min después)
  final bool isReserved;    // ¿Está ocupado?
  final String? memberId;   // UID del miembro (si reservó)
  final String? memberName; // Nombre del miembro (para mostrar rápido)
  final String? note;       // Motivo: "Renovación", "Consejo", etc.
  final String createdBy;   // UID del miembro del obispado que abrió el horario
  final String interviewerRole; // "Obispo", "1er Consejero", "2do Consejero"

  InterviewModel({
    required this.id,
    required this.startTime,
    required this.endTime,
    this.isReserved = false,
    this.memberId,
    this.memberName,
    this.note,
    required this.createdBy,
    required this.interviewerRole,
  });

  // Convertir de Firebase a Objeto Dart
  factory InterviewModel.fromMap(Map<String, dynamic> map, String docId) {
    return InterviewModel(
      id: docId,
      startTime: (map['startTime'] as Timestamp).toDate(),
      endTime: (map['endTime'] as Timestamp).toDate(),
      isReserved: map['isReserved'] ?? false,
      memberId: map['memberId'],
      memberName: map['memberName'],
      note: map['note'],
      createdBy: map['createdBy'] ?? '',
      // Si el campo no existe (registros viejos), asumimos 'Obispo' por defecto
      interviewerRole: map['interviewerRole'] ?? 'Obispo',
    );
  }

  // Convertir de Objeto Dart a Firebase
  Map<String, dynamic> toMap() {
    return {
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'isReserved': isReserved,
      'memberId': memberId,
      'memberName': memberName,
      'note': note,
      'createdBy': createdBy,
      'interviewerRole': interviewerRole,
    };
  }
}