import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/member_model.dart';

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
    // Si este miembro tiene un usuario de sistema vinculado, actualizamos su etiqueta también.
    if (member.relatedUserId != null && member.relatedUserId!.isNotEmpty) {
      try {
        // Definimos qué organización mostrar en el Usuario:
        // Si tiene cargo de servicio (Ej: Primaria), mostramos ese.
        // Si fue relevado (null), mostramos su organización base (Ej: Soc. Socorro).
        String displayOrg = member.servingOrganization ?? member.primaryOrganization;

        await _usersRef.doc(member.relatedUserId).update({
          // Actualizamos Llamamiento (Si es null, guardamos string vacío para borrarlo)
          'calling': member.calling ?? '',

          // Actualizamos Organización (Para que ya no diga Primaria si no trabaja ahí)
          'organization': displayOrg,

          // Opcional: Sincronizar también nombres y teléfonos para mantener todo igual
          'nombres': member.firstName,
          'apellidos': member.lastName,
          'phoneNumber': member.phone,
        });
        print("Usuario sincronizado correctamente.");
      } catch (e) {
        print("El usuario vinculado no existe o hubo error: $e");
        // No lanzamos error para no detener el guardado del miembro
      }
    }
  }

  // Agregar nuevo (Wrapper para claridad en el Formulario)
  Future<void> addMember(MemberModel member) async {
    return saveMember(member);
  }

  // Actualizar existente (Wrapper para claridad en el Formulario)
  Future<void> updateMember(MemberModel member) async {
    return saveMember(member);
  }

  // Borrar miembro
  Future<void> deleteMember(String id) async {
    await _membersRef.doc(id).delete();
  }

  // --- CONSULTAS ---

  // Obtener lista completa en tiempo real
  Stream<List<MemberModel>> getMembers() {
    return _membersRef.orderBy('lastName').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return MemberModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  // Buscar miembros (Filtro en cliente)
  Future<List<MemberModel>> searchMembers(String query) async {
    final snapshot = await _membersRef.get();
    final allMembers = snapshot.docs.map((doc) => MemberModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();

    final lowerQuery = query.toLowerCase();
    return allMembers.where((m) =>
    m.fullName.toLowerCase().contains(lowerQuery) || // fullName es un getter ahora, funciona igual
        m.lastName.toLowerCase().contains(lowerQuery)
    ).toList();
  }

  // Obtener cumpleañeros de la semana
  Stream<List<MemberModel>> getBirthdaysThisWeek() {
    return _membersRef.snapshots().map((snapshot) {
      final now = DateTime.now();

      final members = snapshot.docs.map((doc) {
        return MemberModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();

      return members.where((m) {
        if (m.birthDate == null) return false;

        final dob = m.birthDate!;
        final birthdayThisYear = DateTime(now.year, dob.month, dob.day);
        final birthdayNextYear = DateTime(now.year + 1, dob.month, dob.day);

        final diff = birthdayThisYear.difference(now).inDays;
        final diffNext = birthdayNextYear.difference(now).inDays;

        // Rango: Hoy (0) hasta próximos 7 días
        return (diff >= 0 && diff <= 7) || (diffNext >= 0 && diffNext <= 7);
      }).toList()
        ..sort((a, b) {
          // Ordenar por fecha próxima
          final dobA = a.birthDate!;
          final dobB = b.birthDate!;
          final dateA = DateTime(2000, dobA.month, dobA.day);
          final dateB = DateTime(2000, dobB.month, dobB.day);
          return dateA.compareTo(dateB);
        });
    });
  }

  // --- IMPORTACIÓN Y MIGRACIÓN (ADAPTADO AL NUEVO MODELO) ---
  Future<void> importUsersToMembers() async {
    final usersSnapshot = await _usersRef.get();
    int count = 0;

    for (var userDoc in usersSnapshot.docs) {
      final userData = userDoc.data() as Map<String, dynamic>;
      final userId = userDoc.id;
      final email = userData['email'] as String? ?? '';

      // 1. Evitar duplicados
      final docCheck = await _membersRef.doc(userId).get();
      if (docCheck.exists) continue;

      if (email.isNotEmpty) {
        final emailCheck = await _membersRef.where('email', isEqualTo: email).get();
        if (emailCheck.docs.isNotEmpty) continue;
      }

      // 2. Obtener Datos Básicos
      String firstName = userData['nombres'] ?? userData['firstName'] ?? '';
      String lastName = userData['apellidos'] ?? userData['lastName'] ?? '';

      if (firstName.isEmpty && userData['name'] != null) {
        List<String> parts = (userData['name'] as String).split(' ');
        firstName = parts.isNotEmpty ? parts[0] : '-';
        lastName = parts.length > 1 ? parts.sublist(1).join(' ') : '';
      }

      String phone = userData['phoneNumber'] ?? userData['phone'] ?? userData['celular'] ?? '';
      String calling = userData['calling'] ?? userData['llamamiento'] ?? '';

      // La organización antigua se mapea a primaryOrganization
      String oldOrg = userData['organization'] ?? userData['organizacion'] ?? 'Barrio';

      // 3. Detectar si es JAS (Lógica simple)
      bool isYSA = false;
      if (oldOrg.toUpperCase().contains('JAS') || oldOrg.toUpperCase().contains('YSA')) {
        isYSA = true;
      }

      // 4. Fechas
      DateTime? birthDate;
      if (userData['birthDate'] != null && userData['birthDate'] is Timestamp) {
        birthDate = (userData['birthDate'] as Timestamp).toDate();
      }

      // 5. Género
      String gender = 'M';
      final orgLower = oldOrg.toLowerCase();
      final callLower = calling.toLowerCase();
      if (orgLower.contains('socorro') || orgLower.contains('mujeres') || callLower.contains('hermana')) {
        gender = 'F';
      }

      // 6. CREAR EL NUEVO MODELO (Sin fullName, con nuevos campos)
      final newMember = MemberModel(
        id: userId,
        firstName: firstName,
        lastName: lastName,
        // fullName: SE ELIMINÓ (es getter ahora)
        gender: gender,

        // Mapeo Nuevo:
        primaryOrganization: oldOrg, // Asumimos que lo que había antes era su org principal
        isYSA: isYSA,
        servingOrganization: null,   // Por defecto nulo en migración
        calling: calling.isNotEmpty ? calling : null,

        email: email,
        phone: phone,
        birthDate: birthDate,
        relatedUserId: userId,
      );

      await saveMember(newMember);
      count++;
    }
    print("Migración completada: $count miembros importados.");
  }
}