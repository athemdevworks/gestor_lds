import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gestor_lds/features/meetings/utils/meeting_types.dart';
import 'package:gestor_lds/features/meetings/models/agenda_item_model.dart';
import 'package:gestor_lds/features/meetings/models/sacrament_agenda_model.dart';

class MeetingModel {
  final String id;
  final MeetingType type;
  final DateTime date;
  final String time;
  final String presidedBy;
  final String directedBy;

  // --- NUEVO CAMPO AÑADIDO ---
  final String? organization;
  // ---------------------------

  final List<AgendaItemModel>? agendaItems;
  final List<String>? commitments;
  final SacramentAgendaModel? sacramentAgenda;

  MeetingModel({
    required this.id,
    required this.type,
    required this.date,
    required this.time,
    required this.presidedBy,
    required this.directedBy,

    // --- AÑADIR AL CONSTRUCTOR ---
    this.organization,
    // ----------------------------

    this.agendaItems,
    this.commitments,
    this.sacramentAgenda,
  });

  factory MeetingModel.fromMap(Map<String, dynamic> data) {
    MeetingType typeEnum = MeetingType.values.firstWhere(
          (e) => e.toString() == 'MeetingType.${data['type']}',
      orElse: () => MeetingType.other,
    );

    final List<AgendaItemModel>? mappedAgendaItems = data['agendaItems'] != null
        ? (data['agendaItems'] as List)
        .map((item) => AgendaItemModel.fromMap(item as Map<String, dynamic>))
        .toList()
        : null;

    final sacramentAgendaMap = data['sacramentAgenda'] as Map<String, dynamic>?;

    return MeetingModel(
      id: data['id'] as String,
      type: typeEnum,
      date: (data['date'] as Timestamp).toDate(),
      time: data['time'] as String,
      presidedBy: data['presidedBy'] as String,
      directedBy: data['directedBy'] as String,

      // --- AÑADIR AL MAPEO DE LECTURA ---
      organization: data['organization'] as String?,
      // ----------------------------------

      agendaItems: mappedAgendaItems,
      commitments: data['commitments'] != null ? List<String>.from(data['commitments']) : null,
      sacramentAgenda: sacramentAgendaMap != null ? SacramentAgendaModel.fromMap(sacramentAgendaMap) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.name,
      'date': Timestamp.fromDate(date),
      'time': time,
      'presidedBy': presidedBy,
      'directedBy': directedBy,

      // --- AÑADIR AL MAPEO DE GUARDADO ---
      'organization': organization,
      // -----------------------------------

      'agendaItems': agendaItems?.map((item) => item.toMap()).toList(),
      'commitments': commitments,
      'sacramentAgenda': sacramentAgenda?.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}