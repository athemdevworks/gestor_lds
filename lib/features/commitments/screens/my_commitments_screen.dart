import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:gestor_lds/features/auth/models/user_model.dart';
import 'package:gestor_lds/features/commitments/models/commitment_model.dart';
import 'package:gestor_lds/features/commitments/services/commitment_service.dart';

class MyCommitmentsScreen extends StatefulWidget {
  final UserModel currentUser;

  const MyCommitmentsScreen({super.key, required this.currentUser});

  @override
  State<MyCommitmentsScreen> createState() => _MyCommitmentsScreenState();
}

class _MyCommitmentsScreenState extends State<MyCommitmentsScreen> with SingleTickerProviderStateMixin {
  final CommitmentService _commitmentService = CommitmentService();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    // Color corporativo (puedes usar Theme.of(context).primaryColor si prefieres)
    const brandBlue = Color(0xFF164772);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Compromisos'),
        backgroundColor: brandBlue,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: Colors.orange, // Un toque de color para resaltar la selección
          tabs: const [
            Tab(text: 'PENDIENTES', icon: Icon(Icons.assignment_late_outlined)),
            Tab(text: 'HISTORIAL', icon: Icon(Icons.assignment_turned_in_outlined)),
          ],
        ),
      ),
      body: StreamBuilder<List<CommitmentModel>>(
        stream: _commitmentService.getCommitmentsForUser(widget.currentUser.uid),
        builder: (context, snapshot) {

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final allCommitments = snapshot.data ?? [];

          // Separamos la lista en dos
          final pendingList = allCommitments.where((c) => !c.isCompleted).toList();
          final completedList = allCommitments.where((c) => c.isCompleted).toList();

          return TabBarView(
            controller: _tabController,
            children: [
              // PESTAÑA 1: PENDIENTES
              _buildCommitmentList(pendingList, isHistory: false),

              // PESTAÑA 2: HISTORIAL
              _buildCommitmentList(completedList, isHistory: true),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCommitmentList(List<CommitmentModel> list, {required bool isHistory}) {
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
                isHistory ? Icons.history : Icons.thumb_up_alt_outlined,
                size: 60,
                color: Colors.grey.shade300
            ),
            const SizedBox(height: 20),
            Text(
              isHistory
                  ? 'No tienes tareas completadas aún.'
                  : '¡Estás al día! No tienes pendientes.',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      separatorBuilder: (context, index) => const Divider(),
      itemBuilder: (context, index) {
        final commitment = list[index];

        // Lógica de vencimiento (solo importa si no está completado)
        final isOverdue = !commitment.isCompleted &&
            commitment.dueDate.isBefore(DateTime.now().subtract(const Duration(days: 1)));

        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Transform.scale(
            scale: 1.2,
            child: Checkbox(
              value: commitment.isCompleted,
              activeColor: Colors.green,
              shape: const CircleBorder(),
              onChanged: (bool? value) {
                if (value != null) {
                  _commitmentService.toggleCompletion(commitment.id, value);
                }
              },
            ),
          ),
          title: Text(
            commitment.description,
            style: TextStyle(
              decoration: commitment.isCompleted ? TextDecoration.lineThrough : null,
              color: commitment.isCompleted ? Colors.grey : Colors.black87,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              // Referencia al tema
              if (commitment.agendaItemTopic != null && commitment.agendaItemTopic!.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Ref: ${commitment.agendaItemTopic}',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade800),
                  ),
                ),

              const SizedBox(height: 4),

              // Fecha
              Row(
                children: [
                  Icon(
                      Icons.calendar_today,
                      size: 13,
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
                  if (isOverdue)
                    const Padding(
                      padding: EdgeInsets.only(left: 8.0),
                      child: Text("(Vencido)", style: TextStyle(color: Colors.red, fontSize: 12, fontStyle: FontStyle.italic)),
                    )
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}