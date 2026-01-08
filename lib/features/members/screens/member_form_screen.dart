import 'package:flutter/material.dart';
import 'package:gestor_lds/features/members/models/member_model.dart';
import 'package:gestor_lds/features/members/services/member_service.dart';
import 'package:intl/intl.dart';

class MemberFormScreen extends StatefulWidget {
  final MemberModel? memberToEdit; // Si es null, estamos creando uno nuevo

  const MemberFormScreen({super.key, this.memberToEdit});

  @override
  State<MemberFormScreen> createState() => _MemberFormScreenState();
}

class _MemberFormScreenState extends State<MemberFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final MemberService _memberService = MemberService();

  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _callingCtrl = TextEditingController();
  final _birthDateCtrl = TextEditingController();

  String _gender = 'M'; // Default
  String _selectedOrganization = 'Cuórum de Élderes';
  DateTime? _selectedBirthDate;

  final List<String> _orgs = [
    'Obispado', 'Cuórum de Élderes', 'Sociedad de Socorro',
    'Mujeres Jóvenes', 'Hombres Jóvenes', 'Primaria', 'Escuela Dominical', 'Otro'
  ];

  @override
  void initState() {
    super.initState();
    if (widget.memberToEdit != null) {
      // Cargar datos existentes
      final m = widget.memberToEdit!;
      _firstNameCtrl.text = m.firstName;
      _lastNameCtrl.text = m.lastName;
      _phoneCtrl.text = m.phone ?? '';
      _emailCtrl.text = m.email ?? '';
      _callingCtrl.text = m.calling ?? '';
      _gender = m.gender;
      _selectedOrganization = _orgs.contains(m.organization) ? m.organization : 'Otro';

      if (m.birthDate != null) {
        _selectedBirthDate = m.birthDate;
        _birthDateCtrl.text = DateFormat('dd/MM/yyyy').format(m.birthDate!);
      }
    }
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

  void _save() async {
    if (_formKey.currentState!.validate()) {
      final newMember = MemberModel(
        id: widget.memberToEdit?.id ?? '', // Si es vacío, Firestore crea ID nuevo
        firstName: _firstNameCtrl.text.trim(),
        lastName: _lastNameCtrl.text.trim(),
        fullName: '', // Se genera dentro del modelo/servicio
        gender: _gender,
        birthDate: _selectedBirthDate,
        phone: _phoneCtrl.text.isEmpty ? null : _phoneCtrl.text.trim(),
        email: _emailCtrl.text.isEmpty ? null : _emailCtrl.text.trim(),
        organization: _selectedOrganization,
        calling: _callingCtrl.text.isEmpty ? null : _callingCtrl.text.trim(),
        relatedUserId: widget.memberToEdit?.relatedUserId, // Mantenemos el link si existe
      );

      await _memberService.saveMember(newMember);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Miembro guardado con éxito')));
        Navigator.pop(context);
      }
    }
  }

  void _delete() async {
    final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Eliminar Miembro'),
          content: Text('¿Seguro que deseas eliminar a ${_firstNameCtrl.text}?'),
          actions: [
            TextButton(onPressed: ()=>Navigator.pop(ctx, false), child: const Text('Cancelar')),
            TextButton(onPressed: ()=>Navigator.pop(ctx, true), child: const Text('Eliminar', style: TextStyle(color: Colors.red))),
          ],
        )
    );

    if (confirm == true && widget.memberToEdit != null) {
      await _memberService.deleteMember(widget.memberToEdit!.id);
      if(mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.memberToEdit == null ? 'Nuevo Miembro' : 'Editar Miembro'),
        actions: [
          if (widget.memberToEdit != null)
            IconButton(icon: const Icon(Icons.delete), onPressed: _delete),
        ],
      ),
      body: Center(
      child:SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600), // Para que se vea bien en Web
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // Nombres
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _firstNameCtrl,
                        decoration: const InputDecoration(labelText: 'Nombres', border: OutlineInputBorder()),
                        validator: (v) => v!.isEmpty ? 'Requerido' : null,
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: TextFormField(
                        controller: _lastNameCtrl,
                        decoration: const InputDecoration(labelText: 'Apellidos', border: OutlineInputBorder()),
                        validator: (v) => v!.isEmpty ? 'Requerido' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),

                // Género
                Row(
                  children: [
                    const Text('Género:', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 20),
                    ChoiceChip(
                      label: const Text('Hermano'),
                      selected: _gender == 'M',
                      onSelected: (sel) => setState(() => _gender = 'M'),
                    ),
                    const SizedBox(width: 10),
                    ChoiceChip(
                      label: const Text('Hermana'),
                      selected: _gender == 'F',
                      onSelected: (sel) => setState(() => _gender = 'F'),
                    ),
                  ],
                ),
                const SizedBox(height: 15),

                // Organización y Llamamiento
                DropdownButtonFormField<String>(
                  value: _selectedOrganization,
                  decoration: const InputDecoration(labelText: 'Organización', border: OutlineInputBorder()),
                  items: _orgs.map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
                  onChanged: (v) => setState(() => _selectedOrganization = v!),
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: _callingCtrl,
                  decoration: const InputDecoration(labelText: 'Llamamiento (Opcional)', border: OutlineInputBorder(), hintText: 'Ej. Maestra de Primaria'),
                ),

                const Divider(height: 30),
                const Text('Datos de Contacto', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 10),

                // Fecha Nacimiento
                TextFormField(
                  controller: _birthDateCtrl,
                  decoration: const InputDecoration(labelText: 'Fecha de Nacimiento', border: OutlineInputBorder(), suffixIcon: Icon(Icons.calendar_today)),
                  readOnly: true,
                  onTap: _pickDate,
                ),
                const SizedBox(height: 15),

                TextFormField(
                  controller: _phoneCtrl,
                  decoration: const InputDecoration(labelText: 'Teléfono', border: OutlineInputBorder(), prefixIcon: Icon(Icons.phone)),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: _emailCtrl,
                  decoration: const InputDecoration(labelText: 'Correo Electrónico', border: OutlineInputBorder(), prefixIcon: Icon(Icons.email)),
                  keyboardType: TextInputType.emailAddress,
                ),

                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _save,
                    child: const Text('Guardar', style: TextStyle(fontSize: 18)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      ),
    );
  }
}