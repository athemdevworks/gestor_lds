class AgendaItemModel {
  final String id;
  final String topic;       // Asunto o tema a tratar
  final String assignedTo;  // Responsable de presentar (Ej: Pte. Sociedad Socorro)
  final bool isCompleted;   // Si se marcó como tratado durante la reunión
  final String ward;        // DNI Geográfico ('Estaca Completa' o el nombre del Barrio)
  final int order;          // 🚀 NUEVO: Mantiene la posición al arrastrar y soltar

  AgendaItemModel({
    String? id,
    required this.topic,
    required this.assignedTo,
    this.isCompleted = false,
    this.ward = 'Estaca Completa',
    this.order = 0,
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString(); // 🚀 Autogenerador de ID seguro

  // 🚀 EL CLONADOR TÁCTICO: Indispensable para actualizar la UI
  AgendaItemModel copyWith({
    String? id,
    String? topic,
    String? assignedTo,
    bool? isCompleted,
    String? ward,
    int? order,
  }) {
    return AgendaItemModel(
      id: id ?? this.id,
      topic: topic ?? this.topic,
      assignedTo: assignedTo ?? this.assignedTo,
      isCompleted: isCompleted ?? this.isCompleted,
      ward: ward ?? this.ward,
      order: order ?? this.order,
    );
  }

  // Convertir a mapa para guardar en Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'topic': topic,
      'assignedTo': assignedTo,
      'isCompleted': isCompleted,
      'ward': ward,
      'order': order, // 🚀 Guardamos el orden
    };
  }

  // Crear desde un mapa de Firestore
  factory AgendaItemModel.fromMap(Map<String, dynamic> map) {
    return AgendaItemModel(
      id: map['id'] as String?,
      topic: map['topic'] as String? ?? '',
      assignedTo: map['assignedTo'] as String? ?? '',
      isCompleted: map['isCompleted'] as bool? ?? false,
      ward: map['ward'] as String? ?? 'Desconocido',
      order: map['order'] as int? ?? 0, // 🚀 Recuperamos el orden
    );
  }

  // -----------------------------------------------------------
  // FIX PARA EL DROPDOWN Y LISTAS: Comparar por ID
  // -----------------------------------------------------------
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AgendaItemModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
// -----------------------------------------------------------
}