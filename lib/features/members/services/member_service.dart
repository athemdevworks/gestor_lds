import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/member_model.dart';
import 'dart:convert';
import 'package:flutter/services.dart';

class MemberService {
  final CollectionReference _membersRef = FirebaseFirestore.instance.collection('members');
  final CollectionReference _usersRef = FirebaseFirestore.instance.collection('users');

  // ==========================================================
  // 🚀 MOTOR MATEMÁTICO DE ORGANIZACIONES (PUNTO 2)
  // ==========================================================
  String _calcularOrganizacionPrincipal(DateTime? birthDate, String gender, String fallbackOrg) {
    // Si por algún motivo no hay fecha de nacimiento, usamos la que viene de LCR por defecto
    if (birthDate == null) return fallbackOrg;

    int currentYear = DateTime.now().year;
    int ageThisYear = currentYear - birthDate.year; // "La edad que cumple en ese año"

    if (ageThisYear <= 11) {
      return 'Primaria';
    } else if (ageThisYear >= 12 && ageThisYear <= 17) {
      return gender == 'M' ? 'Hombres Jóvenes' : 'Mujeres Jóvenes';
    } else {
      // De 18 a 1000 años 🦇
      return gender == 'M' ? 'Cuórum de Élderes' : 'Sociedad de Socorro';
    }
  }

  // --- MÉTODOS CRUD PRINCIPALES ---

  Future<void> saveMember(MemberModel member) async {
    final docRef = member.id.isEmpty ? _membersRef.doc() : _membersRef.doc(member.id);
    await docRef.set(member.toMap(), SetOptions(merge: true));

    if (member.relatedUserId != null && member.relatedUserId!.isNotEmpty) {
      try {
        String displayOrg = member.servingOrganization ?? member.primaryOrganization;

        await _usersRef.doc(member.relatedUserId).update({
          'calling': member.calling ?? '',
          'organization': displayOrg,
          'firstName': member.firstName,
          'lastName': member.lastName,
          'phoneNumber': member.phone,
          'ward': member.ward,
        });
        print("Usuario sincronizado correctamente.");
      } catch (e) {
        print("El usuario vinculado no existe o hubo error: $e");
      }
    }
  }

  Future<void> addMember(MemberModel member) async {
    return saveMember(member);
  }

  Future<void> updateMember(MemberModel member) async {
    return saveMember(member);
  }

  Future<void> deleteMember(String id) async {
    await _membersRef.doc(id).delete();
  }

  // --- CONSULTAS OPTIMIZADAS ---

  Future<List<MemberModel>> getMembers() async {
    final snapshot = await _membersRef.orderBy('lastName').get(
        const GetOptions(source: Source.serverAndCache)
    );
    return snapshot.docs.map((doc) {
      return MemberModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    }).toList();
  }

