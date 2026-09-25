import 'package:cloud_firestore/cloud_firestore.dart';

class StatisticsService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // 1. ESTADO DE COMPROMISOS (Resumen de Tareas)
  Future<Map<String, int>> getCommitmentsStats({String ward = 'Todos'}) async {
    int completed = 0;
    int pending = 0;
    try {
      Query query = _db.collection('commitments');
      if (ward != 'Todos') {
        query = query.where('ward', isEqualTo: ward);
      }

      final snapshot = await query.get();
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        if (data['isCompleted'] == true) {
          completed++;
        } else {
          pending++;
        }
      }
      return {'completed': completed, 'pending': pending};
    } catch (e) {
      return {'completed': 0, 'pending': 0};
    }
  }

  // 2. GASTOS (Reembolsos vs Adelantos)
  Future<Map<String, double>> getBudgetStats({String ward = 'Todos'}) async {
    double totalReimbursements = 0.0;
    double totalAdvances = 0.0;
    try {
      Query query = _db.collection('expense_requests');
      if (ward != 'Todos') {
        query = query.where('ward', isEqualTo: ward);
      }

      final snapshot = await query.get();
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final isReimbursement = data['isReimbursement'] ?? true;

        double requestTotal = 0.0;
        if (data['items'] != null && data['items'] is List) {
          for (var item in data['items']) {
            final amount = item['amount'];
            if (amount is num) {
              requestTotal += amount.toDouble();
            }
          }
        }

        if (isReimbursement) {
          totalReimbursements += requestTotal;
        } else {
          totalAdvances += requestTotal;
        }
      }
      return {'reimbursements': totalReimbursements, 'advances': totalAdvances};
    } catch (e) {
      return {'reimbursements': 0.0, 'advances': 0.0};
    }
  }

  // 3. ENTREVISTAS DEL MES ACTUAL (Rango estricto sin colisiones de índice)
  Future<Map<String, int>> getInterviewStats({String ward = 'Todos'}) async {
    int reserved = 0;
    int available = 0;
    try {
      final now = DateTime.now();
      final firstDayOfMonth = DateTime(now.year, now.month, 1);
      final firstDayOfNextMonth = (now.month < 12)
          ? DateTime(now.year, now.month + 1, 1)
          : DateTime(now.year + 1, 1, 1);

      // Consulta acotada solo a las citas del mes calendario en curso
      final snapshot = await _db
          .collection('interview_slots')
          .where('startTime', isGreaterThanOrEqualTo: Timestamp.fromDate(firstDayOfMonth))
          .where('startTime', isLessThan: Timestamp.fromDate(firstDayOfNextMonth))
          .get();

      for (var doc in snapshot.docs) {
        final data = doc.data();
        // Segregación segura en memoria para evitar requerir índices compuestos en Firebase
        if (ward != 'Todos' && data['ward'] != ward) continue;

        if (data['isReserved'] == true) {
          reserved++;
        } else {
          available++;
        }
      }
      return {'reserved': reserved, 'available': available};
    } catch (e) {
      return {'reserved': 0, 'available': 0};
    }
  }

  // 4. FOCOS ROJOS: COMPROMISOS VENCIDOS
  Future<List<Map<String, dynamic>>> getOverdueCommitments({String ward = 'Todos'}) async {
    List<Map<String, dynamic>> overdueList = [];
    try {
      final snapshot = await _db
          .collection('commitments')
          .where('isCompleted', isEqualTo: false)
          .get();

      final now = DateTime.now();

      for (var doc in snapshot.docs) {
        final data = doc.data();
        if (ward != 'Todos' && data['ward'] != ward) continue;

        if (data['dueDate'] != null && data['dueDate'] is Timestamp) {
          final dueDate = (data['dueDate'] as Timestamp).toDate();

          if (dueDate.isBefore(now)) {
            overdueList.add({
              'description': data['description'] ?? 'Tarea sin descripción',
              'responsible': data['responsibleName'] ?? 'Sin asignar',
              'daysLate': now.difference(dueDate).inDays,
              'topic': data['agendaItemTopic'] ?? 'General',
            });
          }
        }
      }
      overdueList.sort((a, b) => (b['daysLate'] as int).compareTo(a['daysLate'] as int));
      return overdueList;
    } catch (e) {
      return [];
    }
  }
}