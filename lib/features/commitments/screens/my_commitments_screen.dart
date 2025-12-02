import 'package:flutter/material.dart';
import 'package:gestor_lds/features/auth/models/user_model.dart';
import 'package:gestor_lds/features/commitments/models/commitment_model.dart';
import 'package:gestor_lds/features/commitments/services/commitment_service.dart';
import 'package:intl/intl.dart';

class MyCommitmentsScreen extends StatelessWidget {
  final UserModel currentUser;

  const MyCommitmentsScreen({super.key, required this.currentUser});

  @override
  Widget build(BuildContext context) {
    final CommitmentService commitmentService = CommitmentService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Compromisos'),
      ),
      body: StreamBuilder<List<CommitmentModel>>(
        // Llama al servicio filtrando por el UID del usuario actual
        stream: commitmentService.getCommitmentsForUser(currentUser.uid),
        builder: (context, snapshot) {

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final commitments = snapshot.data ?? [];

          if (commitments.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.thumb_up_alt_outlined, size: 60, color: Colors.green),
                  SizedBox(height: 20),
                  Text('¡Estás al día! No tienes compromisos pendientes.',
                      style: TextStyle(fontSize: 16)),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: commitments.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final commitment = commitments[index];
              final isOverdue = commitment.dueDate.isBefore(DateTime.now()) && !commitment.isCompleted;

              return ListTile(
                leading: Checkbox(
                  value: commitment.isCompleted,
                  onChanged: (bool? value) {
                    // Actualizar estado en Firestore
                    if (value != null) {
                      commitmentService.toggleCompletion(commitment.id, value);
                    }
                  },
                ),
                title: Text(
                  commitment.description,
                  style: TextStyle(
                    decoration: commitment.isCompleted ? TextDecoration.lineThrough : null,
                    color: commitment.isCompleted ? Colors.grey : Colors.black,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (commitment.agendaItemTopic != null)
                      Text('Ref: ${commitment.agendaItemTopic}',
                          style: TextStyle(fontSize: 12, color: Colors.indigo.shade700)),
                    Text(
                      'Vence: ${DateFormat('dd/MM/yyyy').format(commitment.dueDate)}',
                      style: TextStyle(
                        color: isOverdue ? Colors.red : Colors.grey.shade700,
                        fontWeight: isOverdue ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
                trailing: isOverdue
                    ? const Icon(Icons.warning, color: Colors.red)
                    : null,
              );
            },
          );
        },
      ),
    );
  }
}