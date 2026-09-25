import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gestor_lds/features/meetings/utils/meeting_types.dart';
import 'package:gestor_lds/features/meetings/models/agenda_item_model.dart';
import 'package:gestor_lds/features/meetings/models/sacrament_agenda_model.dart';
import 'package:intl/intl.dart';

class MeetingModel {
  final String id;
  final MeetingType type;
  final DateTime date;
  final String time;
  final String presidedBy;
  final String directedBy;
  final String ward;
  final String? organization;
  final String? openingHymn;
  final String? openingPrayer;
  final String? closingHymn;
  final String? closingPrayer;
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
    required this.ward,
    this.organization,
    this.openingHymn,
    this.openingPrayer,
    this.closingHymn,
    this.closingPrayer,
    this.agendaItems,
    this.commitments,
    this.sacramentAgenda,
  });

  // 🚀 EL CLONADOR TÁCTICO: Permite actualizar campos en memoria durante la edición
  MeetingModel copyWith({
    String? id,
    MeetingType? type,
    DateTime? date,
    String? time,
    String? presidedBy,
    String? directedBy,
    String? ward,
    String? organization,
    String? openingHymn,
    String? openingPrayer,
    String? closingHymn,
    String? closingPrayer,
    List<AgendaItemModel>? agendaItems,
    List<String>? commitments,
    SacramentAgendaModel? sacramentAgenda,
  }) {
    return MeetingModel(
      id: id ?? this.id,
      type: type ?? this.type,
      date: date ?? this.date,
      time: time ?? this.time,
      presidedBy: presidedBy ?? this.presidedBy,
      directedBy: directedBy ?? this.directedBy,
      ward: ward ?? this.ward,
      organization: organization ?? this.organization,
      openingHymn: openingHymn ?? this.openingHymn,
      openingPrayer: openingPrayer ?? this.openingPrayer,
      closingHymn: closingHymn ?? this.closingHymn,
      closingPrayer: closingPrayer ?? this.closingPrayer,
      agendaItems: agendaItems ?? this.agendaItems,
      commitments: commitments ?? this.commitments,
      sacramentAgenda: sacramentAgenda ?? this.sacramentAgenda,
    );
  }

  factory MeetingModel.fromMap(Map<String, dynamic> data, String id) {
    try {
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

      DateTime parsedDate = (data['date'] as Timestamp).toDate();
      String parsedTime;

      if (data['time'] != null && data['time'] is String) {
        parsedTime = data['time'];
      } else {
        if (parsedDate.hour != 0) {
          parsedTime = DateFormat('h:mm a', 'es_ES').format(parsedDate);
        } else {
          parsedTime = "10:00 AM";
        }
      }

      return MeetingModel(
        id: id,
        type: typeEnum,
        date: parsedDate,
        time: parsedTime,
        presidedBy: data['presidedBy'] as String? ?? '',
        directedBy: data['directedBy'] as String? ?? '',
        ward: data['ward'] as String? ?? 'Desconocido',
        organization: data['organization'] as String?,
        openingHymn: data['openingHymn'] as String?,
        openingPrayer: data['openingPrayer'] as String?,
        closingHymn: data['closingHymn'] as String?,
        closingPrayer: data['closingPrayer'] as String?,
        agendaItems: mappedAgendaItems,
        commitments: data['commitments'] != null ? List<String>.from(data['commitments']) : null,
        sacramentAgenda: sacramentAgendaMap != null ? SacramentAgendaModel.fromMap(sacramentAgendaMap) : null,
      );
    } catch (e) {
      print("❌ ERROR FATAL en reunión $id: $e");
      return MeetingModel(
        id: id,
        type: MeetingType.other,
        date: DateTime.now(),
        time: "Error",
        presidedBy: "Error de datos",
        directedBy: "",
        ward: "Error",
        organization: "",
      );
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.name,
      'date': Timestamp.fromDate(date),
      'time': time,
      'presidedBy': presidedBy,
      'directedBy': directedBy,
      'ward': ward,
      'organization': organization,
      'openingHymn': openingHymn,
      'openingPrayer': openingPrayer,
      'closingHymn': closingHymn,
      'closingPrayer': closingPrayer,
      'agendaItems': agendaItems?.map((item) => item.toMap()).toList(),
      'commitments': commitments,
      'sacramentAgenda': sacramentAgenda?.toMap(),
      'updatedAt': FieldValue.serverTimestamp(), // 🚀 Protegemos la fecha original
    };
  }
}