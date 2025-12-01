import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gestor_lds/features/meetings/utils/meeting_types.dart';
import 'package:gestor_lds/features/meetings/models/agenda_item_model.dart';
import 'package:gestor_lds/features/meetings/models/sacrament_agenda_model.dart';

class MeetingModel {
  // Datos comunes a todas las reuniones
  final String id;
  final MeetingType type;
  final DateTime date;
  final String time;
  final String presidedBy;
  final String directedBy;

  // Datos para reuniones de Liderazgo (Obispado/Consejo)
  // Eliminamos String? agendaTopics, ya que se reemplaza por agendaItems
  final List<AgendaItemModel>? agendaItems;
  final List<String>? commitments; // Lista de compromisos
  final SacramentAgendaModel? sacramentAgenda; //Solo existe si type == sacramental

  MeetingModel({
    required this.id,
    required this.type,
    required this.date,
    required this.time,
    required this.presidedBy,
    required this.directedBy,
    this.sacramentAgenda,
    this.agendaItems,
    this.commitments,
  });

  // Constructor para crear el objeto desde un mapa de Firestore
  factory MeetingModel.fromMap(Map<String, dynamic> data) {
    // Convierte el String del tipo de reunión de vuelta al Enum
    MeetingType typeEnum = MeetingType.values.firstWhere(
          (e) => e.toString() == 'MeetingType.${data['type']}',
      orElse: () => MeetingType.other,
    );

    // Mapeo de la lista de Agenda Items
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
      sacramentAgenda: sacramentAgendaMap != null ? SacramentAgendaModel.fromMap(sacramentAgendaMap) : null,

      // Asignamos la lista mapeada
      agendaItems: mappedAgendaItems,

      // Aseguramos que commitments sea una lista de Strings
      commitments: data['commitments'] != null ? List<String>.from(data['commitments']) : null,
    );
  }

  // Método para convertir el objeto a un mapa para guardarlo en Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.name,
      'date': Timestamp.fromDate(date),
      'time': time,
      'presidedBy': presidedBy,
      'directedBy': directedBy,

      'sacramentAgenda': sacramentAgenda?.toMap(), // <-- Guardar el sub-mapa
      'agendaItems': agendaItems?.map((item) => item.toMap()).toList(), // Usamos toMap() en la lista
      'commitments': commitments,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}