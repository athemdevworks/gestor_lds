class AgendaItemModel {
  final String id;
  final String topic;     // Asunto o tema a tratar
  final String assignedTo;  // Responsable de presentar (Ej: Pte. Sociedad Socorro)
  final bool isCompleted; // Si se marcó como tratado durante la reunión

  AgendaItemModel({
    required this.id,
    required this.topic,
    required this.assignedTo,
    this.isCompleted = false,
  });

  // Convertir a mapa para guardar en Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'topic': topic,
      'assignedTo': assignedTo,
      'isCompleted': isCompleted,
    };
  }

  // Crear desde un mapa de Firestore
  factory AgendaItemModel.fromMap(Map<String, dynamic> map) {
    return AgendaItemModel(
      id: map['id'] as String,
      topic: map['topic'] as String,
      assignedTo: map['assignedTo'] as String,
      isCompleted: map['isCompleted'] as bool,
    );
  }

  // -----------------------------------------------------------
  // FIX PARA EL DROPDOWN: Comparar por ID
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