  Future<List<MemberModel>> searchMembers(String query) async {
    final snapshot = await _membersRef.get(const GetOptions(source: Source.serverAndCache));
    final allMembers = snapshot.docs.map((doc) => MemberModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();

    final lowerQuery = query.toLowerCase();
    return allMembers.where((m) =>
    m.fullName.toLowerCase().contains(lowerQuery) ||
        m.lastName.toLowerCase().contains(lowerQuery)
    ).toList();
  }

  Future<List<MemberModel>> getBirthdaysThisWeek() async {
    final snapshot = await _membersRef.get(const GetOptions(source: Source.serverAndCache));
    final now = DateTime.now();

    final members = snapshot.docs.map((doc) {
      return MemberModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    }).toList();

    final upcomingBirthdays = members.where((m) {
      if (m.birthDate == null) return false;

      final dob = m.birthDate!;
      final birthdayThisYear = DateTime(now.year, dob.month, dob.day);
      final birthdayNextYear = DateTime(now.year + 1, dob.month, dob.day);

      final diff = birthdayThisYear.difference(now).inDays;
      final diffNext = birthdayNextYear.difference(now).inDays;

      return (diff >= 0 && diff <= 7) || (diffNext >= 0 && diffNext <= 7);
    }).toList();

    upcomingBirthdays.sort((a, b) {
      final dobA = a.birthDate!;
      final dobB = b.birthDate!;
      final dateA = DateTime(2000, dobA.month, dobA.day);
      final dateB = DateTime(2000, dobB.month, dobB.day);
      return dateA.compareTo(dateB);
    });

    return upcomingBirthdays;
  }

  Future<void> importUsersToMembers() async {
    final usersSnapshot = await _usersRef.get();
    int count = 0;
    for (var userDoc in usersSnapshot.docs) {
      final userData = userDoc.data() as Map<String, dynamic>;
      final userId = userDoc.id;
      final email = userData['email'] as String? ?? '';
      final docCheck = await _membersRef.doc(userId).get();
      if (docCheck.exists) continue;
      if (email.isNotEmpty) {
        final emailCheck = await _membersRef.where('email', isEqualTo: email).get();
        if (emailCheck.docs.isNotEmpty) continue;
      }
      String firstName = userData['nombres'] ?? userData['firstName'] ?? '';
      String lastName = userData['apellidos'] ?? userData['lastName'] ?? '';
      if (firstName.isEmpty && userData['name'] != null) {
        List<String> parts = (userData['name'] as String).split(' ');
        firstName = parts.isNotEmpty ? parts[0] : '-';
        lastName = parts.length > 1 ? parts.sublist(1).join(' ') : '';
      }
      String phone = userData['phoneNumber'] ?? userData['phone'] ?? userData['celular'] ?? '';
      String calling = userData['calling'] ?? userData['llamamiento'] ?? '';

      String oldOrg = userData['organization'] ?? userData['organizacion'] ?? 'Miembro General';
      String ward = userData['ward'] ?? '';

      bool isYSA = false;
      if (oldOrg.toUpperCase().contains('JAS') || oldOrg.toUpperCase().contains('YSA')) {
        isYSA = true;
      }
      DateTime? birthDate;
      if (userData['birthDate'] != null && userData['birthDate'] is Timestamp) {
        birthDate = (userData['birthDate'] as Timestamp).toDate();
      }
      String gender = 'M';
      final orgLower = oldOrg.toLowerCase();
      final callLower = calling.toLowerCase();
      if (orgLower.contains('socorro') || orgLower.contains('mujeres') || callLower.contains('hermana')) {
        gender = 'F';
      }

      // 🚀 Aplicamos tu regla matemática a los usuarios antiguos que se sincronicen
      String orgPrincipal = _calcularOrganizacionPrincipal(birthDate, gender, oldOrg);

      final newMember = MemberModel(
        id: userId,
        firstName: firstName,
        lastName: lastName,
        gender: gender,
        primaryOrganization: orgPrincipal, // La membresía real por edad
        isYSA: isYSA,
        servingOrganization: oldOrg, // Donde sirve
        calling: calling.isNotEmpty ? calling : null,
        email: email,
        phone: phone,
        birthDate: birthDate,
        relatedUserId: userId,
        ward: ward,
      );
      await saveMember(newMember);
      count++;
    }
  }

  // ==========================================================
  // 🚀 MIGRACIÓN MASIVA DESDE JSON (DINÁMICA Y OPTIMIZADA)
  // ==========================================================

  String _generarRutaArchivo(String barrio) {
    String normalizado = barrio.toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u')
        .replaceAll(' ', '_');

    return 'assets/import_$normalizado.json';
  }

  Future<void> importarBarrioDesdeJson({required String barrioDestino}) async {
    try {
      String rutaArchivo = _generarRutaArchivo(barrioDestino);
      print("Iniciando importación para el barrio: $barrioDestino buscando el archivo: $rutaArchivo");

      final String response = await rootBundle.loadString(rutaArchivo);
      final List<dynamic> data = json.decode(response);

      final WriteBatch batch = FirebaseFirestore.instance.batch();
      int count = 0;

      for (var item in data) {
        final docRef = _membersRef.doc();

        String rawDate = item['birthDate'] ?? '';
        DateTime? parsedDate = DateTime.tryParse(rawDate);
        bool esJASReal = item['isYSA'] ?? false;
        String rawGender = item['gender'] ?? 'M';

        // 🚀 La que viene de LCR (sus clases) es la de Llamamiento
        String orgLlamamiento = item['primaryOrganization'] ?? 'Miembro General';

        // 🚀 La Principal la calculamos al 100% con tu regla de edades
        String orgPrincipal = _calcularOrganizacionPrincipal(parsedDate, rawGender, orgLlamamiento);

        final memberData = {
          'id': docRef.id,
          'firstName': item['firstName'],
          'lastName': item['lastName'],
          'fullName': '${item['firstName']} ${item['lastName']}',
          'gender': rawGender,
          'primaryOrganization': orgPrincipal,       // El cálculo matemático
          'servingOrganization': orgLlamamiento,     // Lo que decía LCR
          'isYSA': esJASReal,                        // Soltero de 18 a 35 (Viene de Python)
          'ward': barrioDestino,
          'birthDate': parsedDate != null ? Timestamp.fromDate(parsedDate) : null,
          'birthDateStr': rawDate,
        };

        batch.set(docRef, memberData, SetOptions(merge: true));
        count++;
      }

      await batch.commit();
      print('✅ ¡GOLAZO! Se importaron $count miembros al barrio $barrioDestino con reglas de edad aplicadas.');

    } catch (e) {
      print('❌ Error al importar: $e');
      throw Exception('No se pudo importar. Asegúrate de que el archivo JSON exista en la carpeta assets. Error: $e');
    }
  }
}