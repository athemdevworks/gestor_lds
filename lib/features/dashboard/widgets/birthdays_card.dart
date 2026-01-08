import 'package:flutter/material.dart';
import 'package:gestor_lds/features/members/models/member_model.dart';
import 'package:gestor_lds/features/members/services/member_service.dart';
import 'package:intl/intl.dart';

class BirthdaysCard extends StatelessWidget {
  const BirthdaysCard({super.key});

  @override
  Widget build(BuildContext context) {
    final MemberService memberService = MemberService();

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
              child: StreamBuilder<List<MemberModel>>(
                stream: memberService.getBirthdaysThisWeek(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final birthdays = snapshot.data ?? [];

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
                      final member = birthdays[index];
                      final date = member.birthDate!;
                      // Formato: "20 de Enero"
                      final dateStr = DateFormat("d 'de' MMMM", 'es').format(date);

                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor: Colors.pink.shade50,
                          child: Text('🎂', style: TextStyle(fontSize: 16)),
                        ),
                        title: Text(member.fullName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
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