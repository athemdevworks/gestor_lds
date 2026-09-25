class WardBusinessModel {
  final String id;
  final String type;       // "Sostenimiento", "Relevo", etc.
  final String personName; // "Hno. Juan Perez"
  final String? calling;   // "Maestro de Escuela Dominical" (Opcional)
  final int order;          // 🚀 NUEVO: Orden secuencial de presentación

  WardBusinessModel({
    String? id,
    required this.type,
    required this.personName,
    this.calling,
    this.order = 0,
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString();

  WardBusinessModel copyWith({
    String? id,
    String? type,
    String? personName,
    String? calling,
    int? order,
  }) {
    return WardBusinessModel(
      id: id ?? this.id,
      type: type ?? this.type,
      personName: personName ?? this.personName,
      calling: calling ?? this.calling,
      order: order ?? this.order,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'personName': personName,
      'calling': calling,
      'order': order,
    };
  }

  factory WardBusinessModel.fromMap(Map<String, dynamic> map) {
    return WardBusinessModel(
      id: map['id'] as String?,
      type: map['type'] as String? ?? 'Otro',
      personName: map['personName'] as String? ?? '',
      calling: map['calling'] as String?,
      order: map['order'] as int? ?? 0,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WardBusinessModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}