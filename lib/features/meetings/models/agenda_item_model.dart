class AgendaItemModel {
  final String id;
  final String topic;       // Asunto o tema a tratar
  final String assignedTo;  // Responsable de presentar (Ej: Pte. Sociedad Socorro o Sumo Consejero)
  final bool isCompleted;   // Si se marcó como tratado durante la reunión
  final String ward;        // 🚀 NUEVO: DNI Geográfico ('Estaca Completa' o el nombre del Barrio)

  AgendaItemModel({
    required this.id,
    required this.topic,
    required this.assignedTo,
    this.isCompleted = false,
    this.ward = 'Estaca Completa', // Valor por defecto para evitar crasheos con datos viejos
  });

  // Convertir a mapa para guardar en Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'topic': topic,
      'assignedTo': assignedTo,
      'isCompleted': isCompleted,
      'ward': ward, // 🚀 Guardamos a qué nivel/barrio pertenece
    };
  }

  // Crear desde un mapa de Firestore
  factory AgendaItemModel.fromMap(Map<String, dynamic> map) {
    return AgendaItemModel(
      id: map['id'] as String? ?? '',
      topic: map['topic'] as String? ?? '',
      assignedTo: map['assignedTo'] as String? ?? '',
      isCompleted: map['isCompleted'] as bool? ?? false,
      ward: map['ward'] as String? ?? 'Desconocido', // 🚀 Recuperamos la jurisdicción
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