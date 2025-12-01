// En sacrament_agenda_model.dart
class SacramentAgendaModel {
  // --- Campos Fijos ---
  final String openingHymn;
  final String openingPrayer;
  final String sacramentHymn;
  final String announcements;
  final String chorister;
  final String pianist;

  // --- Campos Condicionales (Se omiten el 1er domingo) ---
  final String? firstSpeakerTopic;
  final String? firstSpeakerName;
  final String? secondSpeakerTopic;
  final String? secondSpeakerName;
  final String? intermediateHymn; // Himno Especial

  // --- Campo de Cierre ---
  final String closingHymn;
  final String closingPrayer;

  // --- Campo de Regla Especial ---
  final bool isFastAndTestimony; // TRUE si es Domingo de Ayuno y Testimonio

  SacramentAgendaModel({
    required this.openingHymn,
    required this.openingPrayer,
    required this.sacramentHymn,
    required this.announcements,
    required this.chorister,
    required this.pianist,
    this.firstSpeakerTopic,
    this.firstSpeakerName,
    this.secondSpeakerTopic,
    this.secondSpeakerName,
    this.intermediateHymn,
    required this.closingHymn,
    required this.closingPrayer,
    this.isFastAndTestimony = false,
  });

  // Método para convertir a mapa (Firestore)
  Map<String, dynamic> toMap() {
    return {
      'openingHymn': openingHymn,
      'openingPrayer': openingPrayer,
      'sacramentHymn': sacramentHymn,
      'announcements': announcements,
      'chorister': chorister,
      'pianist': pianist,
      'firstSpeakerTopic': firstSpeakerTopic,
      'firstSpeakerName': firstSpeakerName,
      'secondSpeakerTopic': secondSpeakerTopic,
      'secondSpeakerName': secondSpeakerName,
      'intermediateHymn': intermediateHymn,
      'closingHymn': closingHymn,
      'closingPrayer': closingPrayer,
      'isFastAndTestimony': isFastAndTestimony,
    };
  }

  // Método para crear desde mapa (Firestore)
  factory SacramentAgendaModel.fromMap(Map<String, dynamic> map) {
    // ... (Implementación para leer datos de Firestore) ...
    // Lo simplificaremos para ahorrar espacio, asumiendo que el mapeo es directo.
    return SacramentAgendaModel(
      openingHymn: map['openingHymn'] as String,
      openingPrayer: map['openingPrayer'] as String, // <-- ERROR CORREGIDO
      sacramentHymn: map['sacramentHymn'] as String, // <-- ERROR CORREGIDO
      announcements: map['announcements'] as String, // <-- ERROR CORREGIDO
      chorister: map['chorister'] as String, // <-- ERROR CORREGIDO
      pianist: map['pianist'] as String, // <-- ERROR CORREGIDO

      // Mapeo de campos opcionales (si no existen en Firestore, serán null)
      firstSpeakerTopic: map['firstSpeakerTopic'] as String?,
      firstSpeakerName: map['firstSpeakerName'] as String?,
      secondSpeakerTopic: map['secondSpeakerTopic'] as String?,
      secondSpeakerName: map['secondSpeakerName'] as String?,
      intermediateHymn: map['intermediateHymn'] as String?,

      closingHymn: map['closingHymn'] as String, // <-- ERROR CORREGIDO
      closingPrayer: map['closingPrayer'] as String, // <-- ERROR CORREGIDO

      // El estado de la regla del primer domingo
      isFastAndTestimony: map['isFastAndTestimony'] as bool? ?? false,
    );
  }
}