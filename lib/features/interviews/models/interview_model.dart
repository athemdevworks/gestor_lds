import 'package:cloud_firestore/cloud_firestore.dart';

class InterviewModel {
  final String id;
  final DateTime startTime;     // Inicio de la entrevista
  final DateTime endTime;       // Fin (10, 15, 20 o 30 min después)
  final bool isReserved;        // ¿Está ocupado?
  final String? memberId;       // UID del miembro (si reservó)
  final String? memberName;     // Nombre del miembro (para visualización rápida)
  final String? note;           // Motivo: "Renovación", "Recomendación", etc.
  final String createdBy;       // UID del líder que abrió el horario
  final String interviewerRole; // "Obispo", "1er Consejero", "2do Consejero"
  final String ward;            // Unidad / Barrio al que pertenece el horario

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
    required this.ward,
  });

  // 1. LECTURA (Firestore -> Dart)
  factory InterviewModel.fromMap(Map<String, dynamic> map, String docId) {
    return InterviewModel(
      id: docId,
      startTime: map['startTime'] is Timestamp
          ? (map['startTime'] as Timestamp).toDate()
          : DateTime.now(),
      endTime: map['endTime'] is Timestamp
          ? (map['endTime'] as Timestamp).toDate()
          : DateTime.now().add(const Duration(minutes: 15)),
      isReserved: map['isReserved'] ?? false,
      memberId: map['memberId'],
      memberName: map['memberName'],
      note: map['note'],
      createdBy: map['createdBy'] ?? '',
      interviewerRole: map['interviewerRole'] ?? 'Obispo',
      ward: map['ward'] ?? '', // Fallback seguro para registros previos
    );
  }

  // 2. ESCRITURA (Dart -> Firestore)
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
      'ward': ward,
    };
  }
}