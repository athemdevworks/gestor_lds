// Enum de Roles (No cambia, controla los permisos de acceso)
enum UserRole {
  pending,      // Por defecto, sin acceso
  bishopric,    // Obispado/Admin
  clerk,        // Secretario
  ward_council, // Líderes de consejo
}

// --- NUEVA EXTENSIÓN PARA TRADUCCIÓN ---
extension UserRoleExtension on UserRole {
  String get displayName {
    switch (this) {
      case UserRole.bishopric:
        return 'Obispado';
      case UserRole.clerk:
        return 'Presidencia de Org.';
      case UserRole.ward_council:
        return 'Consejo de Barrio';
      case UserRole.pending:
        return 'Pendiente';
    }
  }
}

class UserModel {
  final String uid;
  final String email;
  final String username;
  final String nombres;
  final String apellidos;
  final UserRole role;
  final String calling; // ¡Campo actualizado! (Llamamiento)
  final String status; // 'pending' o 'active'

  UserModel({
    required this.uid,
    required this.email,
    required this.username,
    required this.nombres,
    required this.apellidos,
    required this.role,
    required this.calling,
    required this.status,
  });

  // Metodo para convertir el objeto a un mapa de Firestore
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'username': username,
      'nombres': nombres,
      'apellidos': apellidos,
      'role': role.name,
      'calling': calling, // Usamos el nuevo nombre
      'status': status,
    };
  }

  // Metodo para crear el objeto desde un documento de Firestore
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] as String,
      email: map['email'] as String,
      username: map['username'] as String,
      nombres: map['nombres'] as String,
      apellidos: map['apellidos'] as String,
      role: UserRole.values.firstWhere(
            (e) => e.name == map['role'],
        orElse: () => UserRole.pending,
      ),
      calling: map['calling'] as String, // Usamos el nuevo nombre
      status: map['status'] as String,
    );
  }

  // -----------------------------------------------------------
  // FIX CRÍTICO: IMPLEMENTAR IGUALDAD BASADA EN EL UID
  // -----------------------------------------------------------

  // 1. Sobreescribir el operador de igualdad (==)
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true; // Si son el mismo objeto en memoria

    // Si son del mismo tipo y tienen el mismo UID, son iguales.
    return other is UserModel && other.uid == uid;
  }

  // 2. Sobreescribir el código hash
  @override
  int get hashCode => uid.hashCode;
// -----------------------------------------------------------

}