import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/member_model.dart';
import 'dart:convert';
import 'package:flutter/services.dart';

class MemberService {
  final CollectionReference _membersRef = FirebaseFirestore.instance.collection('members');
  final CollectionReference _usersRef = FirebaseFirestore.instance.collection('users');

  // --- MÉTODOS CRUD PRINCIPALES ---

  // Guardar (Crear o Editar) con SINCRONIZACIÓN DE USUARIO
  Future<void> saveMember(MemberModel member) async {
    // 1. Guardar el Miembro (Directorio)
    final docRef = member.id.isEmpty ? _membersRef.doc() : _membersRef.doc(member.id);
    await docRef.set(member.toMap(), SetOptions(merge: true));

    // 2. --- SINCRONIZACIÓN (EFECTO ESPEJO) ---
    if (member.relatedUserId != null && member.relatedUserId!.isNotEmpty) {
      try {
        String displayOrg = member.servingOrganization ?? member.primaryOrganization;

        await _usersRef.doc(member.relatedUserId).update({
          'calling': member.calling ?? '',
          'organization': displayOrg,
          'firstName': member.firstName, // ✅ Corregido al nuevo estándar
          'lastName': member.lastName,   // ✅ Corregido al nuevo estándar
          'phoneNumber': member.phone,
          'ward': member.ward,           // ✅ Sincronizamos el barrio también
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

  // --- CONSULTAS OPTIMIZADAS (AHORRO DE COSTOS Y SOPORTE OFFLINE) ---

  // Obtener lista completa (Lectura Única con Caché)
  Future<List<MemberModel>> getMembers() async {
    final snapshot = await _membersRef.orderBy('lastName').get(
        const GetOptions(source: Source.serverAndCache) // Optimizado para offline y costos
    );
    return snapshot.docs.map((doc) {
      return MemberModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    }).toList();
  }

  // Buscar miembros (Filtro en cliente)
  Future<List<MemberModel>> searchMembers(String query) async {
    final snapshot = await _membersRef.get(
        const GetOptions(source: Source.serverAndCache)
    );
    final allMembers = snapshot.docs.map((doc) => MemberModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();

    final lowerQuery = query.toLowerCase();
    return allMembers.where((m) =>
    m.fullName.toLowerCase().contains(lowerQuery) ||
        m.lastName.toLowerCase().contains(lowerQuery)
    ).toList();
  }

  // Obtener cumpleañeros de la semana (Lectura Única)
  Future<List<MemberModel>> getBirthdaysThisWeek() async {
    final snapshot = await _membersRef.get(
        const GetOptions(source: Source.serverAndCache)
    );
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

    // Ordenar por fecha próxima
    upcomingBirthdays.sort((a, b) {
      final dobA = a.birthDate!;
      final dobB = b.birthDate!;
      final dateA = DateTime(2000, dobA.month, dobA.day);
      final dateB = DateTime(2000, dobB.month, dobB.day);
      return dateA.compareTo(dateB);
    });

    return upcomingBirthdays;
  }

  // --- IMPORTACIÓN Y MIGRACIÓN ---
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
      String oldOrg = userData['organization'] ?? userData['organizacion'] ?? 'Barrio';

      // 👇 NUEVO: Extraemos el barrio o le ponemos Jerusalén por defecto
      String ward = userData['ward'] ?? 'Jerusalén';

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

      final newMember = MemberModel(
        id: userId,
        firstName: firstName,
        lastName: lastName,
        gender: gender,
        primaryOrganization: oldOrg,
        isYSA: isYSA,
        servingOrganization: null,
        calling: calling.isNotEmpty ? calling : null,
        email: email,
        phone: phone,
        birthDate: birthDate,
        relatedUserId: userId,
        ward: ward, // ✅ Obligatorio en el nuevo modelo
      );

      await saveMember(newMember);
      count++;
    }
    print("Migración completada: $count miembros importados.");
  }

  // --- MIGRACIÓN MASIVA DESDE JSON ---
  Future<void> importarBarrioDesdeJson() async {
    try {
      print("Iniciando importación...");
      // 1. Cargar el JSON desde los assets
      final String response = await rootBundle.loadString('assets/import_nuevo_trujillo.json');
      final List<dynamic> data = json.decode(response);

      final WriteBatch batch = FirebaseFirestore.instance.batch();
      int count = 0;

      for (var item in data) {
        final docRef = _membersRef.doc(); // Crea un ID aleatorio nuevo

        // 2. Mapeamos la data. (La fecha la guardamos como String temporalmente para no complicarnos con los formatos en español)
        final memberData = {
          'id': docRef.id,
          'firstName': item['firstName'],
          'lastName': item['lastName'],
          'fullName': '${item['firstName']} ${item['lastName']}',
          'gender': item['gender'],
          'primaryOrganization': item['primaryOrganization'],
          'isYSA': item['isYSA'],
          'ward': item['ward'],
          'birthDateStr': item['birthDate'], // Guardamos el texto "2 mayo 2008" directo
        };

        batch.set(docRef, memberData, SetOptions(merge: true));
        count++;

        // Firebase permite subir máximo 500 por lote. Estamos en 441, así que sobra espacio.
      }

      await batch.commit();
      print('✅ ¡GOLAZO! Se importaron $count miembros a la Estaca.');

    } catch (e) {
      print('❌ Error al importar: $e');
    }
  }

}