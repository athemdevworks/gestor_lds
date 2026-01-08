import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/member_model.dart';

class MemberService {
  final CollectionReference _membersRef = FirebaseFirestore.instance.collection('members');

  // Crear o Actualizar Miembro
  Future<void> saveMember(MemberModel member) async {
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

  // Buscar miembros por nombre (para el Autocomplete)
  Future<List<MemberModel>> searchMembers(String query) async {
    // Nota: Firestore es limitado en búsquedas de texto parcial.
    // Una técnica simple es traer todo y filtrar en memoria si son < 500 miembros.
    // O usar un campo "keywords". Por ahora, filtramos en cliente para v1.

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

  Future<void> importUsersToMembers() async {
    final usersSnapshot = await FirebaseFirestore.instance.collection('users').get();

    int count = 0;

    for (var userDoc in usersSnapshot.docs) {
      final userData = userDoc.data();
      final userId = userDoc.id;
      final email = userData['email'] as String? ?? '';

      // 1. Evitar duplicados
      final existingCheck = await _membersRef.where('email', isEqualTo: email).get();
      if (existingCheck.docs.isNotEmpty) continue;

      // 2. OBTENER DATOS REALES (Ya no adivinamos)
      // Nota: Uso 'firstName' y 'lastName' asumiendo que así se llaman en Firebase
      // Si en tu BD se llaman 'nombres' y 'apellidos', cámbialo aquí abajo.
      String firstName = userData['firstName'] ?? userData['nombres'] ?? '';
      String lastName = userData['lastName'] ?? userData['apellidos'] ?? '';

      // Fallback: Si por alguna razón están vacíos, intentamos separar el 'name' completo
      if (firstName.isEmpty && userData['name'] != null) {
        List<String> parts = (userData['name'] as String).split(' ');
        firstName = parts.isNotEmpty ? parts[0] : '-';
        lastName = parts.length > 1 ? parts.sublist(1).join(' ') : '';
      }

      String phone = userData['phone'] ?? userData['celular'] ?? '';
      String calling = userData['calling'] ?? userData['llamamiento'] ?? '';
      String organization = userData['organization'] ?? userData['organizacion'] ?? 'Sin Asignar';

      // 3. DEFINIR GÉNERO (Esto sí hay que deducirlo o poner default)
      // Si la organización es de mujeres, ponemos F, si no, asumimos M y luego se edita.
      String gender = 'M';
      if (organization.toLowerCase().contains('socorro') ||
          organization.toLowerCase().contains('mujeres') ||
          organization.toLowerCase().contains('primaria') || // Usualmente hermanas
          calling.toLowerCase().contains('hermana') ||
          calling.toLowerCase().contains('presidenta') ||
          calling.toLowerCase().contains('consejera') ||
          calling.toLowerCase().contains('maestra')) {
        gender = 'F';
      }

      // 4. CREAR EL MIEMBRO
      final newMember = MemberModel(
        id: '',
        firstName: firstName,
        lastName: lastName,
        fullName: '$firstName $lastName', // Armamos el nombre completo para búsquedas
        gender: gender,
        email: email,
        phone: phone.isNotEmpty ? phone : null,
        organization: organization,
        calling: calling.isNotEmpty ? calling : null,
        relatedUserId: userId, // ¡Vinculado!
      );

      await saveMember(newMember);
      count++;
    }

    print("Migración Inteligente completada: $count miembros creados.");
  }

  // Obtener cumpleañeros de la semana actual
  Stream<List<MemberModel>> getBirthdaysThisWeek() {
    return _membersRef.snapshots().map((snapshot) {
      final now = DateTime.now();
      // Calculamos el rango de la semana (Lunes a Domingo o Hoy a 7 días)
      // Vamos a hacerlo simple: Próximos 7 días incluyendo hoy.

      final members = snapshot.docs.map((doc) {
        return MemberModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();

      return members.where((m) {
        if (m.birthDate == null) return false;

        final dob = m.birthDate!;
        // Creamos una fecha de "cumpleaños este año"
        final birthdayThisYear = DateTime(now.year, dob.month, dob.day);

        // Ajuste por si el cumple ya pasó este año pero es en los próximos días del año siguiente (ej: estamos 30 dic y cumple es 2 ene)
        final birthdayNextYear = DateTime(now.year + 1, dob.month, dob.day);

        final diff = birthdayThisYear.difference(now).inDays;
        final diffNext = birthdayNextYear.difference(now).inDays;

        // Si es hoy (0) o en los próximos 7 días
        return (diff >= 0 && diff <= 7) || (diffNext >= 0 && diffNext <= 7);
      }).toList()
        ..sort((a, b) {
          // Ordenar por quién cumple primero
          final dobA = a.birthDate!;
          final dobB = b.birthDate!;
          // Comparar solo mes y día
          final dateA = DateTime(2000, dobA.month, dobA.day);
          final dateB = DateTime(2000, dobB.month, dobB.day);
          return dateA.compareTo(dateB);
        });
    });

  }

}