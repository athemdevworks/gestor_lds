import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gestor_lds/features/budget/models/budget_model.dart';
import 'package:gestor_lds/features/budget/services/budget_pdf_service.dart';
import 'package:printing/printing.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ExpenseRequestFormScreen extends StatefulWidget {
  // 👇 1. EL BUZÓN: Recibe los datos si venimos de "Editar"
  final ExpenseRequestModel? requestToEdit;

  const ExpenseRequestFormScreen({super.key, this.requestToEdit});

  @override
  State<ExpenseRequestFormScreen> createState() => _ExpenseRequestFormScreenState();
}

class _ExpenseRequestFormScreenState extends State<ExpenseRequestFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  // 1. TIPO Y PERSONAS
  bool _isReimbursement = true;
  final _applicantController = TextEditingController();
  final _beneficiaryController = TextEditingController();
  final _addressController = TextEditingController();
  final _reasonController = TextEditingController();

  // 2. DETALLE DE GASTOS
  List<ExpenseItem> _items = [];

  final _categoryController = TextEditingController();
  final _amountController = TextEditingController();
  DateTime _itemDate = DateTime.now();

  final List<String> _categories = [
    'Ofrenda de Ayuno: Gastos Comida',
    'Ofrenda de Ayuno: Gastos Alojamiento',
    'Ofrenda de Ayuno: Gastos Médicos',
    'Ofrenda de Ayuno: Agua, Gas, Electricidad',
    'Ofrenda de Ayuno: Otros Gastos',
    'Administración',
    'Administración: Presupuesto',
    'Asignación de Presupuesto',
    'Biblioteca',
    'Centro de Distribución',
    'Currículo',
    'Misceláneo',
    'Adultos Solteros',
    'Adultos Solteros: JAS',
    'Escuela Dominical',
    'Grupo Sumos Sacerdotes',
    'Hombres Jóvenes',
    'Mujeres Jóvenes',
    'Sociedad de Socorro',
    'Primaria: General',
    'Primaria: Materiales',
    'Primaria: Refrigerio',
    'Quorum Élderes: General',
    'Quorum Élderes: Obra Misional',
    'Quorum Élderes: Templo e Historia Familiar',
  ];

  // 3. DATOS BANCARIOS
  final _bankNameController = TextEditingController();
  final _accountTypeController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _cciController = TextEditingController();
  final _docIdController = TextEditingController();

  // 👇 2. EL AUTOLLENADO: Si hay datos, los metemos en los campos
  @override
  void initState() {
    super.initState();
    if (widget.requestToEdit != null) {
      final req = widget.requestToEdit!;
      _isReimbursement = req.isReimbursement;
      _applicantController.text = req.applicantName;
      _beneficiaryController.text = req.beneficiaryName;
      _addressController.text = req.beneficiaryAddress;
      _reasonController.text = req.reason;

      // Clonamos la lista de items para poder editarla sin problemas
      _items = req.items.map((e) => ExpenseItem(category: e.category, date: e.date, amount: e.amount)).toList();

      _bankNameController.text = req.bankDetails.bankName;
      _accountTypeController.text = req.bankDetails.accountType;
      _accountNumberController.text = req.bankDetails.accountNumber;
      _cciController.text = req.bankDetails.cci;
      _docIdController.text = req.bankDetails.identityDoc;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // 👇 Título dinámico
        title: Text(widget.requestToEdit == null ? 'Nueva Solicitud' : 'Editar Solicitud'),
        backgroundColor: Colors.green.shade700,
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

              Card(
                color: Colors.green.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Column(
                    children: [
                      Autocomplete<String>(
                        optionsBuilder: (TextEditingValue textEditingValue) {
                          if (textEditingValue.text.isEmpty) return const Iterable<String>.empty();
                          return _categories.where((String option) => option.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                        },
                        onSelected: (String selection) => _categoryController.text = selection,
                        fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                          if (_categoryController.text.isEmpty && controller.text.isNotEmpty) controller.clear();
                          return TextFormField(
                            controller: controller,
                            focusNode: focusNode,
                            onChanged: (val) => _categoryController.text = val,
                            decoration: const InputDecoration(labelText: 'Categoría (Buscar)', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                          );
                        },
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
                          Expanded(child: _buildTextField('Monto S/.', _amountController, isNumber: true, isDense: true, isRequired: false)),
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
                Expanded(child: _buildTextField('Banco', _bankNameController, isRequired: false)),
                const SizedBox(width: 10),
                Expanded(child: _buildTextField('Tipo Cuenta', _accountTypeController, isRequired: false)),
              ]),
              const SizedBox(height: 10),
              _buildTextField('Número de Cuenta', _accountNumberController, isNumber: true, isRequired: false),
              const SizedBox(height: 10),
              _buildTextField('CCI (Interbancario)', _cciController, isNumber: true, isRequired: false),
              const SizedBox(height: 10),
              _buildTextField('DNI / RUC Titular', _docIdController, isNumber: true, isRequired: false),

              const SizedBox(height: 30),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _saveRequest,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700, foregroundColor: Colors.white),
                  // 👇 Botón dinámico
                  child: Text(widget.requestToEdit == null ? 'GUARDAR Y GENERAR PDF' : 'ACTUALIZAR Y GENERAR PDF', style: const TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(children: [Icon(icon, color: Colors.grey[700]), const SizedBox(width: 8), Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey[800]))]);
  }

  Widget _buildTextField(String label, TextEditingController controller, {IconData? icon, bool isNumber = false, int maxLines = 1, bool isDense = false, bool isRequired = true}) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
      maxLines: maxLines,
      validator: (val) => (isRequired && (val == null || val.isEmpty)) ? 'Requerido' : null,
      decoration: InputDecoration(
        labelText: label, prefixIcon: icon != null ? Icon(icon, size: 20) : null,
        border: const OutlineInputBorder(), contentPadding: isDense ? const EdgeInsets.symmetric(horizontal: 10, vertical: 8) : null,
      ),
    );
  }

  void _addItem() {
    if (_categoryController.text.isEmpty || _amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ingresa categoría y monto')));
      return;
    }
    setState(() {
      _items.add(ExpenseItem(category: _categoryController.text, date: _itemDate, amount: double.tryParse(_amountController.text) ?? 0));
      _amountController.clear();
      _categoryController.clear();
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
      final user = FirebaseAuth.instance.currentUser;
      final uid = user?.uid ?? 'unknown_user';

      // 👇 3. EL CEREBRO: Mapa base de datos que sí cambian
      final requestData = {
        'isReimbursement': _isReimbursement,
        'applicantName': _applicantController.text.trim(),
        'beneficiaryName': _beneficiaryController.text.trim(),
        'beneficiaryAddress': _addressController.text.trim(),
        'reason': _reasonController.text.trim(),
        'items': _items.map((item) => {
          'category': item.category,
          'date': Timestamp.fromDate(item.date),
          'amount': item.amount,
        }).toList(),
        'bankDetails': {
          'bankName': _bankNameController.text.trim(),
          'accountType': _accountTypeController.text.trim(),
          'accountNumber': _accountNumberController.text.trim(),
          'cci': _cciController.text.trim(),
          'identityDoc': _docIdController.text.trim(),
        }
      };

      // Si es NUEVO, le agregamos los datos de creación inicial
      if (widget.requestToEdit == null) {
        requestData['requestDate'] = Timestamp.now();
        requestData['status'] = 'pendiente';
        requestData['requestedByUid'] = uid;

        await FirebaseFirestore.instance.collection('expense_requests').add(requestData);
      } else {
        // Si es EDICIÓN, solo actualizamos los campos (sin borrar la fecha original ni el estado)
        await FirebaseFirestore.instance.collection('expense_requests')
            .doc(widget.requestToEdit!.id)
            .update(requestData);
      }

      if (mounted) {
        // Respetamos la fecha original para el PDF si estamos editando
        final pdfDate = widget.requestToEdit?.requestDate ?? DateTime.now();

        final requestForPdf = ExpenseRequestModel(
            id: widget.requestToEdit?.id ?? 'temp',
            isReimbursement: _isReimbursement,
            applicantName: _applicantController.text.trim(),
            beneficiaryName: _beneficiaryController.text.trim(),
            beneficiaryAddress: _addressController.text.trim(),
            reason: _reasonController.text.trim(),
            items: _items,
            requestDate: pdfDate,
            bankDetails: BankDetails(
              bankName: _bankNameController.text.trim(),
              accountType: _accountTypeController.text.trim(),
              accountNumber: _accountNumberController.text.trim(),
              cci: _cciController.text.trim(),
              identityDoc: _docIdController.text.trim(),
            )
        );

        final pdfData = await BudgetPdfService().generateExpenseRequestPdf(requestForPdf);
        final dateStr = DateFormat('dd-MM-yyyy').format(pdfDate);

        await Printing.layoutPdf(
            onLayout: (_) async => pdfData,
            name: "SG '${requestForPdf.reason}' '$dateStr'.pdf"
        );

        // Mensaje dinámico de éxito
        final successMsg = widget.requestToEdit == null ? '✅ Solicitud guardada y PDF generado' : '✅ Solicitud actualizada y PDF generado';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(successMsg), backgroundColor: Colors.green));

        Navigator.pop(context);
      }
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if(mounted) setState(() => _isSaving = false);
    }
  }
}