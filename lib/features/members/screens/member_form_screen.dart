import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;

import 'package:gestor_lds/features/auth/models/user_model.dart';
import 'package:gestor_lds/core/constants/wards_list.dart';
import 'package:gestor_lds/core/constants/organizations_list.dart';
import 'package:gestor_lds/core/constants/callings_ward_list.dart';
import 'package:gestor_lds/core/constants/callings_stake_list.dart';

class MemberFormScreen extends StatefulWidget {
  final UserModel? memberToEdit;
  final bool isStakeMode;
  final UserModel currentUser;

  const MemberFormScreen({
    super.key,
    this.memberToEdit,
    required this.isStakeMode,
    required this.currentUser,
  });

  @override
  State<MemberFormScreen> createState() => _MemberFormScreenState();
}

class _MemberFormScreenState extends State<MemberFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final Color _brandBlue = const Color(0xFF22539A);

  // 1. Controladores Datos Personales
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _birthDateCtrl = TextEditingController();
  final _callingCtrl = TextEditingController();

  // 2. Estado de Membresía
  String _gender = 'M';
  DateTime? _selectedBirthDate;
  bool _isLoading = false;
  bool _isYSA = false;
  bool _isStakeCalling = false;
  List<Map<String, String>> _activeCallings = [];

  String? _selectedWard;
  String _primaryOrganization = 'Miembro General';
  String _servingOrganization = 'Miembro General';
  String? _selectedCalling;

  // 3. 🔐 Controles Administrativos Unificados
  UserRole _selectedRole = UserRole.miembro;
  bool _isApproved = true;
  bool _isActive = true;
  bool _isRegistered = false;

  // Permisos para gestionar credenciales y roles
  bool get _canManageSystemAccess {
    final role = widget.currentUser.role;
    return role == UserRole.admin ||
        role == UserRole.presidencia_estaca ||
        role == UserRole.obispado;
  }

  @override
  void initState() {
    super.initState();
    if (widget.memberToEdit != null) {
      _loadExistingData();
    } else {
      if (kWardsList.contains(widget.currentUser.ward)) {
        _selectedWard = widget.currentUser.ward;
      } else if (kWardsList.isNotEmpty) {
        _selectedWard = kWardsList.first;
      }
      _isApproved = true; // Si lo crea un líder, nace pre-aprobado
      _isActive = true;
      _isRegistered = false;
    }
  }

  void _loadExistingData() {
    final u = widget.memberToEdit!;
    _firstNameCtrl.text = u.firstName;
    _lastNameCtrl.text = u.lastName;
    _phoneCtrl.text = u.phone ?? '';
    _emailCtrl.text = u.email ?? '';
    _gender = u.gender;
    _isYSA = u.isYSA;

    if (kWardsList.contains(u.ward)) {
      _selectedWard = u.ward;
    }

    if (kOrganizationsList.contains(u.organization)) {
      _primaryOrganization = u.organization;
    }

    // Llamamientos activos
    int count = math.max(u.callings.length, u.callingOrganizations.length);
    for (int i = 0; i < count; i++) {
      String o = i < u.callingOrganizations.length ? u.callingOrganizations[i] : 'Miembro General';
      String c = i < u.callings.length ? u.callings[i] : 'Ninguno';

      if (c != 'Ninguno' && c.isNotEmpty) {
        _activeCallings.add({'org': o, 'calling': c});
      }
    }

    if (u.birthDate != null) {
      _selectedBirthDate = u.birthDate;
      _birthDateCtrl.text = DateFormat('dd/MM/yyyy').format(u.birthDate!);
    }

    // Datos administrativos unificados
    _selectedRole = u.role;
    _isApproved = u.isApproved;
    _isActive = u.isActive;
    _isRegistered = u.isRegistered;
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

  void _addCallingToList() {
    String finalCalling = 'Ninguno';
    final currentMap = _isStakeCalling ? kStakeStructure : kLdsStructure;
    final availableCallings = currentMap[_servingOrganization] ?? [];

    if (availableCallings.isNotEmpty) {
      if (_selectedCalling == 'Otro') {
        finalCalling = _callingCtrl.text.trim();
      } else if (_selectedCalling != null) {
        finalCalling = _selectedCalling!;
      }
    } else if (_callingCtrl.text.trim().isNotEmpty) {
      finalCalling = _callingCtrl.text.trim();
    }

    if (finalCalling == 'Ninguno' || finalCalling.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Especifique un llamamiento antes de añadir.')),
      );
      return;
    }

    setState(() {
      _activeCallings.add({'org': _servingOrganization, 'calling': finalCalling});
      _servingOrganization = 'Miembro General';
      _selectedCalling = null;
      _callingCtrl.clear();
      _isStakeCalling = false;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedWard == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ Por favor, selecciona el barrio del miembro'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      List<String> finalOrgs = _activeCallings.map((e) => e['org']!).toList();
      List<String> finalCalls = _activeCallings.map((e) => e['calling']!).toList();

      if (finalOrgs.isEmpty) finalOrgs = [_primaryOrganization];
      if (finalCalls.isEmpty) finalCalls = ['Ninguno'];

      final collection = FirebaseFirestore.instance.collection('users');
      final docId = widget.memberToEdit?.uid ?? collection.doc().id;
      final phoneValue = _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim();

      final userData = {
        'firstName': _firstNameCtrl.text.trim(),
        'lastName': _lastNameCtrl.text.trim(),
        'gender': _gender,
        'birthDate': _selectedBirthDate != null ? Timestamp.fromDate(_selectedBirthDate!) : null,
        'phone': phoneValue,
        'phoneNumber': phoneValue,
        'email': _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
        'ward': _selectedWard!,
        'organization': _primaryOrganization,
        'callingOrganizations': finalOrgs,
        'callings': finalCalls,
        'isYSA': _isYSA,
        // Campos administrativos unificados
        'role': _selectedRole.name,
        'isApproved': _isApproved,
        'isActive': _isActive,
        'isRegistered': _isRegistered,
      };

      if (widget.memberToEdit == null) {
        userData['createdAt'] = Timestamp.now();
      }

      await collection.doc(docId).set(userData, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Ficha y credenciales guardadas con éxito'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentStructure = _isStakeCalling ? kStakeStructure : kLdsStructure;
    final availableCallings = currentStructure[_servingOrganization] ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFFEEF2F6),
      appBar: AppBar(
        title: Text(widget.memberToEdit == null ? 'Nuevo Miembro' : 'Editar Ficha y Permisos', style: const TextStyle(fontWeight: FontWeight.bold)),
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
                  // 1. DATOS PERSONALES
                  _buildCard(
                    title: '1. Identidad y Contacto',
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
                      _buildTextField('Correo Electrónico (Opcional)', _emailCtrl, icon: Icons.email, isEmail: true),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // 2. MEMBRESÍA Y UNIDAD
                  _buildCard(
                    title: '2. Membresía y Unidad',
                    icon: Icons.account_balance,
                    children: [
                      DropdownButtonFormField<String>(
                        value: _selectedWard,
                        decoration: InputDecoration(
                          labelText: 'Barrio Actual',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.location_city),
                          isDense: true,
                          filled: !widget.isStakeMode,
                          fillColor: widget.isStakeMode ? Colors.white : Colors.grey.shade100,
                        ),
                        items: kWardsList.map((w) => DropdownMenuItem(value: w, child: Text(w))).toList(),
                        onChanged: widget.isStakeMode ? (v) => setState(() => _selectedWard = v) : null,
                        validator: (v) => v == null ? 'Requerido' : null,
                      ),
                      if (!widget.isStakeMode)
                        const Padding(
                          padding: EdgeInsets.only(top: 8.0, left: 4.0),
                          child: Text(
                            'Solo la Estaca puede trasladar miembros entre barrios.',
                            style: TextStyle(fontSize: 11, color: Colors.grey, fontStyle: FontStyle.italic),
                          ),
                        ),
                      const SizedBox(height: 15),
                      DropdownButtonFormField<String>(
                        value: _primaryOrganization,
                        decoration: const InputDecoration(
                          labelText: 'Org. Principal (Membresía)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person_pin),
                          isDense: true,
                        ),
                        items: ['Miembro General', ...kOrganizationsList].toSet().map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
                        onChanged: (v) => setState(() => _primaryOrganization = v!),
                      ),
                      const SizedBox(height: 15),
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

                  const SizedBox(height: 20),

                  // 3. LLAMAMIENTOS
                  _buildCard(
                    title: '3. Llamamientos Asignados',
                    icon: Icons.badge,
                    children: [
                      if (_activeCallings.isEmpty)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 20),
                          child: Text('Sin llamamientos asignados.', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
                        )
                      else
                        Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _activeCallings.map((item) {
                              return Chip(
                                backgroundColor: _brandBlue.withOpacity(0.1),
                                label: Text('${item['calling']} (${item['org']})', style: TextStyle(color: _brandBlue, fontWeight: FontWeight.bold)),
                                deleteIcon: const Icon(Icons.cancel, size: 20, color: Colors.redAccent),
                                onDeleted: () => setState(() => _activeCallings.remove(item)),
                              );
                            }).toList(),
                          ),
                        ),
                      const Divider(),
                      const SizedBox(height: 10),
                      const Text('Añadir Nuevo Llamamiento', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 15),
                      Container(
                        decoration: BoxDecoration(
                          color: _isStakeCalling ? Colors.purple.shade50 : Colors.transparent,
                          border: Border.all(color: _isStakeCalling ? Colors.purple : Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: SwitchListTile(
                          title: Text(
                            'Es un llamamiento de Estaca',
                            style: TextStyle(fontWeight: FontWeight.bold, color: _isStakeCalling ? Colors.purple : Colors.black87),
                          ),
                          value: _isStakeCalling,
                          activeColor: Colors.purple,
                          onChanged: (val) {
                            setState(() {
                              _isStakeCalling = val;
                              _servingOrganization = 'Miembro General';
                              _selectedCalling = null;
                              _callingCtrl.clear();
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 15),
                      DropdownButtonFormField<String>(
                        value: _servingOrganization,
                        decoration: const InputDecoration(
                          labelText: '¿En qué organización sirve?',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.assignment_ind),
                          isDense: true,
                        ),
                        items: ['Miembro General', ...currentStructure.keys].toSet().map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
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
                            prefixIcon: Icon(Icons.star),
                            isDense: true,
                          ),
                          items: [...availableCallings, 'Otro'].toSet().map((c) => DropdownMenuItem(value: c, child: Text(c, overflow: TextOverflow.ellipsis))).toList(),
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
                            prefixIcon: Icon(Icons.star),
                            isDense: true,
                          ),
                        ),
                      ],
                      const SizedBox(height: 15),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton.icon(
                          onPressed: _addCallingToList,
                          icon: const Icon(Icons.add),
                          label: const Text('Añadir a la lista'),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade600, foregroundColor: Colors.white),
                        ),
                      )
                    ],
                  ),

                  // 4. 🔐 SECCIÓN UNIFICADA: ACCESO Y PERMISOS DEL SISTEMA (SOLO LIDERAZGO)
                  if (_canManageSystemAccess) ...[
                    const SizedBox(height: 20),
                    _buildCard(
                      title: '4. Permisos y Acceso al Sistema',
                      icon: Icons.security,
                      children: [
                        const Text(
                          'Configure los privilegios eclesiásticos de la cuenta en la plataforma.',
                          style: TextStyle(fontSize: 12, color: Colors.black54),
                        ),
                        const SizedBox(height: 15),

                        // Selector de Rol
                        DropdownButtonFormField<UserRole>(
                          value: _selectedRole,
                          decoration: const InputDecoration(
                            labelText: 'Rol Eclesiástico en la App',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.admin_panel_settings),
                            isDense: true,
                          ),
                          items: UserRole.values.map((role) {
                            return DropdownMenuItem(
                              value: role,
                              child: Text(_getRoleLabel(role)),
                            );
                          }).toList(),
                          onChanged: (v) => setState(() => _selectedRole = v!),
                        ),
                        const SizedBox(height: 15),

                        // Interruptor de Aprobación
                        SwitchListTile(
                          title: const Text('Cuenta Aprobada', style: TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: const Text('Permite el acceso a los módulos correspondientes'),
                          value: _isApproved,
                          activeColor: Colors.green,
                          contentPadding: EdgeInsets.zero,
                          onChanged: (val) => setState(() => _isApproved = val),
                        ),
                        const Divider(),

                        // Interruptor de Estado Activo
                        SwitchListTile(
                          title: const Text('Miembro Activo en el Sistema', style: TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: const Text('Si se desactiva, no aparecerá en búsquedas ni listas operativas'),
                          value: _isActive,
                          activeColor: _brandBlue,
                          contentPadding: EdgeInsets.zero,
                          onChanged: (val) => setState(() => _isActive = val),
                        ),
                        const Divider(),

                        // Estado de Registro (Lectura / Feedback)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(
                            _isRegistered ? Icons.check_circle : Icons.warning_amber_rounded,
                            color: _isRegistered ? Colors.green : Colors.orange,
                          ),
                          title: Text(_isRegistered ? 'Cuenta Vinculada' : 'Ficha sin Registro Directo'),
                          subtitle: Text(
                            _isRegistered
                                ? 'El miembro ya creó su cuenta con correo y contraseña.'
                                : 'Ficha creada por el liderazgo. El miembro podrá reclamarla al iniciar sesión con su correo.',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ],

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
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      label: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('GUARDAR FICHA COMPLETA', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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

  String _getRoleLabel(UserRole role) {
    switch (role) {
      case UserRole.admin: return 'Administrador Global';
      case UserRole.presidencia_estaca: return 'Presidencia de Estaca';
      case UserRole.obispado: return 'Obispado (Obispo / Consejero)';
      case UserRole.lider_estaca: return 'Líder Auxiliar de Estaca';
      case UserRole.lider_barrio: return 'Presidencia Auxiliar de Barrio';
      case UserRole.miembro: return 'Miembro General';
    }
  }

  Widget _buildCard({required String title, required IconData icon, required List<Widget> children}) {
    return Card(
      elevation: 4,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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