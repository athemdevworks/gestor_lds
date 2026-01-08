import 'package:cloud_firestore/cloud_firestore.dart';

class MemberModel {
  final String id;
  final String firstName;
  final String lastName;
  final String fullName; // Helper para búsqueda
  final String gender; // 'M' o 'F'
  final DateTime? birthDate;
  final String? phone;
  final String? email;
  final String organization; // 'Élderes', 'Sociedad Socorro', etc.
  final String? calling; // 'Obispo', 'Maestra', etc.
  final String? relatedUserId; // Si este miembro tiene cuenta de sistema

  MemberModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.fullName,
    required this.gender,
    this.birthDate,
    this.phone,
    this.email,
    required this.organization,
    this.calling,
    this.relatedUserId,
  });

  Map<String, dynamic> toMap() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'fullName': '$firstName $lastName', // Se autogenera al guardar
      'gender': gender,
      'birthDate': birthDate != null ? Timestamp.fromDate(birthDate!) : null,
      'phone': phone,
      'email': email,
      'organization': organization,
      'calling': calling,
      'relatedUserId': relatedUserId,
    };
  }

  factory MemberModel.fromMap(Map<String, dynamic> map, String docId) {
    return MemberModel(
      id: docId,
      firstName: map['firstName'] ?? '',
      lastName: map['lastName'] ?? '',
      fullName: map['fullName'] ?? '${map['firstName']} ${map['lastName']}',
      gender: map['gender'] ?? 'M',
      birthDate: map['birthDate'] != null ? (map['birthDate'] as Timestamp).toDate() : null,
      phone: map['phone'],
      email: map['email'],
      organization: map['organization'] ?? 'Sin Asignar',
      calling: map['calling'],
      relatedUserId: map['relatedUserId'],
    );
  }
}