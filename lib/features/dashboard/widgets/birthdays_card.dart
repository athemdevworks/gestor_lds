import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import 'package:gestor_lds/features/auth/models/user_model.dart'; // 🚀 IMPORTAMOS EL NUEVO MODELO

class BirthdaysCard extends StatelessWidget {
  const BirthdaysCard({super.key});

// 🚀 TÁCTICA DE SEGURIDAD RELAJADA: Mostramos a todos los del barrio sin importar si usan la app
  Future<QuerySnapshot> _getUsersQuery() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw Exception('No autenticado');

    final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final currentUser = UserModel.fromMap(userDoc.data()!, userDoc.id);

    // Quitamos el filtro de isApproved
    Query query = FirebaseFirestore.instance.collection('users');

    // Si no es admin global, solo ve los de su barrio
    if (!currentUser.canSeeAllWards) {
      query = query.where('ward', isEqualTo: currentUser.ward);
    }

    return query.get();
  }

  // 🚀 TÁCTICA DE FILTRADO LOCAL: Buscar cumpleaños en los próximos 7 días
  List<UserModel> _filterUpcomingBirthdays(List<UserModel> allUsers) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final nextWeek = today.add(const Duration(days: 7));

    List<UserModel> upcoming = [];

    for (var user in allUsers) {
      if (user.birthDate == null) continue;

      // Calculamos el cumpleaños de este año
      DateTime bdayThisYear = DateTime(today.year, user.birthDate!.month, user.birthDate!.day);

      // Si ya pasó este año, calculamos para el próximo año
      if (bdayThisYear.isBefore(today)) {
        bdayThisYear = DateTime(today.year + 1, user.birthDate!.month, user.birthDate!.day);
      }

      // Si cae en los próximos 7 días (incluyendo hoy)
      if (bdayThisYear.isAfter(today.subtract(const Duration(days: 1))) &&
          bdayThisYear.isBefore(nextWeek.add(const Duration(days: 1)))) {
        upcoming.add(user);
      }
    }

    // Ordenar cronológicamente (los más próximos primero)
    upcoming.sort((a, b) {
      DateTime aDate = DateTime(today.year, a.birthDate!.month, a.birthDate!.day);
      if (aDate.isBefore(today)) aDate = DateTime(today.year + 1, a.birthDate!.month, a.birthDate!.day);

      DateTime bDate = DateTime(today.year, b.birthDate!.month, b.birthDate!.day);
      if (bDate.isBefore(today)) bDate = DateTime(today.year + 1, b.birthDate!.month, b.birthDate!.day);

      return aDate.compareTo(bDate);
    });

    return upcoming;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.cake, color: Colors.pink.shade400, size: 28),
                const SizedBox(width: 10),
                const Text(
                  'Cumpleaños (7 días)',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(),
            Expanded(
              child: FutureBuilder<QuerySnapshot>(
                future: _getUsersQuery(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return const Center(child: Text('Error al cargar datos', style: TextStyle(color: Colors.red)));
                  }

                  // 🚀 CONVERTIMOS LA RESPUESTA EN NUESTRO MODELO
                  final allUsers = snapshot.data?.docs.map((doc) =>
                      UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)
                  ).toList() ?? [];

                  // 🚀 FILTRAMOS A LOS CUMPLEAÑEROS
                  final birthdays = _filterUpcomingBirthdays(allUsers);

                  if (birthdays.isEmpty) {
                    return Center(
                      child: Text(
                        'No hay cumpleaños esta semana 🎉',
                        style: TextStyle(color: Colors.grey.shade600, fontStyle: FontStyle.italic),
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: birthdays.length,
                    itemBuilder: (context, index) {
                      final user = birthdays[index];
                      final date = user.birthDate!;
                      // Formato: "20 de Enero"
                      final dateStr = DateFormat("d 'de' MMMM", 'es').format(date);

                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor: Colors.pink.shade50,
                          child: const Text('🎂', style: TextStyle(fontSize: 16)),
                        ),
                        // 🚀 USAMOS LOS NOMBRES DEL USERMODEL
                        title: Text('${user.firstName} ${user.lastName}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        subtitle: Text(dateStr, style: TextStyle(color: Colors.pink.shade700, fontWeight: FontWeight.w500)),
                        dense: true,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}