import 'package:flutter/material.dart';
import 'package:gestor_lds/features/members/models/member_model.dart';
import 'package:gestor_lds/features/members/services/member_service.dart';
import 'package:gestor_lds/core/constants/wards_list.dart';
// 🚀 IMPORTAMOS TU MAPA DE CONSTRAINTS DESDE SU ARCHIVO
import 'package:gestor_lds/core/constants/callings_ward_list.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/organizations_list.dart';

class MemberFormScreen extends StatefulWidget {
  final MemberModel? memberToEdit;

  const MemberFormScreen({super.key, this.memberToEdit});

  @override
  State<MemberFormScreen> createState() => _MemberFormScreenState();
}

class _MemberFormScreenState extends State<MemberFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final MemberService _memberService = MemberService();
  final Color _brandBlue = const Color(0xFF22539A);

  // Controladores
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _birthDateCtrl = TextEditingController();
  final _callingCtrl = TextEditingController(); // Usado si el llamamiento es "Otro"

  // Variables de Estado
  String _gender = 'M';
  DateTime? _selectedBirthDate;
  bool _isLoading = false;
  bool _isYSA = false;

  // 🚀 VARIABLES DEL DOBLE PIVOTE
  String? _selectedWard;
  String _primaryOrganization = 'Miembro General';
  String _servingOrganization = 'Miembro General';
  String? _selectedCalling;

  @override
  void initState() {
    super.initState();
    if (widget.memberToEdit != null) {
      _loadExistingData();
    }
  }

  void _loadExistingData() {
    final m = widget.memberToEdit!;
    _firstNameCtrl.text = m.firstName;
    _lastNameCtrl.text = m.lastName;
    _phoneCtrl.text = m.phone ?? '';
    _emailCtrl.text = m.email ?? '';
    _gender = m.gender;
    _isYSA = m.isYSA;

    // Barrio
    if (kWardsList.contains(m.ward)) {
      _selectedWard = m.ward;
    }

// 🚀 1. Cargar Organización Principal (Validado contra kOrganizationsList)
    if (kOrganizationsList.contains(m.primaryOrganization)) {
      _primaryOrganization = m.primaryOrganization;
    } else {
      _primaryOrganization = 'Miembro General'; // Fallback por seguridad
    }

    // 🚀 2. Cargar Organización de Llamamiento (Validado contra kLdsStructure)
    String servingOrg = m.servingOrganization ?? m.primaryOrganization;
    if (kLdsStructure.containsKey(servingOrg)) {
      _servingOrganization = servingOrg;
    } else {
      _servingOrganization = 'Miembro General'; // Fallback por seguridad
    }

    // 3. Cargar Llamamiento
    if (m.calling != null && m.calling!.isNotEmpty) {
      final availableCallings = kLdsStructure[_servingOrganization] ?? [];
      if (availableCallings.contains(m.calling)) {
        _selectedCalling = m.calling;
      } else {
        _selectedCalling = 'Otro';
        _callingCtrl.text = m.calling!;
      }
    }

    if (m.birthDate != null) {
      _selectedBirthDate = m.birthDate;
      _birthDateCtrl.text = DateFormat('dd/MM/yyyy').format(m.birthDate!);
    }
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _birthDateCtrl.dispose();
    _callingCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedBirthDate ?? DateTime(2000),
      firstDate: DateTime(1920),
      lastDate: now,
    );
    if (picked != null) {
      setState(() {
        _selectedBirthDate = picked;
        _birthDateCtrl.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedWard == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('⚠️ Por favor, selecciona el barrio del miembro'), backgroundColor: Colors.orange));
      return;
    }

    setState(() => _isLoading = true);

    try {
      String? finalCalling;
      final availableCallings = kLdsStructure[_servingOrganization] ?? [];

      if (availableCallings.isNotEmpty) {
        if (_selectedCalling == 'Otro') {
          finalCalling = _callingCtrl.text.trim();
        } else {
          finalCalling = _selectedCalling;
        }
      } else {
        finalCalling = _callingCtrl.text.trim();
      }

      final newMember = MemberModel(
        id: widget.memberToEdit?.id ?? '',
        firstName: _firstNameCtrl.text.trim(),
        lastName: _lastNameCtrl.text.trim(),
        gender: _gender,
        birthDate: _selectedBirthDate,
        phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
        email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
        ward: _selectedWard!,
        primaryOrganization: _primaryOrganization,
        servingOrganization: _servingOrganization,
        calling: (finalCalling == null || finalCalling.isEmpty) ? null : finalCalling,
        isYSA: _isYSA,
        relatedUserId: widget.memberToEdit?.relatedUserId,
      );

      await _memberService.saveMember(newMember);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Ficha guardada con éxito'), backgroundColor: Colors.green));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Lista combinada usando la constante importada
    final orgList = ['Miembro General', ...kLdsStructure.keys.toList()];
    final availableCallings = kLdsStructure[_servingOrganization] ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFFEEF2F6),
      appBar: AppBar(
        title: Text(widget.memberToEdit == null ? 'Nuevo Miembro' : 'Editar Ficha', style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: _brandBlue,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [

                  // 🚀 TARJETA 1: IDENTIDAD
                  _buildCard(
                    title: 'Identidad y Contacto',
                    icon: Icons.person,
                    children: [
                      Row(
                        children: [
                          Expanded(child: _buildTextField('Nombres', _firstNameCtrl, required: true)),
                          const SizedBox(width: 15),
                          Expanded(child: _buildTextField('Apellidos', _lastNameCtrl, required: true)),
                        ],
                      ),
                      const SizedBox(height: 15),
                      Row(
                        children: [
                          const Text('Género:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
                          const SizedBox(width: 15),
                          ChoiceChip(
                            label: const Text('Hombre'),
                            selected: _gender == 'M',
                            onSelected: (sel) => setState(() => _gender = 'M'),
                            avatar: const Icon(Icons.male, size: 18),
                            selectedColor: Colors.blue.shade100,
                          ),
                          const SizedBox(width: 10),
                          ChoiceChip(
                            label: const Text('Mujer'),
                            selected: _gender == 'F',
                            onSelected: (sel) => setState(() => _gender = 'F'),
                            avatar: const Icon(Icons.female, size: 18),
                            selectedColor: Colors.pink.shade100,
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      TextFormField(
                        controller: _birthDateCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Fecha de Nacimiento',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.calendar_today),
                          isDense: true,
                        ),
                        readOnly: true,
                        onTap: _pickDate,
                      ),
                      const SizedBox(height: 15),
                      _buildTextField('Celular / WhatsApp', _phoneCtrl, icon: Icons.phone, isPhone: true),
                      const SizedBox(height: 15),
                      _buildTextField('Correo Electrónico', _emailCtrl, icon: Icons.email, isEmail: true),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // 🚀 TARJETA 2: PERTENENCIA ECLESIÁSTICA (DOBLE PIVOTE)
                  _buildCard(
                    title: 'Organización y Llamamiento',
                    icon: Icons.account_balance,
                    children: [
                      DropdownButtonFormField<String>(
                        value: _selectedWard,
                        decoration: const InputDecoration(
                          labelText: 'Barrio Actual',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.location_city),
                          isDense: true,
                        ),
                        items: kWardsList.map((w) => DropdownMenuItem(value: w, child: Text(w))).toList(),
                        onChanged: (v) => setState(() => _selectedWard = v),
                        validator: (v) => v == null ? 'Requerido' : null,
                      ),
                      const SizedBox(height: 15),

                      // 2. ORGANIZACIÓN PRINCIPAL (Usa kOrganizationsList)
                      DropdownButtonFormField<String>(
                        value: _primaryOrganization,
                        decoration: const InputDecoration(
                          labelText: 'Org. Principal (Membresía)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person_pin),
                          isDense: true,
                        ),
                        // 🚀 Aquí usamos la lista simple de membresía
                        items: kOrganizationsList.map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
                        onChanged: (v) => setState(() => _primaryOrganization = v!),
                      ),
                      const SizedBox(height: 15),

                      // 3. ORGANIZACIÓN DEL LLAMAMIENTO (Usa las llaves de kLdsStructure)
                      DropdownButtonFormField<String>(
                        value: _servingOrganization,
                        decoration: const InputDecoration(
                          labelText: '¿En qué organización sirve?',
                          helperText: 'Esto filtra la lista de llamamientos de abajo',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.assignment_ind),
                          isDense: true,
                        ),
                        // 🚀 Aquí usamos las llaves del mapa de llamamientos
                        items: ['Miembro General', ...kLdsStructure.keys.toList()]
                            .map((o) => DropdownMenuItem(value: o, child: Text(o)))
                            .toList(),
                        onChanged: (v) {
                          setState(() {
                            _servingOrganization = v!;
                            _selectedCalling = null;
                            _callingCtrl.clear();
                          });
                        },
                      ),
                      const SizedBox(height: 15),

                      if (availableCallings.isNotEmpty) ...[
                        DropdownButtonFormField<String>(
                          value: _selectedCalling,
                          decoration: const InputDecoration(
                            labelText: 'Llamamiento Oficial',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.badge),
                            isDense: true,
                          ),
                          items: [...availableCallings, 'Otro'].map((c) => DropdownMenuItem(value: c, child: Text(c, overflow: TextOverflow.ellipsis))).toList(),
                          onChanged: (v) => setState(() => _selectedCalling = v),
                        ),
                        if (_selectedCalling == 'Otro') ...[
                          const SizedBox(height: 15),
                          TextFormField(
                            controller: _callingCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Especificar Llamamiento',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.edit),
                              isDense: true,
                            ),
                          ),
                        ]
                      ] else ...[
                        TextFormField(
                          controller: _callingCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Asignación / Tarea (Opcional)',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.badge),
                            isDense: true,
                          ),
                        ),
                      ],

                      const SizedBox(height: 20),
                      Container(
                        decoration: BoxDecoration(
                          color: _isYSA ? _brandBlue.withOpacity(0.05) : Colors.transparent,
                          border: Border.all(color: _isYSA ? _brandBlue : Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: SwitchListTile(
                          title: Text(
                            '¿Es Joven Adulto Soltero (JAS)?',
                            style: TextStyle(fontWeight: FontWeight.bold, color: _isYSA ? _brandBlue : Colors.black87),
                          ),
                          subtitle: const Text('Marcar si tiene 18-35 años y es soltero(a)'),
                          value: _isYSA,
                          activeColor: _brandBlue,
                          onChanged: (val) => setState(() => _isYSA = val),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),

                  SizedBox(
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _save,
                      icon: _isLoading ? const SizedBox.shrink() : const Icon(Icons.save),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: _brandBlue,
                          foregroundColor: Colors.white,
                          elevation: 3,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                      ),
                      label: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('GUARDAR FICHA', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Helpers visuales
  Widget _buildCard({required String title, required IconData icon, required List<Widget> children}) {
    return Card(
      elevation: 4,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              children: [
                Icon(icon, color: _brandBlue, size: 28),
                const SizedBox(width: 12),
                Expanded(child: Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _brandBlue))),
              ],
            ),
            const Divider(thickness: 1, height: 30),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController ctrl, {bool required = false, IconData? icon, bool isPhone = false, bool isEmail = false}) {
    return TextFormField(
      controller: ctrl,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: icon != null ? Icon(icon) : null,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
      keyboardType: isPhone ? TextInputType.phone : (isEmail ? TextInputType.emailAddress : TextInputType.text),
      validator: required ? (v) => v!.isEmpty ? 'Requerido' : null : null,
      textCapitalization: isEmail ? TextCapitalization.none : TextCapitalization.words,
    );
  }
}