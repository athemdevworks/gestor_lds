import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:gestor_lds/features/auth/models/user_model.dart';
import 'package:gestor_lds/features/commitments/models/commitment_model.dart';
import 'package:gestor_lds/features/commitments/services/commitment_service.dart';

class MyCommitmentsScreen extends StatelessWidget {
  final UserModel currentUser;

  // Instanciamos el servicio como propiedad de la clase
  final CommitmentService _commitmentService = CommitmentService();

  MyCommitmentsScreen({super.key, required this.currentUser});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Compromisos'),
      ),
      body: StreamBuilder<List<CommitmentModel>>(
        // Llama al servicio filtrando por el UID del usuario actual
        stream: _commitmentService.getCommitmentsForUser(currentUser.uid),
        builder: (context, snapshot) {

          // 1. Estado de Carga
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // 2. Estado de Error
          if (snapshot.hasError) {
            return Center(child: Text('Error al cargar datos: ${snapshot.error}'));
          }

          final commitments = snapshot.data ?? [];

          // 3. Estado Vacío
          if (commitments.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.thumb_up_alt_outlined, size: 60, color: Colors.green.shade300),
                  const SizedBox(height: 20),
                  const Text(
                    '¡Estás al día! No tienes compromisos pendientes.',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          // 4. Lista de Compromisos
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: commitments.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final commitment = commitments[index];

              // Verificamos si está vencido y aún no se completa
              final isOverdue = commitment.dueDate.isBefore(DateTime.now())
                  && !commitment.isCompleted;

              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Checkbox(
                  value: commitment.isCompleted,
                  activeColor: Theme.of(context).primaryColor,
                  onChanged: (bool? value) {
                    // Actualizar estado en Firestore
                    if (value != null) {
                      _commitmentService.toggleCompletion(commitment.id, value);
                    }
                  },
                ),
                title: Text(
                  commitment.description,
                  style: TextStyle(
                    decoration: commitment.isCompleted ? TextDecoration.lineThrough : null,
                    color: commitment.isCompleted ? Colors.grey : Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    // Mostrar Referencia al Tema (Si existe)
                    if (commitment.agendaItemTopic != null && commitment.agendaItemTopic!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4.0),
                        child: Text(
                          'Ref: ${commitment.agendaItemTopic}',
                          style: TextStyle(fontSize: 12, color: Theme.of(context).primaryColor),
                        ),
                      ),

                    // Fecha de Vencimiento
                    Row(
                      children: [
                        Icon(
                            Icons.calendar_today,
                            size: 14,
                            color: isOverdue ? Colors.red : Colors.grey
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Vence: ${DateFormat('dd/MM/yyyy').format(commitment.dueDate)}',
                          style: TextStyle(
                            fontSize: 13,
                            color: isOverdue ? Colors.red : Colors.grey.shade700,
                            fontWeight: isOverdue ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                trailing: isOverdue
                    ? const Tooltip(
                  message: 'Compromiso Vencido',
                  child: Icon(Icons.warning_amber_rounded, color: Colors.red),
                )
                    : null,
              );
            },
          );
        },
      ),
    );
  }
}