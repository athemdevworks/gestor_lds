import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

import 'package:gestor_lds/features/auth/models/user_model.dart';
import 'package:gestor_lds/features/budget/models/budget_model.dart';
import 'package:gestor_lds/features/budget/screens/activity_budget_form_screen.dart';
import 'package:gestor_lds/features/budget/screens/expense_request_form_screen.dart';
import 'package:gestor_lds/features/budget/services/budget_pdf_service.dart';

class BudgetListScreen extends StatefulWidget {
  final UserModel currentUser;

  const BudgetListScreen({super.key, required this.currentUser});

  @override
  State<BudgetListScreen> createState() => _BudgetListScreenState();
}

class _BudgetListScreenState extends State<BudgetListScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final brandColor = const Color(0xFF22539A);

  // 🛡️ Permisos para líderes financieros / obispado
  bool get _isFinancialLeader {
    final role = widget.currentUser.role;
    if (role == UserRole.admin ||
        role == UserRole.obispado ||
        role == UserRole.presidencia_estaca) {
      return true;
    }

    return widget.currentUser.callings?.any((c) {
      final cLower = c.toLowerCase();
      return cLower.contains('secretario') ||
          cLower.contains('financiero') ||
          cLower.contains('obispo');
    }) ??
        false;
  }

  // Nivel global (Estaca o Administrador)
  bool get _isGlobalScope =>
      widget.currentUser.role == UserRole.admin ||
          widget.currentUser.role == UserRole.presidencia_estaca;

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
        title: const Text('Gestión de Finanzas', style: TextStyle(fontWeight: FontWeight.bold)),
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
  // PESTAÑA 1: HOJAS DE PRESUPUESTO (ACTIVIDAD)
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

        final allDocs = snapshot.data?.docs ?? [];

        // Filtro por unidad
        final filteredDocs = allDocs.where((doc) {
          if (_isGlobalScope) return true;
          final data = doc.data() as Map<String, dynamic>;
          final ward = data['ward'] ?? '';
          return ward.isEmpty || ward == widget.currentUser.ward || ward.toLowerCase() == 'estaca';
        }).toList();

        if (filteredDocs.isEmpty) return _buildEmptyState('No hay presupuestos registrados para tu unidad.');

        return ListView.builder(
          padding: const EdgeInsets.only(top: 10, left: 10, right: 10, bottom: 80),
          itemCount: filteredDocs.length,
          itemBuilder: (context, index) {
            final data = filteredDocs[index].data() as Map<String, dynamic>;
            final budget = ActivityBudgetModel.fromMap(data, filteredDocs[index].id);
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
          child: const Icon(Icons.event_note, color: Color(0xFF22539A)),
        ),
        title: Text(budget.activityName, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${budget.organization} • ${DateFormat('dd/MM/yyyy').format(budget.activityDate)}'),
            Text(
              'S/. ${budget.totalBudget.toStringAsFixed(2)}',
              style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.bold),
            ),
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
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ActivityBudgetFormScreen(
                        budgetToEdit: budget,
                        currentUser: widget.currentUser,
                      ),
                      settings: const RouteSettings(name: '/budget-edit'),
                    ),
                  );
                } else if (value == 'delete') {
                  _confirmDelete('activity_budgets', budget.id);
                }
              },
              itemBuilder: (BuildContext context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(children: [Icon(Icons.edit, color: Colors.blue, size: 20), SizedBox(width: 8), Text('Editar')]),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(children: [Icon(Icons.delete, color: Colors.red, size: 20), SizedBox(width: 8), Text('Eliminar')]),
                ),
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

        final allDocs = snapshot.data?.docs ?? [];

        // 🛡️ Filtro de privacidad y unidad
        final filteredDocs = allDocs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final docWard = data['ward'] ?? '';
          final requestedByUid = data['requestedByUid'] ?? '';

          // Si es líder financiero: ve las de su barrio (o todas si es global)
          if (_isFinancialLeader) {
            if (_isGlobalScope) return true;
            return docWard.isEmpty || docWard == widget.currentUser.ward;
          }

          // Si es miembro u organización general: solo ve sus trámites propios
          return requestedByUid == widget.currentUser.uid;
        }).toList();

        if (filteredDocs.isEmpty) {
          return _buildEmptyState(
            _isFinancialLeader
                ? 'No hay solicitudes de gastos en tu unidad.'
                : 'No tienes solicitudes de gastos registradas.',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.only(top: 10, left: 10, right: 10, bottom: 80),
          itemCount: filteredDocs.length,
          itemBuilder: (context, index) {
            final data = filteredDocs[index].data() as Map<String, dynamic>;
            final request = ExpenseRequestModel.fromMap(data, filteredDocs[index].id);
            return _buildRequestCard(context, request);
          },
        );
      },
    );
  }

  Widget _buildRequestCard(BuildContext context, ExpenseRequestModel request) {
    final bool isApproved = request.status.toLowerCase() == 'aprobado';
    final bool canEditOrDelete = _isFinancialLeader || request.requestedByUid == widget.currentUser.uid;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 10),
      shape: Border(
        left: BorderSide(
          color: request.isReimbursement ? Colors.blue : Colors.orange,
          width: 5,
        ),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isApproved ? Colors.green.shade100 : Colors.orange.shade100,
          child: Icon(
            isApproved ? Icons.check_circle : Icons.hourglass_empty,
            color: isApproved ? Colors.green.shade700 : Colors.orange.shade700,
          ),
        ),
        title: Text(request.applicantName, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(request.reason, maxLines: 1, overflow: TextOverflow.ellipsis),
            Text(
              'S/. ${request.totalAmount.toStringAsFixed(2)} - ${request.isReimbursement ? 'Reembolso' : 'Adelanto'}',
              style: TextStyle(color: Colors.green.shade800, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
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
            if (canEditOrDelete)
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ExpenseRequestFormScreen(
                          requestToEdit: request,
                          currentUser: widget.currentUser,
                        ),
                        settings: const RouteSettings(name: '/expense-edit'),
                      ),
                    );
                  } else if (value == 'delete') {
                    _confirmDelete('expense_requests', request.id);
                  }
                },
                itemBuilder: (BuildContext context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(children: [Icon(Icons.edit, color: Colors.blue, size: 20), SizedBox(width: 8), Text('Editar')]),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(children: [Icon(Icons.delete, color: Colors.red, size: 20), SizedBox(width: 8), Text('Eliminar')]),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // FUNCIONES AUXILIARES Y NAVEGACIÓN
  // ==========================================

  Future<void> _reprintPdf(ActivityBudgetModel budget) async {
    final pdfData = await BudgetPdfService().generateActivityBudgetPdf(budget);
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
          Text(message, style: TextStyle(fontSize: 16, color: Colors.grey.shade600), textAlign: TextAlign.center),
          const SizedBox(height: 10),
          const Text('Presiona "NUEVO" para registrar un movimiento', style: TextStyle(color: Colors.grey)),
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
                child: Text('¿Qué deseas registrar?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.indigo.shade50,
                  child: const Icon(Icons.event_note, color: Colors.indigo),
                ),
                title: const Text('Hoja de Presupuesto'),
                subtitle: const Text('Planificación logística y financiera de una actividad'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ActivityBudgetFormScreen(currentUser: widget.currentUser),
                      settings: const RouteSettings(name: '/budget-form'),
                    ),
                  );
                },
              ),
              const Divider(),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.green.shade50,
                  child: Icon(Icons.attach_money, color: Colors.green.shade700),
                ),
                title: const Text('Solicitud de Gastos'),
                subtitle: const Text('Solicitar Reembolso o Adelanto con datos bancarios'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ExpenseRequestFormScreen(currentUser: widget.currentUser),
                      settings: const RouteSettings(name: '/expense-form'),
                    ),
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