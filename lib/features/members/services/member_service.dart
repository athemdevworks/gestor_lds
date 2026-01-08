import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/member_model.dart';

class MemberService {
  final CollectionReference _membersRef = FirebaseFirestore.instance.collection('members');
  final CollectionReference _usersRef = FirebaseFirestore.instance.collection('users');

  // Crear o Actualizar Miembro
  Future<void> saveMember(MemberModel member) async {
    // Si el ID viene vacío, dejamos que Firestore genere uno, si no, usamos el ID que traemos
    final docRef = member.id.isEmpty ? _membersRef.doc() : _membersRef.doc(member.id);
    await docRef.set(member.toMap(), SetOptions(merge: true));
  }

  // Obtener lista completa (stream para tiempo real)
  Stream<List<MemberModel>> getMembers() {
    return _membersRef.orderBy('lastName').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return MemberModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  // Buscar miembros (Filtro en cliente por ahora)
  Future<List<MemberModel>> searchMembers(String query) async {
    final snapshot = await _membersRef.get();
    final allMembers = snapshot.docs.map((doc) => MemberModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();

    final lowerQuery = query.toLowerCase();
    return allMembers.where((m) =>
    m.fullName.toLowerCase().contains(lowerQuery) ||
        m.lastName.toLowerCase().contains(lowerQuery)
    ).toList();
  }

  // Borrar miembro
  Future<void> deleteMember(String id) async {
    await _membersRef.doc(id).delete();
  }

  // --- FUNCIÓN DE IMPORTACIÓN CORREGIDA ---
  Future<void> importUsersToMembers() async {
    final usersSnapshot = await _usersRef.get();
    int count = 0;

    for (var userDoc in usersSnapshot.docs) {
      final userData = userDoc.data() as Map<String, dynamic>;
      final userId = userDoc.id;
      final email = userData['email'] as String? ?? '';

      // 1. EVITAR DUPLICADOS (Mejorado)
      // Primero verificamos si ya existe un miembro con este ID (es lo ideal)
      final docCheck = await _membersRef.doc(userId).get();
      if (docCheck.exists) continue;

      // Por seguridad, verificamos también por email si el ID no coincidió
      if (email.isNotEmpty) {
        final emailCheck = await _membersRef.where('email', isEqualTo: email).get();
        if (emailCheck.docs.isNotEmpty) continue;
      }

      // 2. OBTENER DATOS (Mapeo corregido)
      // Priorizamos 'nombres' y 'apellidos' que es lo que usa tu Registro
      String firstName = userData['nombres'] ?? userData['firstName'] ?? '';
      String lastName = userData['apellidos'] ?? userData['lastName'] ?? '';

      // Fallback: Si están vacíos, intentamos separar el 'name'
      if (firstName.isEmpty && userData['name'] != null) {
        List<String> parts = (userData['name'] as String).split(' ');
        firstName = parts.isNotEmpty ? parts[0] : '-';
        lastName = parts.length > 1 ? parts.sublist(1).join(' ') : '';
      }

      // CORRECCIÓN TELÉFONO: El registro usa 'phoneNumber'
      String phone = userData['phoneNumber'] ?? userData['phone'] ?? userData['celular'] ?? '';

      String calling = userData['calling'] ?? userData['llamamiento'] ?? '';
      String organization = userData['organization'] ?? userData['organizacion'] ?? 'Barrio';

      // CORRECCIÓN FECHA: Convertir Timestamp a DateTime
      DateTime? birthDate;
      if (userData['birthDate'] != null) {
        // Validación de seguridad por si no es Timestamp
        if (userData['birthDate'] is Timestamp) {
          birthDate = (userData['birthDate'] as Timestamp).toDate();
        }
      }

      // 3. DEFINIR GÉNERO
      String gender = 'M'; // Default
      // Lógica automática básica
      final orgLower = organization.toLowerCase();
      final callLower = calling.toLowerCase();

      if (orgLower.contains('socorro') ||
          orgLower.contains('mujeres') ||
          orgLower.contains('primaria') ||
          callLower.contains('hermana') ||
          callLower.contains('presidenta') ||
          callLower.contains('consejera') ||
          callLower.contains('maestra')) {
        gender = 'F';
      }

      // 4. CREAR EL MIEMBRO
      final newMember = MemberModel(
        id: userId, // Usamos el mismo ID del usuario para vincularlos
        firstName: firstName,
        lastName: lastName,
        fullName: '$firstName $lastName',
        gender: gender,
        email: email,
        phone: phone, // Ahora sí lleva el teléfono
        birthDate: birthDate, // Ahora sí lleva la fecha
        organization: organization,
        calling: calling.isNotEmpty ? calling : null,
        relatedUserId: userId,
      );

      await saveMember(newMember);
      count++;
    }

    print("Migración completada: $count miembros importados.");
  }

  // Obtener cumpleañeros de la semana (Lógica mantenida)
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
          final dobA = a.birthDate!;
          final dobB = b.birthDate!;
          final dateA = DateTime(2000, dobA.month, dobA.day);
          final dateB = DateTime(2000, dobB.month, dobB.day);
          return dateA.compareTo(dateB);
        });
    });
  }
}