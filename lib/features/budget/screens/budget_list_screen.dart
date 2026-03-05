import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:gestor_lds/features/budget/models/budget_model.dart';
import 'package:gestor_lds/features/budget/screens/activity_budget_form_screen.dart';
import 'package:gestor_lds/features/budget/services/budget_pdf_service.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';

import 'expense_request_form_screen.dart';

// 👇 CAMBIO 1: Convertido a StatefulWidget para usar TabBar
class BudgetListScreen extends StatefulWidget {
  const BudgetListScreen({super.key});

  @override
  State<BudgetListScreen> createState() => _BudgetListScreenState();
}

class _BudgetListScreenState extends State<BudgetListScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final brandColor = const Color(0xFF164772);

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Finanzas'),
        backgroundColor: brandColor,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: Colors.orange,
          tabs: const [
            Tab(text: 'PRESUPUESTOS', icon: Icon(Icons.event_note)),
            Tab(text: 'SOLICITUDES', icon: Icon(Icons.receipt_long)),
          ],
        ),
      ),
      // 👇 CAMBIO 2: TabBarView con los dos streams separados
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildBudgetsTab(),
          _buildRequestsTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateOptions(context),
        backgroundColor: brandColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('NUEVO', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  // ==========================================
  // PESTAÑA 1: HOJAS DE PRESUPUESTO
  // ==========================================
  Widget _buildBudgetsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('activity_budgets')
          .orderBy('activityDate', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) return _buildEmptyState('No hay presupuestos registrados');

        return ListView.builder(
          padding: const EdgeInsets.only(top: 10, left: 10, right: 10, bottom: 80),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final budget = ActivityBudgetModel.fromMap(data, docs[index].id);
            return _buildBudgetCard(context, budget);
          },
        );
      },
    );
  }

  Widget _buildBudgetCard(BuildContext context, ActivityBudgetModel budget) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.indigo.shade50,
          child: const Icon(Icons.event_note, color: Color(0xFF164772)),
        ),
        title: Text(budget.activityName, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${budget.organization} • ${DateFormat('dd/MM/yyyy').format(budget.activityDate)}'),
            Text('S/. ${budget.totalBudget.toStringAsFixed(2)}', style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.bold)),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.picture_as_pdf, color: Colors.red),
              onPressed: () => _reprintPdf(budget),
              tooltip: 'Ver PDF',
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') {
                  // 👇 CORRECCIÓN 1: Habilitada la navegación para editar
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ActivityBudgetFormScreen(budgetToEdit: budget),
                        settings: const RouteSettings(name: '/budget-edit'),
                      )
                  );
                } else if (value == 'delete') {
                  _confirmDelete('activity_budgets', budget.id);
                }
              },
              itemBuilder: (BuildContext context) => [
                const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, color: Colors.blue, size: 20), SizedBox(width: 8), Text('Editar')])),
                const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, color: Colors.red, size: 20), SizedBox(width: 8), Text('Eliminar')])),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // PESTAÑA 2: SOLICITUDES DE GASTOS
  // ==========================================
  Widget _buildRequestsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('expense_requests')
          .orderBy('requestDate', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) return _buildEmptyState('No hay solicitudes de gastos');

        return ListView.builder(
          padding: const EdgeInsets.only(top: 10, left: 10, right: 10, bottom: 80),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final docId = docs[index].id;

            // 1. EXTRAEMOS LOS DATOS BÁSICOS PARA LA TARJETA
            final isReimbursement = data['isReimbursement'] ?? true;
            final applicant = data['applicantName'] ?? 'Sin nombre';
            final reason = data['reason'] ?? 'Sin detalle';
            final status = data['status'] ?? 'pendiente';

            double total = 0;
            if (data['items'] != null) {
              for (var item in (data['items'] as List)) {
                total += (item['amount'] ?? 0).toDouble();
              }
            }

            // 2. ARMAMOS EL OBJETO COMPLETO (Lo sacamos del botón PDF para usarlo en ambos lados)
            final request = ExpenseRequestModel(
              id: docId,
              isReimbursement: isReimbursement,
              applicantName: applicant,
              beneficiaryName: data['beneficiaryName'] ?? '',
              beneficiaryAddress: data['beneficiaryAddress'] ?? '',
              reason: reason,
              items: (data['items'] as List<dynamic>? ?? []).map((item) {
                return ExpenseItem(
                  category: item['category'] ?? 'General',
                  date: (item['date'] as Timestamp).toDate(),
                  amount: (item['amount'] ?? 0).toDouble(),
                );
              }).toList(),
              requestDate: (data['requestDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
              bankDetails: BankDetails(
                bankName: data['bankDetails']?['bankName'] ?? '',
                accountType: data['bankDetails']?['accountType'] ?? '',
                accountNumber: data['bankDetails']?['accountNumber'] ?? '',
                cci: data['bankDetails']?['cci'] ?? '',
                identityDoc: data['bankDetails']?['identityDoc'] ?? '',
              ),
            );

            // 3. CONSTRUIMOS LA TARJETA UI
            return Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 10),
              shape: Border(left: BorderSide(color: isReimbursement ? Colors.blue : Colors.orange, width: 5)),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: status == 'aprobado' ? Colors.green.shade100 : Colors.orange.shade100,
                  child: Icon(
                      status == 'aprobado' ? Icons.check_circle : Icons.hourglass_empty,
                      color: status == 'aprobado' ? Colors.green.shade700 : Colors.orange.shade700
                  ),
                ),
                title: Text(applicant, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(reason, maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text('S/. ${total.toStringAsFixed(2)} - ${isReimbursement ? 'Reembolso' : 'Adelanto'}',
                        style: TextStyle(color: Colors.green.shade800, fontWeight: FontWeight.bold)
                    ),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // BOTÓN DE PDF (Ahora usa la variable 'request' de arriba)
                    IconButton(
                      icon: const Icon(Icons.picture_as_pdf, color: Colors.red),
                      onPressed: () async {
                        final pdfData = await BudgetPdfService().generateExpenseRequestPdf(request);
                        final dateStr = DateFormat('dd-MM-yyyy').format(request.requestDate);
                        await Printing.layoutPdf(
                          onLayout: (PdfPageFormat format) async => pdfData,
                          name: "SG '${request.reason}' '$dateStr'.pdf",
                        );
                      },
                      tooltip: 'Ver PDF',
                    ),

                    // BOTÓN DE OPCIONES (Editar / Eliminar)
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'edit') {
                          // 👇 MAGIA APLICADA: Mandamos el objeto 'request' al formulario
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ExpenseRequestFormScreen(requestToEdit: request),
                                settings: const RouteSettings(name: '/expense-edit'),
                              )
                          );
                        } else if (value == 'delete') {
                          _confirmDelete('expense_requests', docId);
                        }
                      },
                      itemBuilder: (BuildContext context) => [
                        const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, color: Colors.blue, size: 20), SizedBox(width: 8), Text('Editar')])),
                        const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, color: Colors.red, size: 20), SizedBox(width: 8), Text('Eliminar')])),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ==========================================
  // FUNCIONES AUXILIARES Y LÓGICA
  // ==========================================

  Future<void> _reprintPdf(ActivityBudgetModel budget) async {
    final pdfData = await BudgetPdfService().generateActivityBudgetPdf(budget);
    // 👇 CORRECCIÓN 2: Regla de oro para el nombre del PDF de Presupuestos (HP)
    final dateStr = DateFormat('dd-MM-yyyy').format(budget.activityDate);

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfData,
      name: "HP '${budget.activityName}' '$dateStr'.pdf",
    );
  }

  void _confirmDelete(String collection, String docId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar Eliminación'),
        content: const Text('¿Estás seguro de que deseas eliminar este registro permanentemente?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              await FirebaseFirestore.instance.collection(collection).doc(docId).delete();
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Registro eliminado')));
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.account_balance_wallet_outlined, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 20),
          Text(message, style: TextStyle(fontSize: 18, color: Colors.grey.shade600)),
          const SizedBox(height: 10),
          const Text('Presiona "NUEVO" para comenzar', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  void _showCreateOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.only(bottom: 15),
                child: Text('¿Qué deseas hacer?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              ListTile(
                leading: CircleAvatar(backgroundColor: Colors.indigo.shade50, child: const Icon(Icons.event_note, color: Colors.indigo)),
                title: const Text('Hoja de Presupuesto'),
                subtitle: const Text('Planificación de actividad'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ActivityBudgetFormScreen(),
                        settings: const RouteSettings(name: '/budget-form'),
                      )
                  );
                },
              ),
              const Divider(),
              ListTile(
                leading: CircleAvatar(backgroundColor: Colors.green.shade50, child: Icon(Icons.attach_money, color: Colors.green.shade700)),
                title: const Text('Formulario de Solicitud de Gastos'),
                subtitle: const Text('Solicitar Reembolso / Adelanto'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ExpenseRequestFormScreen(),
                        settings: const RouteSettings(name: '/expense-form'),
                      )
                  );
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }
}