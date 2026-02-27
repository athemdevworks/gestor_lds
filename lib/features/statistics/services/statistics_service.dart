import 'package:cloud_firestore/cloud_firestore.dart';

class StatisticsService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // 1. ANILLO: ESTADO DE COMPROMISOS (Ya funciona)
  Future<Map<String, int>> getCommitmentsStats() async {
    int completed = 0;
    int pending = 0;
    try {
      final snapshot = await _db.collection('commitments').get();
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final isCompleted = data['isCompleted'] ?? false;
        if (isCompleted) {
          completed++;
        } else {
          pending++;
        }
      }
      return {'completed': completed, 'pending': pending};
    } catch (e) {
      print("Error obteniendo compromisos: $e");
      return {'completed': 0, 'pending': 0};
    }
  }

  // 2. BARRAS: GASTOS (Reembolsos vs Adelantos)
  // Como no hay un "presupuesto asignado global" en la BD, compararemos
  // cuánto dinero ha salido por reembolsos vs cuánto por adelantos.
  Future<Map<String, double>> getBudgetStats() async {
    double totalReimbursements = 0; // Reembolsos
    double totalAdvances = 0;       // Adelantos
    try {
      // Asumo que tu colección de solicitudes de gastos se llama 'expense_requests'
      final snapshot = await _db.collection('expense_requests').get();
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final isReimbursement = data['isReimbursement'] ?? true;

        // Sumamos los montos de la lista de items
        double requestTotal = 0;
        if (data['items'] != null) {
          for (var item in data['items']) {
            requestTotal += (item['amount'] ?? 0).toDouble();
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
      print("Error en presupuesto: $e");
      return {'reimbursements': 0, 'advances': 0};
    }
  }

  // 3. MEDIDOR: ENTREVISTAS DEL MES ACTUAL
  Future<Map<String, int>> getInterviewStats() async {
    int reserved = 0;
    int available = 0;
    try {
      final now = DateTime.now();
      final firstDayOfMonth = DateTime(now.year, now.month, 1);

      final snapshot = await _db.collection('interview_slots')
          .where('startTime', isGreaterThanOrEqualTo: Timestamp.fromDate(firstDayOfMonth))
          .get();

      for (var doc in snapshot.docs) {
        if (doc.data()['isReserved'] == true) {
          reserved++;
        } else {
          available++;
        }
      }
      return {'reserved': reserved, 'available': available};
    } catch (e) {
      print("Error en entrevistas: $e");
      return {'reserved': 0, 'available': 0};
    }
  }

  // 4. ALERTA: FOCOS ROJOS (Compromisos atrasados más de 3 días)
  Future<List<Map<String, dynamic>>> getOverdueCommitments() async {
    List<Map<String, dynamic>> overdueList = [];
    try {
      final snapshot = await _db.collection('commitments')
          .where('isCompleted', isEqualTo: false)
          .get();

      final now = DateTime.now();

      for (var doc in snapshot.docs) {
        final data = doc.data();
        if (data['dueDate'] != null) {
          final dueDate = (data['dueDate'] as Timestamp).toDate();

          // Si la fecha límite ya pasó (es antes de hoy)...
          if (dueDate.isBefore(now)) {
            overdueList.add({
              'description': data['description'] ?? 'Tarea sin nombre',
              'responsible': data['responsibleName'] ?? 'Alguien',
              'daysLate': now.difference(dueDate).inDays,
              'topic': data['agendaItemTopic'] ?? 'General',
            });
          }
        }
      }
      // Ordenar: Los más atrasados primero (mayor cantidad de días tarde)
      overdueList.sort((a, b) => b['daysLate'].compareTo(a['daysLate']));
      return overdueList;
    } catch (e) {
      print("Error en Focos Rojos: $e");
      return [];
    }
  }
}