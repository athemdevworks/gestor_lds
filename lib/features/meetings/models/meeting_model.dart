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

  factory MeetingModel.fromMap(Map<String, dynamic> data, String id) {
    try {
      // 1. Enum
      MeetingType typeEnum = MeetingType.values.firstWhere(
            (e) => e.toString() == 'MeetingType.${data['type']}',
        orElse: () => MeetingType.other,
      );

      // 2. Agenda Items
      final List<AgendaItemModel>? mappedAgendaItems = data['agendaItems'] != null
          ? (data['agendaItems'] as List)
          .map((item) => AgendaItemModel.fromMap(item as Map<String, dynamic>))
          .toList()
          : null;

      final sacramentAgendaMap = data['sacramentAgenda'] as Map<String, dynamic>?;

      // 3. --- ZONA DE REPARACIÓN DE FECHA/HORA ---
      DateTime parsedDate = (data['date'] as Timestamp).toDate();
      String parsedTime;

      // A) ¿Tiene el formato nuevo?
      if (data['time'] != null && data['time'] is String) {
        parsedTime = data['time'];
      } else {
        // B) Es formato viejo -> APLICAMOS PARCHE
        print("🔧 Reparando reunión antigua ID: $id (Fecha: $parsedDate)"); // <--- CHISMOSO

        if (parsedDate.hour != 0) {
          parsedTime = DateFormat('h:mm a', 'es_ES').format(parsedDate);
        } else {
          parsedTime = "10:00 AM";
        }
        print("   -> Hora asignada: $parsedTime"); // <--- CHISMOSO
      }

      return MeetingModel(
        id: id,
        type: typeEnum,
        date: parsedDate,
        time: parsedTime, // Variable segura
        presidedBy: data['presidedBy'] as String? ?? '',
        directedBy: data['directedBy'] as String? ?? '',
        organization: data['organization'] as String?,
        agendaItems: mappedAgendaItems,
        commitments: data['commitments'] != null ? List<String>.from(data['commitments']) : null,
        sacramentAgenda: sacramentAgendaMap != null ? SacramentAgendaModel.fromMap(sacramentAgendaMap) : null,
      );
    } catch (e) {
      // Si una reunión específica está muy corrupta, esto evita que la app explote
      print("❌ ERROR FATAL en reunión $id: $e");
      // Retornamos una reunión 'vacía' de emergencia para que la lista cargue igual
      return MeetingModel(
        id: id,
        type: MeetingType.other,
        date: DateTime.now(),
        time: "Error",
        presidedBy: "Error de datos",
        directedBy: "",
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