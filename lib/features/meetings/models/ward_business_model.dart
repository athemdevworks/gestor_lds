class WardBusinessModel {
  String type; // "Sostenimiento", "Relevo", etc.
  String personName; // "Hno. Juan Perez"
  String? calling;   // "Maestro de Escuela Dominical" (Opcional)

  WardBusinessModel({
    required this.type,
    required this.personName,
    this.calling,
  });

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'personName': personName,
      'calling': calling,
    };
  }

  factory WardBusinessModel.fromMap(Map<String, dynamic> map) {
    return WardBusinessModel(
      type: map['type'] ?? 'Otro',
      personName: map['personName'] ?? '',
      calling: map['calling'],
    );
  }
}