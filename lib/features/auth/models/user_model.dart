enum UserRole {
  obispado, // Admin
  lider,    // Acceso medio
  miembro,  // Acceso básico
}

class UserModel {
  final String uid;
  final String email;
  final String username;
  final String nombres;
  final String apellidos;
  final String calling; // Llamamiento
  final String organization; // Organización
  final UserRole role;
  final bool isApproved; // ¿El obispo lo aprobó?
  final String? phoneNumber; // Nuevo campo opcional

  UserModel({
    required this.uid,
    required this.email,
    required this.username,
    required this.nombres,
    required this.apellidos,
    required this.calling,
    required this.organization,
    required this.role,
    this.isApproved = false,
    this.phoneNumber,
  });

  // --- CORRECCIÓN AQUÍ: Agregamos "String id" ---
  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      uid: id, // Usamos el ID del documento como UID principal
      email: map['email'] ?? '',
      username: map['username'] ?? '',
      nombres: map['nombres'] ?? '',
      apellidos: map['apellidos'] ?? '',
      calling: map['calling'] ?? '',
      organization: map['organization'] ?? '',
      // Convertir String a Enum (con fallback a 'miembro')
      role: UserRole.values.firstWhere(
            (e) => e.toString().split('.').last == (map['role'] ?? 'miembro'),
        orElse: () => UserRole.miembro,
      ),
      isApproved: map['isApproved'] ?? false,
      phoneNumber: map['phoneNumber'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'username': username,
      'nombres': nombres,
      'apellidos': apellidos,
      'calling': calling,
      'organization': organization,
      'role': role.toString().split('.').last, // Guardamos solo "obispado", "lider", etc.
      'isApproved': isApproved,
      'phoneNumber': phoneNumber,
    };
  }
}