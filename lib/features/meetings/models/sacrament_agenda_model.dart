import 'ward_business_model.dart';

class SacramentAgendaModel {
  // --- Campos Fijos ---
  final String? welcome;
  final String openingHymn;
  final String openingPrayer;
  final String sacramentHymn;
  final String announcements;
  final String chorister;
  final String pianist;
  final List<WardBusinessModel> wardBusiness;

  // --- Campos Condicionales ---
  final String? firstSpeakerTopic;
  final String? firstSpeakerName;
  final String? secondSpeakerTopic;
  final String? secondSpeakerName;
  final String? intermediateHymn;

  // --- Tercer Discursante ---
  final bool hasThirdSpeaker;
  final String? thirdSpeakerTopic;
  final String? thirdSpeakerName;

  // --- Campo de Cierre ---
  final String closingHymn;
  final String closingPrayer;

  // --- Regla Especial ---
  final bool isFastAndTestimony;

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
    this.hasThirdSpeaker = false,
    this.thirdSpeakerTopic,
    this.thirdSpeakerName,
    required this.closingHymn,
    required this.closingPrayer,
    this.isFastAndTestimony = false,
    this.wardBusiness = const [],
  });

  // 🚀 EL CLONADOR TÁCTICO: Indispensable para los formularios en Flutter
  SacramentAgendaModel copyWith({
    String? welcome,
    String? openingHymn,
    String? openingPrayer,
    String? sacramentHymn,
    String? announcements,
    String? chorister,
    String? pianist,
    List<WardBusinessModel>? wardBusiness,
    String? firstSpeakerTopic,
    String? firstSpeakerName,
    String? secondSpeakerTopic,
    String? secondSpeakerName,
    String? intermediateHymn,
    bool? hasThirdSpeaker,
    String? thirdSpeakerTopic,
    String? thirdSpeakerName,
    String? closingHymn,
    String? closingPrayer,
    bool? isFastAndTestimony,
  }) {
    return SacramentAgendaModel(
      welcome: welcome ?? this.welcome,
      openingHymn: openingHymn ?? this.openingHymn,
      openingPrayer: openingPrayer ?? this.openingPrayer,
      sacramentHymn: sacramentHymn ?? this.sacramentHymn,
      announcements: announcements ?? this.announcements,
      chorister: chorister ?? this.chorister,
      pianist: pianist ?? this.pianist,
      wardBusiness: wardBusiness ?? this.wardBusiness,
      firstSpeakerTopic: firstSpeakerTopic ?? this.firstSpeakerTopic,
      firstSpeakerName: firstSpeakerName ?? this.firstSpeakerName,
      secondSpeakerTopic: secondSpeakerTopic ?? this.secondSpeakerTopic,
      secondSpeakerName: secondSpeakerName ?? this.secondSpeakerName,
      intermediateHymn: intermediateHymn ?? this.intermediateHymn,
      hasThirdSpeaker: hasThirdSpeaker ?? this.hasThirdSpeaker,
      thirdSpeakerTopic: thirdSpeakerTopic ?? this.thirdSpeakerTopic,
      thirdSpeakerName: thirdSpeakerName ?? this.thirdSpeakerName,
      closingHymn: closingHymn ?? this.closingHymn,
      closingPrayer: closingPrayer ?? this.closingPrayer,
      isFastAndTestimony: isFastAndTestimony ?? this.isFastAndTestimony,
    );
  }

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
      'hasThirdSpeaker': hasThirdSpeaker,
      'thirdSpeakerTopic': thirdSpeakerTopic,
      'thirdSpeakerName': thirdSpeakerName,
      'closingHymn': closingHymn,
      'closingPrayer': closingPrayer,
      'isFastAndTestimony': isFastAndTestimony,
      'wardBusiness': wardBusiness.map((x) => x.toMap()).toList(),
    };
  }

  factory SacramentAgendaModel.fromMap(Map<String, dynamic> map) {
    return SacramentAgendaModel(
      welcome: map['welcome'] as String?,
      // 🚀 Blindaje anti-crasheos: as String? ?? ''
      openingHymn: map['openingHymn'] as String? ?? '',
      openingPrayer: map['openingPrayer'] as String? ?? '',
      sacramentHymn: map['sacramentHymn'] as String? ?? '',
      announcements: map['announcements'] as String? ?? '',
      chorister: map['chorister'] as String? ?? '',
      pianist: map['pianist'] as String? ?? '',

      firstSpeakerTopic: map['firstSpeakerTopic'] as String?,
      firstSpeakerName: map['firstSpeakerName'] as String?,
      secondSpeakerTopic: map['secondSpeakerTopic'] as String?,
      secondSpeakerName: map['secondSpeakerName'] as String?,
      intermediateHymn: map['intermediateHymn'] as String?,

      hasThirdSpeaker: map['hasThirdSpeaker'] as bool? ?? false,
      thirdSpeakerTopic: map['thirdSpeakerTopic'] as String?,
      thirdSpeakerName: map['thirdSpeakerName'] as String?,

      closingHymn: map['closingHymn'] as String? ?? '',
      closingPrayer: map['closingPrayer'] as String? ?? '',

      isFastAndTestimony: map['isFastAndTestimony'] as bool? ?? false,

      wardBusiness: map['wardBusiness'] != null
          ? List<WardBusinessModel>.from(
          (map['wardBusiness'] as List).map((x) => WardBusinessModel.fromMap(x as Map<String, dynamic>)))
          : [],
    );
  }
}