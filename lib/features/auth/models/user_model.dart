import 'package:cloud_firestore/cloud_firestore.dart'; // NECESARIO PARA TIMESTAMP

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
  final String calling;
  final String organization;
  final UserRole role;
  final bool isApproved;
  final String? phoneNumber;
  final DateTime? birthDate; // <--- NUEVO CAMPO

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
    this.birthDate, // <--- Agregar al constructor
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      uid: id,
      email: map['email'] ?? '',
      username: map['username'] ?? '',
      nombres: map['nombres'] ?? '',
      apellidos: map['apellidos'] ?? '',
      calling: map['calling'] ?? '',
      organization: map['organization'] ?? '',
      role: UserRole.values.firstWhere(
            (e) => e.toString().split('.').last == (map['role'] ?? 'miembro'),
        orElse: () => UserRole.miembro,
      ),
      isApproved: map['isApproved'] ?? false,
      phoneNumber: map['phoneNumber'],
      // CONVERSIÓN DE TIMESTAMP A DATETIME
      birthDate: map['birthDate'] != null
          ? (map['birthDate'] as Timestamp).toDate()
          : null,
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
      'role': role.toString().split('.').last,
      'isApproved': isApproved,
      'phoneNumber': phoneNumber,
      // CONVERSIÓN DE DATETIME A TIMESTAMP PARA FIREBASE
      'birthDate': birthDate != null ? Timestamp.fromDate(birthDate!) : null,
    };
  }
}