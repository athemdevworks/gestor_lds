import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import 'package:gestor_lds/features/auth/models/user_model.dart';
import 'package:gestor_lds/features/commitments/models/commitment_model.dart';
import 'package:gestor_lds/features/commitments/services/commitment_service.dart';
import 'package:gestor_lds/features/commitments/widgets/new_commitment_modal.dart';

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
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const brandBlue = Color(0xFF22539A);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Compromisos'),
        backgroundColor: brandBlue,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: Colors.orange,
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
          final pendingList = allCommitments.where((c) => !c.isCompleted).toList();
          final completedList = allCommitments.where((c) => c.isCompleted).toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _buildCommitmentList(pendingList, isHistory: false),
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
              color: Colors.grey.shade300,
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
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 13,
                    color: isOverdue ? Colors.red : Colors.grey,
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
                      child: Text(
                        "(Vencido)",
                        style: TextStyle(color: Colors.red, fontSize: 12, fontStyle: FontStyle.italic),
                      ),
                    )
                ],
              ),
            ],
          ),
          trailing: PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.grey),
            onSelected: (value) {
              if (value == 'share') {
                _compartirPorWhatsApp(commitment);
              } else if (value == 'edit') {
                _editarCompromiso(commitment);
              } else if (value == 'delete') {
                _confirmarEliminarCompromiso(commitment);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'share',
                child: Row(
                  children: [
                    Icon(Icons.share, color: Colors.green, size: 20),
                    SizedBox(width: 8),
                    Text('Recordar por WhatsApp'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit_outlined, color: Colors.blue, size: 20),
                    SizedBox(width: 8),
                    Text('Editar'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, color: Colors.red, size: 20),
                    SizedBox(width: 8),
                    Text('Eliminar'),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // =========================================================================
  // 🚀 MÉTODOS DE ACCIÓN RÁPIDA
  // =========================================================================

  Future<void> _compartirPorWhatsApp(CommitmentModel commitment) async {
    final String fecha = DateFormat('dd/MM/yyyy').format(commitment.dueDate);
    final String referencia = (commitment.agendaItemTopic != null && commitment.agendaItemTopic!.isNotEmpty)
        ? '\n📌 *Tema:* ${commitment.agendaItemTopic}'
        : '';

    final String mensaje = '📋 *RECORDATORIO DE COMPROMISO*\n'
        'Estimado(a) hermano(a), te recordamos tu asignación:\n\n'
        '▫️ *Tarea:* ${commitment.description}'
        '$referencia\n'
        '🗓 *Fecha límite:* $fecha\n\n'
        '_GestorLDS_';

    await Share.share(mensaje);
  }

  void _editarCompromiso(CommitmentModel commitment) {
    showDialog(
      context: context,
      builder: (ctx) => NewCommitmentModal(
        meetingId: commitment.meetingId ?? '',
        commitmentToEdit: commitment,
      ),
    );
  }

  void _confirmarEliminarCompromiso(CommitmentModel commitment) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('Eliminar Compromiso'),
          ],
        ),
        content: const Text('¿Estás seguro de que deseas eliminar esta tarea? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              await _commitmentService.deleteCommitment(commitment.id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('🗑️ Compromiso eliminado.'), backgroundColor: Colors.redAccent),
                );
              }
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}