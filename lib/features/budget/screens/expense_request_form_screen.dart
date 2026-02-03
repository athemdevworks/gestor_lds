import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gestor_lds/features/budget/models/budget_model.dart';
import 'package:gestor_lds/features/budget/services/budget_pdf_service.dart';
import 'package:printing/printing.dart';

class ExpenseRequestFormScreen extends StatefulWidget {
  const ExpenseRequestFormScreen({super.key});

  @override
  State<ExpenseRequestFormScreen> createState() => _ExpenseRequestFormScreenState();
}

class _ExpenseRequestFormScreenState extends State<ExpenseRequestFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  // 1. TIPO Y PERSONAS
  bool _isReimbursement = true; // true = Reembolso, false = Adelanto
  final _applicantController = TextEditingController();
  final _beneficiaryController = TextEditingController(); // Pagar a
  final _addressController = TextEditingController();
  final _reasonController = TextEditingController();

  // 2. DETALLE DE GASTOS (Lista Dinámica)
  List<ExpenseItem> _items = [];

  // Controladores temporales para agregar item
  String? _selectedCategory;
  final _amountController = TextEditingController();
  DateTime _itemDate = DateTime.now();

  final List<String> _categories = [
    'Administración', 'Quórum de Élderes', 'Sociedad de Socorro',
    'Hombres Jóvenes', 'Mujeres Jóvenes', 'Primaria', 'Escuela Dominical',
    'Música', 'Historia Familiar', 'Actividades', 'Otros'
  ];

  // 3. DATOS BANCARIOS
  final _bankNameController = TextEditingController();
  final _accountTypeController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _cciController = TextEditingController();
  final _docIdController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Solicitud de Gastos'),
        backgroundColor: Colors.green.shade700, // Verde para diferenciar dinero
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: _isSaving
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.save),
            onPressed: _isSaving ? null : _saveRequest,
          )
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // TIPO DE SOLICITUD
              Card(
                child: SwitchListTile(
                  title: Text(_isReimbursement ? 'SOLICITUD DE REEMBOLSO' : 'SOLICITUD DE ADELANTO',
                      style: TextStyle(fontWeight: FontWeight.bold, color: _isReimbursement ? Colors.blue : Colors.orange)),
                  subtitle: const Text('¿Ya gastaste el dinero o lo necesitas por adelantado?'),
                  value: _isReimbursement,
                  activeColor: Colors.blue,
                  inactiveThumbColor: Colors.orange,
                  inactiveTrackColor: Colors.orange.shade200,
                  onChanged: (val) => setState(() => _isReimbursement = val),
                ),
              ),
              const SizedBox(height: 15),

              _buildSectionTitle('1. DATOS DEL BENEFICIARIO', Icons.person),
              const SizedBox(height: 10),
              _buildTextField('Solicitante (Tu nombre)', _applicantController, icon: Icons.person_outline),
              const SizedBox(height: 10),
              _buildTextField('PAGAR A (Nombre en la cuenta)', _beneficiaryController, icon: Icons.person),
              const SizedBox(height: 10),
              _buildTextField('Dirección / Barrio', _addressController, icon: Icons.location_on_outlined),
              const SizedBox(height: 10),
              _buildTextField('Propósito General del Gasto', _reasonController, maxLines: 2),

              const SizedBox(height: 25),
              _buildSectionTitle('2. DETALLE DE MONTOS', Icons.monetization_on_outlined),
              const SizedBox(height: 10),

              // CARD PARA AGREGAR ITEM
              Card(
                color: Colors.green.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Column(
                    children: [
                      DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                        onChanged: (val) => setState(() => _selectedCategory = val),
                        decoration: const InputDecoration(labelText: 'Categoría', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final picked = await showDatePicker(context: context, initialDate: _itemDate, firstDate: DateTime(2024), lastDate: DateTime(2030));
                                if (picked != null) setState(() => _itemDate = picked);
                              },
                              child: InputDecorator(
                                decoration: const InputDecoration(labelText: 'Fecha', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                                child: Text(DateFormat('dd/MM/yyyy').format(_itemDate)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildTextField('Monto S/.', _amountController, isNumber: true, isDense: true),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton.icon(
                          onPressed: _addItem,
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Agregar Línea'),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                        ),
                      )
                    ],
                  ),
                ),
              ),

              // LISTA DE ITEMS
              if (_items.isNotEmpty) ...[
                const SizedBox(height: 10),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _items.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final item = _items[index];
                    return ListTile(
                      dense: true,
                      title: Text('${item.category} - ${DateFormat('dd/MM').format(item.date)}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('S/. ${item.amount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          IconButton(icon: const Icon(Icons.delete, color: Colors.red, size: 20), onPressed: () => setState(() => _items.removeAt(index))),
                        ],
                      ),
                    );
                  },
                ),
                const Divider(),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'TOTAL: S/. ${_calculateTotal().toStringAsFixed(2)}',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green.shade800),
                  ),
                ),
              ],

              const SizedBox(height: 25),
              _buildSectionTitle('3. DATOS BANCARIOS (EFT)', Icons.account_balance),
              const Text('Llenar solo si se requiere transferencia.', style: TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 10),

              Row(children: [
                Expanded(child: _buildTextField('Banco', _bankNameController)),
                const SizedBox(width: 10),
                Expanded(child: _buildTextField('Tipo Cuenta', _accountTypeController)),
              ]),
              const SizedBox(height: 10),
              _buildTextField('Número de Cuenta', _accountNumberController, isNumber: true),
              const SizedBox(height: 10),
              _buildTextField('CCI (Interbancario)', _cciController, isNumber: true),
              const SizedBox(height: 10),
              _buildTextField('DNI / RUC Titular', _docIdController, isNumber: true),

              const SizedBox(height: 30),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _saveRequest,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700, foregroundColor: Colors.white),
                  child: const Text('GUARDAR Y GENERAR PDF', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- HELPERS ---
  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(children: [Icon(icon, color: Colors.grey[700]), const SizedBox(width: 8), Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey[800]))]);
  }

  Widget _buildTextField(String label, TextEditingController controller, {IconData? icon, bool isNumber = false, int maxLines = 1, bool isDense = false}) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      maxLines: maxLines,
      validator: (val) => (!isDense && (val == null || val.isEmpty)) ? 'Requerido' : null,
      decoration: InputDecoration(
        labelText: label, prefixIcon: icon != null ? Icon(icon, size: 20) : null,
        border: const OutlineInputBorder(), contentPadding: isDense ? const EdgeInsets.symmetric(horizontal: 10, vertical: 8) : null,
      ),
    );
  }

  // --- LOGICA ---
  void _addItem() {
    if (_selectedCategory == null || _amountController.text.isEmpty) return;
    setState(() {
      _items.add(ExpenseItem(category: _selectedCategory!, date: _itemDate, amount: double.tryParse(_amountController.text) ?? 0));
      _amountController.clear();
    });
  }

  double _calculateTotal() => _items.fold(0, (sum, item) => sum + item.amount);

  Future<void> _saveRequest() async {
    if (!_formKey.currentState!.validate()) return;
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Agrega al menos un monto')));
      return;
    }

    setState(() => _isSaving = true);

    try {
      final request = ExpenseRequestModel(
        id: '',
        isReimbursement: _isReimbursement,
        applicantName: _applicantController.text,
        beneficiaryName: _beneficiaryController.text,
        beneficiaryAddress: _addressController.text,
        reason: _reasonController.text,
        items: _items,
        requestDate: DateTime.now(),
        bankDetails: BankDetails(
          bankName: _bankNameController.text,
          accountType: _accountTypeController.text,
          accountNumber: _accountNumberController.text,
          cci: _cciController.text,
          identityDoc: _docIdController.text,
        ),
      );

      // Guardar en Firestore (Usamos la misma colección 'activity_budgets' o una nueva 'expense_requests')
      // Para orden, recomiendo una colección separada:
      await FirebaseFirestore.instance.collection('expense_requests').add(request.toMap());

      if (mounted) {
        // Generar PDF (Lo implementaremos en el paso 2)
        final pdfData = await BudgetPdfService().generateExpenseRequestPdf(request);
        await Printing.layoutPdf(onLayout: (_) async => pdfData, name: 'Solicitud-${request.applicantName}.pdf');

        Navigator.pop(context);
      }
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if(mounted) setState(() => _isSaving = false);
    }
  }
}