enum UserRole {
  obispado, // Ve TODO (Admin)
  lider,    // Ve lo suyo + Consejos
  miembro   // Ve solo lo público
}

class UserModel {
  final String uid;
  final String email;
  final String nombres;
  final String apellidos;
  final String calling;      // Ej: "Presidenta de Primaria"
  final String organization; // Ej: "Primaria" (NUEVO CAMPO CLAVE PARA FILTROS)
  final UserRole role;       // El Enum nuevo
  final bool isApproved;
  final String? username;    // Para login híbrido

  UserModel({
    required this.uid,
    required this.email,
    required this.nombres,
    required this.apellidos,
    required this.calling,
    required this.organization,
    required this.role,
    this.isApproved = false,
    this.username,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'nombres': nombres,
      'apellidos': apellidos,
      'calling': calling,
      'organization': organization,
      'role': role.name, // Guarda "obispado", "lider", etc.
      'isApproved': isApproved,
      'username': username,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      nombres: map['nombres'] ?? '',
      apellidos: map['apellidos'] ?? '',
      calling: map['calling'] ?? '',
      organization: map['organization'] ?? 'Barrio',

      // Conversión inteligente del Enum (Maneja fallos)
      role: UserRole.values.firstWhere(
            (e) => e.name == map['role'],
        orElse: () => UserRole.miembro,
      ),

      isApproved: map['isApproved'] ?? false,
      username: map['username'],
    );
  }
}