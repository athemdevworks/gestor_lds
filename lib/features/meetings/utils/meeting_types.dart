enum MeetingType {
  // --- REUNIONES DE BARRIO ---
  sacramental,
  bishopric,
  wardCouncil,
  youthCouncil,

  // --- REUNIONES DE ESTACA ---
  stakeConference,
  stakePriesthoodGeneral,
  stakePriesthoodLeadership,
  stakeLeadershipTraining,
  highPriestsQuorum,
  stakePresidency,
  highCouncil,
  stakeCouncil,
  stakeAdultLeadership,
  stakeYouthLeadership,
  stakeBishopsCouncil,

  // --- REUNIONES COMPARTIDAS (Barrio y Estaca) ---
  presidency,
  other,
}

extension MeetingTypeExtension on MeetingType {
  String get displayName {
    switch (this) {
    // Barrio
      case MeetingType.sacramental: return 'Reunión Sacramental';
      case MeetingType.bishopric: return 'Reunión del Obispado';
      case MeetingType.wardCouncil: return 'Consejo de Barrio';
      case MeetingType.youthCouncil: return 'Consejo de Barrio para la Juventud';

    // Estaca
      case MeetingType.stakeConference: return 'Conferencia de Estaca';
      case MeetingType.stakePriesthoodGeneral: return 'Reunión general del sacerdocio de estaca';
      case MeetingType.stakePriesthoodLeadership: return 'Reunión de líderes del sacerdocio de estaca';
      case MeetingType.stakeLeadershipTraining: return 'Capacitación de líderes de estaca';
      case MeetingType.highPriestsQuorum: return 'Reunión del cuórum de sumos sacerdotes';
      case MeetingType.stakePresidency: return 'Reunión de la Presidencia de Estaca';
      case MeetingType.highCouncil: return 'Reunión del Sumo Consejo';
      case MeetingType.stakeCouncil: return 'Consejo de Estaca';
      case MeetingType.stakeAdultLeadership: return 'Comité de líderes de adultos de estaca';
      case MeetingType.stakeYouthLeadership: return 'Comité de líderes de jóvenes de estaca';
      case MeetingType.stakeBishopsCouncil: return 'Consejo de obispos de estaca';

    // Compartidas
      case MeetingType.presidency: return 'Reunión de Presidencia';
      case MeetingType.other: return 'Otra Reunión';
    }
  }
}

// 🚀 LISTAS INTELIGENTES PARA LOS DROPDOWNS MULTIVERSO
class MeetingTypeLists {
  // Lo que ve un líder cuando está en "Modo Barrio"
  static const List<MeetingType> wardMeetings = [
    MeetingType.sacramental,
    MeetingType.bishopric,
    MeetingType.wardCouncil,
    MeetingType.youthCouncil,
    MeetingType.presidency,
    MeetingType.other,
  ];

  // Lo que ve un líder cuando está en "Modo Estaca"
  static const List<MeetingType> stakeMeetings = [
    MeetingType.stakeConference,
    MeetingType.stakePriesthoodGeneral,
    MeetingType.stakePriesthoodLeadership,
    MeetingType.stakeLeadershipTraining,
    MeetingType.highPriestsQuorum,
    MeetingType.stakePresidency,
    MeetingType.highCouncil,
    MeetingType.stakeCouncil,
    MeetingType.stakeAdultLeadership,
    MeetingType.stakeYouthLeadership,
    MeetingType.stakeBishopsCouncil,
    MeetingType.presidency,
    MeetingType.other,
  ];
}