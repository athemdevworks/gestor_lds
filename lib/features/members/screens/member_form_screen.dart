import 'package:flutter/material.dart';
import 'package:gestor_lds/features/members/models/member_model.dart';
import 'package:gestor_lds/features/members/services/member_service.dart';
import 'package:gestor_lds/core/constants/callings_list.dart'; // Tu archivo de constantes
import 'package:intl/intl.dart';

class MemberFormScreen extends StatefulWidget {
  final MemberModel? memberToEdit;

  const MemberFormScreen({super.key, this.memberToEdit});

  @override
  State<MemberFormScreen> createState() => _MemberFormScreenState();
}

class _MemberFormScreenState extends State<MemberFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final MemberService _memberService = MemberService();

  // Controladores de Texto
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _birthDateCtrl = TextEditingController();
  // NOTA: _callingCtrl YA NO EXISTE porque usamos dropdown

  // Variables de Estado
  String _gender = 'M';
  DateTime? _selectedBirthDate;
  bool _isLoading = false;

  // Variables de Lógica
  String _primaryOrganization = 'Cuórum de Élderes'; // Pertenencia
  bool _isYSA = false;

  // Variables de Servicio (Dropdowns)
  String? _servingOrganization; // La llave del Mapa
  String? _selectedCalling;     // El valor de la Lista

  // Lista Fija de Pertenencia
  final List<String> _primaryOrgsList = [
    'Obispado', 'Cuórum de Élderes', 'Sociedad de Socorro',
    'Presbíteros', 'Maestros', 'Diáconos',
    'Mujeres Jóvenes', 'Primaria'
  ];

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

    // Pertenencia
    if (_primaryOrgsList.contains(m.primaryOrganization)) {
      _primaryOrganization = m.primaryOrganization;
    } else {
      _primaryOrganization = 'Otro';
    }
    _isYSA = m.isYSA;

    // Carga Inteligente de Llamamiento
    if (m.servingOrganization != null && kLdsStructure.containsKey(m.servingOrganization)) {
      _servingOrganization = m.servingOrganization;

      final possibleCallings = kLdsStructure[_servingOrganization]!;
      if (m.calling != null && possibleCallings.contains(m.calling)) {
        _selectedCalling = m.calling;
      } else {
        _selectedCalling = null;
      }
    } else {
      _servingOrganization = null;
      _selectedCalling = null;
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
    setState(() => _isLoading = true);

    try {
      final newMember = MemberModel(
        id: widget.memberToEdit?.id ?? '',
        firstName: _firstNameCtrl.text.trim(),
        lastName: _lastNameCtrl.text.trim(),
        gender: _gender,
        birthDate: _selectedBirthDate,
        phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
        email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),

        primaryOrganization: _primaryOrganization,
        isYSA: _isYSA,

        servingOrganization: _servingOrganization,
        calling: _selectedCalling,

        relatedUserId: widget.memberToEdit?.relatedUserId,
      );

      await _memberService.saveMember(newMember);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Miembro guardado con éxito')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text(widget.memberToEdit == null ? 'Nuevo Miembro' : 'Editar Miembro'),
        backgroundColor: const Color(0xFF164772),
        foregroundColor: Colors.white,
        centerTitle: true,
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

                  // TARJETA 1: DATOS PERSONALES
                  _buildCard(
                    title: 'Datos Personales',
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
                          const Text('Género:', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(width: 15),
                          ChoiceChip(
                            label: const Text('Hermano'),
                            selected: _gender == 'M',
                            onSelected: (sel) => setState(() => _gender = 'M'),
                            avatar: const Icon(Icons.male, size: 18),
                          ),
                          const SizedBox(width: 10),
                          ChoiceChip(
                            label: const Text('Hermana'),
                            selected: _gender == 'F',
                            onSelected: (sel) => setState(() => _gender = 'F'),
                            avatar: const Icon(Icons.female, size: 18),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      TextFormField(
                        controller: _birthDateCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Fecha de Nacimiento',
                          border: OutlineInputBorder(),
                          suffixIcon: Icon(Icons.calendar_today),
                        ),
                        readOnly: true,
                        onTap: _pickDate,
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // TARJETA 2: PERTENENCIA
                  _buildCard(
                    title: 'Pertenencia Eclesiástica',
                    icon: Icons.groups,
                    children: [
                      DropdownButtonFormField<String>(
                        value: _primaryOrganization,
                        decoration: const InputDecoration(labelText: 'Organización Principal', border: OutlineInputBorder()),
                        items: _primaryOrgsList.map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
                        onChanged: (v) => setState(() => _primaryOrganization = v!),
                      ),
                      const SizedBox(height: 15),

                      // Diseño JAS Destacado
                      Container(
                        decoration: BoxDecoration(
                          color: _isYSA ? const Color(0xFF164772).withOpacity(0.1) : Colors.transparent,
                          border: Border.all(color: _isYSA ? const Color(0xFF164772) : Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: SwitchListTile(
                          title: Text(
                            '¿Es Joven Adulto Soltero (JAS)?',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _isYSA ? const Color(0xFF164772) : Colors.black87
                            ),
                          ),
                          subtitle: const Text('Marcar si tiene 18-35 años y es soltero(a)'),
                          value: _isYSA,
                          activeColor: const Color(0xFF164772),
                          onChanged: (val) => setState(() => _isYSA = val),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // TARJETA 3: LLAMAMIENTO (Cascada Automática)
                  _buildCard(
                    title: 'Llamamiento y Servicio',
                    icon: Icons.work,
                    children: [
                      DropdownButtonFormField<String>(
                        value: _servingOrganization,
                        decoration: const InputDecoration(
                          labelText: 'Organización de Servicio',
                          border: OutlineInputBorder(),
                          helperText: 'Seleccione "Ninguno" para relevar',
                          prefixIcon: Icon(Icons.business),
                        ),
                        items: [
                          const DropdownMenuItem<String>(value: null, child: Text('Ninguno (Sin llamamiento)')),
                          ...kLdsStructure.keys.map((orgKey) => DropdownMenuItem(value: orgKey, child: Text(orgKey))),
                        ],
                        onChanged: (newValue) {
                          setState(() {
                            _servingOrganization = newValue;
                            // Resetear cargo al cambiar organización
                            _selectedCalling = null;
                            // (Aquí borramos la línea problemática de _callingCtrl)
                          });
                        },
                      ),
                      const SizedBox(height: 15),
                      DropdownButtonFormField<String>(
                        key: ValueKey(_servingOrganization),
                        value: _selectedCalling,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Llamamiento Específico',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.badge),
                        ),
                        items: _servingOrganization == null || !kLdsStructure.containsKey(_servingOrganization)
                            ? []
                            : kLdsStructure[_servingOrganization]!.map((cargo) => DropdownMenuItem(value: cargo, child: Text(cargo, overflow: TextOverflow.ellipsis))).toList(),
                        onChanged: _servingOrganization == null
                            ? null
                            : (newValue) => setState(() => _selectedCalling = newValue),
                        hint: Text(_servingOrganization == null ? 'Seleccione organización primero' : 'Seleccione el cargo'),
                        disabledHint: const Text('Primero seleccione organización'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // TARJETA 4: CONTACTO
                  _buildCard(
                    title: 'Contacto',
                    icon: Icons.contact_phone,
                    children: [
                      _buildTextField('Teléfono / WhatsApp', _phoneCtrl, icon: Icons.phone, isPhone: true),
                      const SizedBox(height: 15),
                      _buildTextField('Correo Electrónico', _emailCtrl, icon: Icons.email, isEmail: true),
                    ],
                  ),

                  const SizedBox(height: 30),

                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _save,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF164772),
                          foregroundColor: Colors.white,
                          elevation: 3,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('GUARDAR DATOS', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Icon(icon, color: const Color(0xFF164772)),
                const SizedBox(width: 10),
                Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF164772))),
              ],
            ),
            const Divider(thickness: 1, height: 25),
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
      ),
      keyboardType: isPhone ? TextInputType.phone : (isEmail ? TextInputType.emailAddress : TextInputType.text),
      validator: required ? (v) => v!.isEmpty ? 'Requerido' : null : null,
      textCapitalization: isEmail ? TextCapitalization.none : TextCapitalization.words,
    );
  }
}