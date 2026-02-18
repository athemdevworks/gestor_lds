import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole {
  admin,    // <--- TÚ (Desarrollador / Superusuario)
  obispado, // Acceso Total Eclesiástico
  lider,    // Acceso a Presupuestos/Agendas de su org
  miembro,  // Solo ver información básica
}

class UserModel {
  final String uid;
  final String email;
  final String username;

  // Datos Visuales
  final String nombres;
  final String apellidos;

  // Datos Eclesiásticos (Snapshot)
  final String calling;
  final String organization;

  // --- CONTROL DE ACCESO ---
  final UserRole role;
  final bool isApproved;
  final bool isActive;

  // --- VINCULACIÓN ---
  final String? memberId;

  // Datos Opcionales
  final String? phoneNumber;
  final DateTime? birthDate;

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
    this.isActive = true,
    this.memberId,
    this.phoneNumber,
    this.birthDate,
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

      // La magia para leer 'admin' ya funciona aquí automáticamente
      role: UserRole.values.firstWhere(
            (e) => e.toString().split('.').last == (map['role'] ?? 'miembro'),
        orElse: () => UserRole.miembro,
      ),

      isApproved: map['isApproved'] ?? false,
      isActive: map['isActive'] ?? true,
      memberId: map['memberId'],

      phoneNumber: map['phoneNumber'],
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
      'role': role.toString().split('.').last, // Esto guardará "admin"
      'isApproved': isApproved,
      'isActive': isActive,
      'memberId': memberId,
      'phoneNumber': phoneNumber,
      'birthDate': birthDate != null ? Timestamp.fromDate(birthDate!) : null,
    };
  }

  // --- 🌟 GETTERS DE PODER (Úsalos en tu UI) ---

  // 1. ¿Puede entrar al sistema?
  bool get canAccess => isApproved && isActive;

  // 2. ¿Es el Jefe Supremo? (Admin u Obispo)
  // Úsalo para: Ver datos sensibles, aprobar usuarios, editar directorio global.
  bool get isAdminOrBishop => role == UserRole.admin || role == UserRole.obispado;

  // 3. ¿Tiene algún liderazgo? (Admin, Obispo o Líder)
  // Úsalo para: Ver presupuestos, crear agendas.
  bool get isLeaderOrBetter =>
      role == UserRole.admin ||
          role == UserRole.obispado ||
          role == UserRole.lider;

  // 4. ¿Es estrictamente Admin?
  // Úsalo para: Borrar base de datos, configuraciones técnicas, ver logs.
  bool get isAdmin => role == UserRole.admin;
}