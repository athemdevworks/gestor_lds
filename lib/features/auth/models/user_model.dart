import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole {
  admin,
  presidencia_estaca,
  obispado,
  lider_estaca,
  lider_barrio,
  miembro,
}

class UserModel {
  // --- IDENTIFICADORES Y CREDENCIALES ---
  final String uid;
  final String? email;
  final String? username;
  final String? phone;

  // --- DATOS PERSONALES ---
  final String firstName;
  final String lastName;
  final String gender;
  final bool isYSA;
  final DateTime? birthDate;

  // --- DATOS ECLESIÁSTICOS ---
  final String ward;
  final String organization; // Su clase dominical (Ej. Cuórum de Élderes)

  // 🚀 LLAMAMIENTOS MÚLTIPLES (¡Ahora son Listas!)
  final List<String> callingOrganizations; // Donde sirve (Ej. ["Música", "Escuela Dominical"])
  final List<String> callings;             // Sus cargos (Ej. ["Coordinador", "Maestro"])

  // --- CONTROL DE ACCESO ---
  final UserRole role;
  final bool isApproved;
  final bool isActive;
  final bool isRegistered;

  UserModel({
    required this.uid,
    this.email,
    this.username,
    this.phone,
    required this.firstName,
    required this.lastName,
    required this.gender,
    required this.isYSA,
    this.birthDate,
    required this.ward,
    required this.organization,
    required this.callingOrganizations, // 🚀 Lista
    required this.callings,             // 🚀 Lista
    required this.role,
    this.isApproved = false,
    this.isActive = true,
    this.isRegistered = true,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    String rawRole = map['role'] ?? 'miembro';
    if (rawRole == 'lider') rawRole = 'lider_barrio';

    DateTime? parsedDate;
    if (map['birthDate'] is Timestamp) {
      parsedDate = (map['birthDate'] as Timestamp).toDate();
    } else if (map['birthDate'] is String) {
      parsedDate = DateTime.tryParse(map['birthDate']);
    }

    // 🚀 TÁCTICA DE MIGRACIÓN SILENCIOSA
    // Si viene como String (del JSON antiguo o código viejo), lo convertimos a Lista automáticamente.
    List<String> parseToList(dynamic value, String defaultValue) {
      if (value is List) return List<String>.from(value);
      if (value is String) return [value];
      return [defaultValue];
    }

    return UserModel(
      uid: id,
      email: map['email'],
      username: map['username'],
      phone: map['phone'],
      firstName: map['firstName'] ?? '',
      lastName: map['lastName'] ?? '',
      gender: map['gender'] ?? 'M',
      isYSA: map['isYSA'] ?? false,
      birthDate: parsedDate,

      ward: map['ward'] ?? 'Sin Barrio',
      organization: map['organization'] ?? 'Sin Organización',

      // 🚀 Extraemos y convertimos a Listas
      callingOrganizations: parseToList(map['callingOrganization'] ?? map['callingOrganizations'], 'Ninguna'),
      callings: parseToList(map['calling'] ?? map['callings'], 'Sin Llamamiento'),

      role: UserRole.values.firstWhere(
            (e) => e.name == rawRole,
        orElse: () => UserRole.miembro,
      ),

      isApproved: map['isApproved'] ?? false,
      isActive: map['isActive'] ?? true,
      isRegistered: map['isRegistered'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'username': username,
      'phone': phone,
      'firstName': firstName,
      'lastName': lastName,
      'gender': gender,
      'isYSA': isYSA,
      'birthDate': birthDate != null ? Timestamp.fromDate(birthDate!) : null,
      'ward': ward,
      'organization': organization,

      // 🚀 Guardamos como Listas
      'callingOrganizations': callingOrganizations,
      'callings': callings,

      'role': role.name,
      'isApproved': isApproved,
      'isActive': isActive,
      'isRegistered': isRegistered,
    };
  }

  // ==========================================================
  // 🌟 GETTERS DE PODER PARA GESTIÓN DE ESTACA
  // ==========================================================
  bool get canAccess => isApproved && isActive && isRegistered;
  bool get isAdmin => role == UserRole.admin;
  bool get isGlobalAdmin => role == UserRole.admin || role == UserRole.presidencia_estaca;
  bool get isLocalAdmin => role == UserRole.obispado;
  bool get canSeeAllWards => role == UserRole.admin || role == UserRole.presidencia_estaca || role == UserRole.lider_estaca;
  bool get isAnyLeader => role != UserRole.miembro;

  // 🚀 NUEVO GETTER: Para mostrar su llamamiento principal en la interfaz (El primero de la lista)
  String get primaryCalling => callings.isNotEmpty ? callings.first : 'Sin Llamamiento';
}