import 'package:cloud_firestore/cloud_firestore.dart';

class MemberModel {
  final String id;
  final String firstName;
  final String lastName;
  // fullName ya no es variable final, es un getter calculado abajo
  final String gender; // 'M' o 'F'
  final DateTime? birthDate;
  final String? phone;
  final String? email;

  // --- IDENTIDAD (SER) ---
  final String primaryOrganization; // Ej: 'Cuórum de Élderes', 'Sociedad de Socorro'
  final bool isYSA;                 // ¿Es JAS? (Independiente de su org)

  // --- SERVICIO (SERVIR) ---
  final String? calling;            // Ej: 'Maestro de Primaria'
  final String? servingOrganization;// Ej: 'Primaria' (Donde ejerce el llamamiento)

  // --- SISTEMA ---
  final String? relatedUserId;      // ID del usuario si tiene acceso

  MemberModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.gender,
    required this.primaryOrganization,
    this.isYSA = false, // Por defecto no es JAS
    this.birthDate,
    this.phone,
    this.email,
    this.calling,
    this.servingOrganization,
    this.relatedUserId,
  });

  // --- GETTERS INTELIGENTES ---

  // 1. Nombre Completo siempre al día
  String get fullName => '$firstName $lastName';

  // 2. Edad Calculada (Vital para pasar de Primaria -> HJ/MJ)
  int? get age {
    if (birthDate == null) return null;
    final today = DateTime.now();
    int age = today.year - birthDate!.year;
    if (today.month < birthDate!.month ||
        (today.month == birthDate!.month && today.day < birthDate!.day)) {
      age--;
    }
    return age;
  }

  // --- SERIALIZACIÓN ---

  Map<String, dynamic> toMap() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'fullName': fullName, // Se guarda para facilitar búsquedas en Firestore
      'gender': gender,
      'birthDate': birthDate != null ? Timestamp.fromDate(birthDate!) : null,
      'phone': phone,
      'email': email,

      // Nuevos campos de estructura
      'primaryOrganization': primaryOrganization,
      'isYSA': isYSA,
      'calling': calling,
      'servingOrganization': servingOrganization,

      'relatedUserId': relatedUserId,
    };
  }

  factory MemberModel.fromMap(Map<String, dynamic> map, String docId) {
    return MemberModel(
      id: docId,
      firstName: map['firstName'] ?? '',
      lastName: map['lastName'] ?? '',
      // fullName se calcula solo
      gender: map['gender'] ?? 'M',
      birthDate: map['birthDate'] != null ? (map['birthDate'] as Timestamp).toDate() : null,
      phone: map['phone'],
      email: map['email'],

      // Mapeo de nuevos campos
      primaryOrganization: map['primaryOrganization'] ?? map['organization'] ?? 'Sin Asignar', // Fallback para datos viejos
      isYSA: map['isYSA'] ?? false,
      calling: map['calling'],
      servingOrganization: map['servingOrganization'],

      relatedUserId: map['relatedUserId'],
    );
  }
}