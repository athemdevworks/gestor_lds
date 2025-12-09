enum MeetingType {
  sacramental,
  bishopric,      // Obispado
  wardCouncil,    // Consejo de Barrio
  presidency,     // Reunión de Presidencia (General)
  youthCouncil,   // Consejo de Barrio para la Juventud
  interview,
  other,
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
      case MeetingType.presidency:
        return 'Reunión de Presidencia'; // <--- Nuevo
      case MeetingType.youthCouncil:
        return 'Consejo de Barrio para la Juventud'; // <--- Nuevo
      case MeetingType.interview:
        return 'Entrevistas';
      case MeetingType.other:
        return 'Otra Reunión';
    }
  }
}