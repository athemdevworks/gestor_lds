enum MeetingType {
  sacramental, // Para la reunión sacramental, con formato fijo
  bishopric, // Para el Obispado, se enfocará en compromisos y seguimiento
  wardCouncil, // Para el Consejo de Barrio, se enfocará en la agenda dinámica
  other, // Para otras reuniones (conferencia, etc.)
}

extension MeetingTypeExtension on MeetingType {
  String get displayName {
    switch (this) {
      case MeetingType.sacramental:
        return 'Reunión Sacramental';
      case MeetingType.bishopric:
        return 'Reunión de Obispado';
      case MeetingType.wardCouncil:
        return 'Consejo de Barrio';
      case MeetingType.other:
        return 'Otra Reunión';
    }
  }
}