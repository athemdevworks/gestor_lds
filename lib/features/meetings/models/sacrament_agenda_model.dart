import 'ward_business_model.dart';

// En sacrament_agenda_model.dart
class SacramentAgendaModel {
  // --- Campos Fijos ---
  final String? welcome; // Bienvenida y Reconocimientos
  final String openingHymn;
  final String openingPrayer;
  final String sacramentHymn;
  final String announcements;
  final String chorister;
  final String pianist;
  final List<WardBusinessModel> wardBusiness;

  // --- Campos Condicionales (Se omiten el 1er domingo) ---
  final String? firstSpeakerTopic;
  final String? firstSpeakerName;
  final String? secondSpeakerTopic;
  final String? secondSpeakerName;
  final String? intermediateHymn; // Himno Especial

  // --- NUEVOS CAMPOS: Tercer Discursante ---
  final bool hasThirdSpeaker; // TRUE si se activó la opción del tercer discursante
  final String? thirdSpeakerTopic;
  final String? thirdSpeakerName;

  // --- Campo de Cierre ---
  final String closingHymn;
  final String closingPrayer;

  // --- Campo de Regla Especial ---
  final bool isFastAndTestimony; // TRUE si es Domingo de Ayuno y Testimonio

  SacramentAgendaModel({
    this.welcome,
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

    // Inicializamos el booleano en false por defecto
    this.hasThirdSpeaker = false,
    this.thirdSpeakerTopic,
    this.thirdSpeakerName,

    required this.closingHymn,
    required this.closingPrayer,
    this.isFastAndTestimony = false,
    this.wardBusiness = const [],
  });

  // Método para convertir a mapa (Firestore)
  Map<String, dynamic> toMap() {
    return {
      'welcome': welcome,
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

      // Guardamos los nuevos campos
      'hasThirdSpeaker': hasThirdSpeaker,
      'thirdSpeakerTopic': thirdSpeakerTopic,
      'thirdSpeakerName': thirdSpeakerName,

      'closingHymn': closingHymn,
      'closingPrayer': closingPrayer,
      'isFastAndTestimony': isFastAndTestimony,
      'wardBusiness': wardBusiness.map((x) => x.toMap()).toList(),
    };
  }

  // Método para crear desde mapa (Firestore)
  factory SacramentAgendaModel.fromMap(Map<String, dynamic> map) {
    return SacramentAgendaModel(
      welcome: map['welcome'],
      openingHymn: map['openingHymn'] as String,
      openingPrayer: map['openingPrayer'] as String,
      sacramentHymn: map['sacramentHymn'] as String,
      announcements: map['announcements'] as String,
      chorister: map['chorister'] as String,
      pianist: map['pianist'] as String,

      // Mapeo de campos opcionales
      firstSpeakerTopic: map['firstSpeakerTopic'] as String?,
      firstSpeakerName: map['firstSpeakerName'] as String?,
      secondSpeakerTopic: map['secondSpeakerTopic'] as String?,
      secondSpeakerName: map['secondSpeakerName'] as String?,
      intermediateHymn: map['intermediateHymn'] as String?,

      // Recuperamos los nuevos campos (con fallback seguro por si son reuniones antiguas)
      hasThirdSpeaker: map['hasThirdSpeaker'] as bool? ?? false,
      thirdSpeakerTopic: map['thirdSpeakerTopic'] as String?,
      thirdSpeakerName: map['thirdSpeakerName'] as String?,

      closingHymn: map['closingHymn'] as String,
      closingPrayer: map['closingPrayer'] as String,

      isFastAndTestimony: map['isFastAndTestimony'] as bool? ?? false,

      // Asuntos de Barrio
      wardBusiness: map['wardBusiness'] != null
          ? List<WardBusinessModel>.from(
          (map['wardBusiness'] as List).map((x) => WardBusinessModel.fromMap(x)))
          : [],
    );
  }
}