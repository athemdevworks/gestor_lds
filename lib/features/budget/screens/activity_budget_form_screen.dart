import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gestor_lds/features/budget/models/budget_model.dart';
import 'package:gestor_lds/features/auth/models/user_model.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import '../../../core/widgets/hymn_autocomplete.dart';
import '../../activities/models/activity_model.dart';
import '../services/budget_pdf_service.dart';

class ActivityBudgetFormScreen extends StatefulWidget {
  final ActivityModel? fromActivity;
  final ActivityBudgetModel? budgetToEdit;
  final UserModel? currentUser;

  const ActivityBudgetFormScreen({
    super.key,
    this.fromActivity,
    this.budgetToEdit,
    this.currentUser,
  });

  @override
  State<ActivityBudgetFormScreen> createState() => _ActivityBudgetFormScreenState();
}

class _ActivityBudgetFormScreenState extends State<ActivityBudgetFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();

  final _organizationController = TextEditingController();
  final _leaderController = TextEditingController();
  final _activityNameController = TextEditingController();
  final _purposeController = TextEditingController();
  final _applicantController = TextEditingController();

  DateTime? _activityDate;
  DateTime? _presentationDate;

  List<BudgetItem> _expenses = [];
  final _itemDescController = TextEditingController();
  final _itemQtyController = TextEditingController(text: '1');
  final _itemPriceController = TextEditingController();

  final _conductedByController = TextEditingController();
  final _presidedByController = TextEditingController();
  final _openingHymnController = TextEditingController();
  final _openingPrayerController = TextEditingController();
  final _developmentController = TextEditingController();
  final _closingHymnController = TextEditingController();
  final _closingPrayerController = TextEditingController();
  final _cleaningController = TextEditingController();
  final _securityController = TextEditingController();

  bool _isSaving = false;

  final List<String> _organizations = [
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
    'Quorum Élderes: Templo e Historia Familiar'
  ];

  @override
  void initState() {
    super.initState();

    if (widget.budgetToEdit != null) {
      final b = widget.budgetToEdit!;
      _organizationController.text = b.organization;
      _leaderController.text = b.responsibleLeader;
      _activityDate = b.activityDate;
      _presentationDate = b.presentationDate;
      _activityNameController.text = b.activityName;
      _purposeController.text = b.activityPurpose;
      _applicantController.text = b.applicantName;
      _expenses = List.from(b.expenses);
      _conductedByController.text = b.conductedBy;
      _presidedByController.text = b.presidedBy;
      _openingHymnController.text = b.openingHymn;
      _openingPrayerController.text = b.openingPrayer;
      _developmentController.text = b.activityDevelopment;
      _closingHymnController.text = b.closingHymn;
      _closingPrayerController.text = b.closingPrayer;
      _cleaningController.text = b.cleaningTeam;
      _securityController.text = b.securityTeam;
    } else if (widget.fromActivity != null) {
      final act = widget.fromActivity!;
      _activityNameController.text = act.title;
      _purposeController.text = act.description;
      _activityDate = act.date;
      _organizationController.text = act.organization;
      _presentationDate = DateTime.now();
      if (widget.currentUser != null) {
        _applicantController.text = "${widget.currentUser!.firstName} ${widget.currentUser!.lastName}".trim();
      }
    } else if (widget.currentUser != null) {
      _applicantController.text = "${widget.currentUser!.firstName} ${widget.currentUser!.lastName}".trim();
      _presentationDate = DateTime.now();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _organizationController.dispose();
    _leaderController.dispose();
    _activityNameController.dispose();
    _purposeController.dispose();
    _applicantController.dispose();
    _itemDescController.dispose();
    _itemQtyController.dispose();
    _itemPriceController.dispose();
    _conductedByController.dispose();
    _presidedByController.dispose();
    _openingHymnController.dispose();
    _openingPrayerController.dispose();
    _developmentController.dispose();
    _closingHymnController.dispose();
    _closingPrayerController.dispose();
    _cleaningController.dispose();
    _securityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.budgetToEdit == null ? 'Hoja de Presupuesto' : 'Editar Presupuesto'),
        backgroundColor: const Color(0xFF22539A),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: _isSaving
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.save),
            onPressed: _isSaving ? null : _saveBudget,
          )
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSectionTitle('1. DATOS GENERALES', Icons.info_outline),
              const SizedBox(height: 10),

              Autocomplete<String>(
                optionsBuilder: (TextEditingValue textEditingValue) {
                  if (textEditingValue.text.isEmpty) return const Iterable<String>.empty();
                  return _organizations.where((String option) {
                    return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
                  });
                },
                onSelected: (String selection) {
                  _organizationController.text = selection;
                },
                fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                  if (_organizationController.text.isNotEmpty && controller.text.isEmpty) {
                    controller.text = _organizationController.text;
                  }

                  return TextFormField(
                    controller: controller,
                    focusNode: focusNode,
                    onChanged: (val) => _organizationController.text = val,
                    validator: (value) => (value == null || value.isEmpty) ? 'Requerido' : null,
                    decoration: const InputDecoration(
                      labelText: 'Organización (Escriba para buscar)',
                      prefixIcon: Icon(Icons.group, size: 20),
                      border: OutlineInputBorder(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 10),
              _buildTextField('Líder Responsable', _leaderController, icon: Icons.person),
              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(child: _buildDatePicker('Fecha Actividad', _activityDate, (d) => setState(() => _activityDate = d))),
                  const SizedBox(width: 10),
                  Expanded(child: _buildDatePicker('Fecha Presentación', _presentationDate, (d) => setState(() => _presentationDate = d))),
                ],
              ),
              const SizedBox(height: 10),

              _buildTextField('Nombre Actividad', _activityNameController, icon: Icons.local_activity),
              const SizedBox(height: 10),
              _buildTextField('Propósito', _purposeController, maxLines: 2),
              const SizedBox(height: 10),
              _buildTextField('Solicitante', _applicantController, icon: Icons.person_outline),

              const SizedBox(height: 25),
              _buildSectionTitle('2. DESGLOSE DE GASTOS', Icons.monetization_on),
              const SizedBox(height: 10),

              Card(
                color: Colors.grey.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(flex: 3, child: _buildTextField('Descripción', _itemDescController, isDense: true)),
                          const SizedBox(width: 5),
                          Expanded(flex: 1, child: _buildTextField('Cant.', _itemQtyController, isNumber: true, isDense: true)),
                          const SizedBox(width: 5),
                          Expanded(flex: 2, child: _buildTextField('Precio Unit.', _itemPriceController, isNumber: true, isDense: true)),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton.icon(
                          onPressed: _addExpenseItem,
                          icon: const Icon(Icons.add_shopping_cart, size: 16),
                          label: const Text('Agregar Gasto'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade600,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              if (_expenses.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(15.0),
                  child: Center(child: Text('No hay gastos agregados aún.', style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey))),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _expenses.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final item = _expenses[index];
                    return ListTile(
                      dense: true,
                      title: Text(item.description, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('${item.quantity} x S/. ${item.unitPrice.toStringAsFixed(2)}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('S/. ${item.total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                            onPressed: () => setState(() => _expenses.removeAt(index)),
                          ),
                        ],
                      ),
                    );
                  },
                ),

              const Divider(thickness: 2),
              Container(
                padding: const EdgeInsets.all(10),
                color: Colors.indigo.shade50,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('TOTAL SOLICITADO:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text('S/. ${_calculateTotal().toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.indigo.shade800)),
                  ],
                ),
              ),

              const SizedBox(height: 25),
              _buildSectionTitle('3. PROGRAMA SUGERIDO', Icons.list_alt),
              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(child: _buildTextField('Dirige', _conductedByController)),
                  const SizedBox(width: 10),
                  Expanded(child: _buildTextField('Preside', _presidedByController)),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: HymnAutocomplete(
                      label: '1er Himno',
                      controller: _openingHymnController,
                      icon: Icons.music_note,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: _buildTextField('1ra Oración', _openingPrayerController)),
                ],
              ),
              const SizedBox(height: 10),

              _buildTextField(
                'Desarrollo de la Actividad (Mensaje, Clase, Dinámica...)',
                _developmentController,
                maxLines: 3,
                icon: Icons.article_outlined,
              ),

              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: HymnAutocomplete(
                      label: 'Himno Final',
                      controller: _closingHymnController,
                      icon: Icons.music_note,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: _buildTextField('Oración Final', _closingPrayerController)),
                ],
              ),
              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(child: _buildTextField('Encargados Limpieza', _cleaningController, icon: Icons.cleaning_services)),
                  const SizedBox(width: 10),
                  Expanded(child: _buildTextField('Encargados Seguridad', _securityController, icon: Icons.security)),
                ],
              ),

              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _saveBudget,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF22539A),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('GUARDAR Y GENERAR PDF', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF22539A)),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF22539A))),
      ],
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {IconData? icon, bool isNumber = false, int maxLines = 1, bool isDense = false}) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
      maxLines: maxLines,
      validator: (value) {
        if (!isDense && (value == null || value.isEmpty)) return 'Requerido';
        return null;
      },
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: icon != null ? Icon(icon, size: 20) : null,
        border: const OutlineInputBorder(),
        contentPadding: isDense ? const EdgeInsets.symmetric(horizontal: 10, vertical: 8) : null,
      ),
    );
  }

  Widget _buildDatePicker(String label, DateTime? date, Function(DateTime) onChanged) {
    return InkWell(
      onTap: () async {
        final initial = date ?? DateTime.now();
        final picked = await showDatePicker(
          context: context,
          initialDate: initial.isBefore(DateTime(2020)) ? DateTime.now() : initial,
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
        );
        if (picked != null) onChanged(picked);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          prefixIcon: const Icon(Icons.calendar_today),
        ),
        child: Text(
          date != null ? DateFormat('dd/MM/yyyy').format(date) : 'Seleccionar',
          style: TextStyle(color: date != null ? Colors.black : Colors.grey),
        ),
      ),
    );
  }

  void _addExpenseItem() {
    if (_itemDescController.text.isEmpty || _itemPriceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ingresa descripción y precio')));
      return;
    }

    setState(() {
      _expenses.add(BudgetItem(
        description: _itemDescController.text.trim(),
        quantity: int.tryParse(_itemQtyController.text) ?? 1,
        unitPrice: double.tryParse(_itemPriceController.text) ?? 0.0,
      ));
      _itemDescController.clear();
      _itemQtyController.text = '1';
      _itemPriceController.clear();
    });
  }

  double _calculateTotal() {
    return _expenses.fold(0, (sum, item) => sum + item.total);
  }

  Future<void> _saveBudget() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Por favor completa los campos obligatorios')));
      return;
    }
    if (_activityDate == null || _presentationDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selecciona las fechas')));
      return;
    }

    setState(() => _isSaving = true);

    try {
      final String targetWard = widget.budgetToEdit?.ward ??
          widget.fromActivity?.ward ??
          widget.currentUser?.ward ??
          '';

      final newBudget = ActivityBudgetModel(
        id: widget.budgetToEdit?.id ?? '',
        organization: _organizationController.text.trim(),
        responsibleLeader: _leaderController.text.trim(),
        activityDate: _activityDate!,
        activityName: _activityNameController.text.trim(),
        activityPurpose: _purposeController.text.trim(),
        presentationDate: _presentationDate!,
        applicantName: _applicantController.text.trim(),
        ward: targetWard,
        expenses: _expenses,
        conductedBy: _conductedByController.text.trim(),
        presidedBy: _presidedByController.text.trim(),
        openingHymn: _openingHymnController.text.trim(),
        openingPrayer: _openingPrayerController.text.trim(),
        activityDevelopment: _developmentController.text.trim(),
        closingHymn: _closingHymnController.text.trim(),
        closingPrayer: _closingPrayerController.text.trim(),
        cleaningTeam: _cleaningController.text.trim(),
        securityTeam: _securityController.text.trim(),
      );

      if (widget.budgetToEdit != null) {
        await FirebaseFirestore.instance.collection('activity_budgets').doc(widget.budgetToEdit!.id).update(newBudget.toMap());
      } else {
        await FirebaseFirestore.instance.collection('activity_budgets').add(newBudget.toMap());
      }

      if (mounted) {
        final pdfData = await BudgetPdfService().generateActivityBudgetPdf(newBudget);

        await Printing.layoutPdf(
          onLayout: (PdfPageFormat format) async => pdfData,
          name: 'HP-${newBudget.activityName}.pdf',
        );

        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Guardado y generado exitosamente')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}