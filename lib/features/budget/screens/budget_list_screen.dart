import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:gestor_lds/features/budget/models/budget_model.dart';
import 'package:gestor_lds/features/budget/screens/activity_budget_form_screen.dart';
import 'package:gestor_lds/features/budget/services/budget_pdf_service.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';

import 'expense_request_form_screen.dart';

class BudgetListScreen extends StatelessWidget {
  const BudgetListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final brandColor = const Color(0xFF164772);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Presupuestos'),
        backgroundColor: brandColor,
        foregroundColor: Colors.white,
      ),
      // AQUÍ ESTÁ LA MAGIA: StreamBuilder escucha cambios en vivo
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('activity_budgets')
            .orderBy('activityDate', descending: true) // Ordenar por fecha
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              // Convertimos el documento a nuestro Modelo
              final data = docs[index].data() as Map<String, dynamic>;
              final budget = ActivityBudgetModel.fromMap(data, docs[index].id);

              return _buildBudgetCard(context, budget);
            },
          );
        },
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateOptions(context),
        backgroundColor: brandColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('NUEVO', style: TextStyle(color: Colors.white)),
      ),
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
        title: Text(
          budget.activityName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
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
        trailing: IconButton(
          icon: const Icon(Icons.picture_as_pdf, color: Colors.red),
          onPressed: () => _reprintPdf(context, budget),
          tooltip: 'Ver PDF',
        ),
        onTap: () {
          // Opcional: Aquí podrías abrir el formulario para editar
          // Por ahora solo mostramos detalle o reimprimimos
          _reprintPdf(context, budget);
        },
      ),
    );
  }

  Future<void> _reprintPdf(BuildContext context, ActivityBudgetModel budget) async {
    // Reutilizamos el servicio para generar el PDF al vuelo
    final pdfData = await BudgetPdfService().generateActivityBudgetPdf(budget);

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfData,
      name: 'Presupuesto-${budget.activityName}.pdf',
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.account_balance_wallet_outlined, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 20),
          Text(
            'No hay presupuestos registrados',
            style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 10),
          const Text(
            'Presiona "NUEVO" para comenzar',
            style: TextStyle(color: Colors.grey),
          ),
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
                        // 👇 AGREGADO: Ruta web para Formulario de Presupuesto
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
                        // 👇 AGREGADO: Ruta web para Formulario de Gastos
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