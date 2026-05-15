import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:gestor_lds/features/auth/auth_service.dart';
import 'package:gestor_lds/features/auth/models/user_model.dart';
import 'package:gestor_lds/core/utils/alert_utils.dart';
import 'package:gestor_lds/features/auth/screens/login_screen.dart';
import 'package:gestor_lds/features/auth/screens/pending_access_screen.dart'; // 🚀 IMPORTACIÓN DE LA PANTALLA PENDIENTE
import 'package:gestor_lds/core/constants/wards_list.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final Color _brandBlue = const Color(0xFF164772);

  // 🚀 EL MOTOR DE FASES (0 = Buscar, 1 = Reclamar)
  int _currentStep = 0;
  UserModel? _foundUser;
  String? _foundDocId;

  // Controladores - Fase 1 (Búsqueda)
  final _searchLastNameController = TextEditingController();
  String? _selectedWard;

  // Controladores - Fase 2 (Credenciales)
  final _phoneController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  DateTime? _selectedBirthDate;

  bool _obscurePassword = true;
  bool _isLoading = false;

  final AuthService _authService = AuthService();

  @override
  void dispose() {
    _searchLastNameController.dispose();
    _phoneController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // =======================================================
  // 🚀 TÁCTICA 1: BUSCAR LA FICHA IMPORTADA DEL JSON
  // =======================================================
  Future<void> _searchOfficialRecord() async {
    if (_selectedWard == null || _searchLastNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selecciona tu barrio y escribe tu apellido.'), backgroundColor: Colors.orange));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final String searchLastName = _searchLastNameController.text.trim();

      // Buscamos en Firebase las fichas vacías
      final query = await FirebaseFirestore.instance
          .collection('users')
          .where('ward', isEqualTo: _selectedWard)
          .where('lastName', isEqualTo: searchLastName)
          .where('isRegistered', isEqualTo: false)
          .get();

      if (query.docs.isEmpty) {
        if (mounted) {
          showErrorDialog(context, 'Ficha no encontrada', 'No encontramos un registro pendiente con ese apellido en este barrio. Por favor, pídele al Secretario que te agregue al directorio primero.');
        }
      } else if (query.docs.length == 1) {
        // 🚀 PASO DIRECTO: Solo hay un miembro con ese apellido
        final doc = query.docs.first;
        setState(() {
          _foundUser = UserModel.fromMap(doc.data(), doc.id);
          _foundDocId = doc.id;
          _currentStep = 1;
        });
      } else {
        // 🚀 DESEMPATE: Hay múltiples resultados (Hermanos, familias, etc.)
        if (mounted) {
          _showMultiUserDialog(query.docs);
        }
      }
    } catch (e) {
      if (mounted) showErrorDialog(context, 'Error de Búsqueda', e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // =======================================================
  // 🚀 EL VAR: DIÁLOGO DE DESEMPATE PARA APELLIDOS REPETIDOS
  // =======================================================
  void _showMultiUserDialog(List<QueryDocumentSnapshot> docs) {
    showDialog(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Múltiples Fichas Encontradas', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Hay varias personas con ese apellido en el directorio. Selecciona tu nombre para continuar:', style: TextStyle(color: Colors.grey, fontSize: 14)),
                  const SizedBox(height: 15),
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final doc = docs[index];
                        final tempUser = UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);

                        return Card(
                          elevation: 2,
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            leading: CircleAvatar(
                                backgroundColor: _brandBlue.withOpacity(0.1),
                                child: Icon(Icons.person, color: _brandBlue)
                            ),
                            title: Text('${tempUser.firstName} ${tempUser.lastName}', style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(tempUser.primaryCalling), // Muestra el llamamiento para ayudar a identificar
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {
                              Navigator.pop(ctx); // Cierra el diálogo
                              setState(() {
                                _foundUser = tempUser;
                                _foundDocId = doc.id;
                                _currentStep = 1; // Pasa a la fase de credenciales
                              });
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar', style: TextStyle(color: Colors.grey))),
            ],
          );
        }
    );
  }

  // =======================================================
  // 🚀 TÁCTICA 2: CREAR CREDENCIALES Y RECLAMAR FICHA
  // =======================================================
  Future<void> _claimAccount() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedBirthDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ingresa tu fecha de nacimiento'), backgroundColor: Colors.orange));
        return;
      }

      setState(() => _isLoading = true);
      try {
        await _authService.registerUser(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          firstName: _foundUser!.firstName,
          lastName: _foundUser!.lastName,
          gender: _foundUser!.gender,
          isYSA: _foundUser!.isYSA,
          organization: _foundUser!.organization,
          callingOrganizations: _foundUser!.callingOrganizations,
          callings: _foundUser!.callings,
          ward: _foundUser!.ward,
          role: _foundUser!.role,
          username: _usernameController.text.trim().toLowerCase(),
          phone: _phoneController.text.trim(),
          birthDate: _selectedBirthDate,
        );

        await FirebaseFirestore.instance.collection('users').doc(_foundDocId).delete();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ ¡Solicitud enviada con éxito!'), backgroundColor: Colors.green));

          // 🚀 EL PASE AL VACÍO: Redirigimos a la sala de espera y destruimos el historial
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const PendingAccessScreen()),
                (route) => false,
          );
        }

      } catch (e) {
        if (mounted) showErrorDialog(context, 'Error al crear cuenta', e.toString());
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEF2F6),
      appBar: AppBar(
        title: const Text('Solicitud de Acceso', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: _brandBlue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: _currentStep == 0 ? _buildSearchPhase() : _buildClaimPhase(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // PANTALLA 1: EL BUSCADOR
  // ==========================================
  Widget _buildSearchPhase() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(Icons.search, size: 48, color: _brandBlue),
        const SizedBox(height: 10),
        Text('Busca tu Registro', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: _brandBlue), textAlign: TextAlign.center),
        const SizedBox(height: 8),
        const Text('Para registrarte, el Secretario debe haber creado tu perfil previamente.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
        const SizedBox(height: 25),

        DropdownButtonFormField<String>(
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'Barrio', border: OutlineInputBorder(), prefixIcon: Icon(Icons.location_city), isDense: true),
          value: _selectedWard,
          items: kWardsList.map((ward) => DropdownMenuItem(value: ward, child: Text(ward, overflow: TextOverflow.ellipsis))).toList(),
          onChanged: (val) => setState(() => _selectedWard = val),
        ),
        const SizedBox(height: 15),

        TextFormField(
          controller: _searchLastNameController,
          decoration: const InputDecoration(labelText: 'Tu Apellido (Paterno)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.badge), isDense: true, helperText: 'Escríbelo tal como está en los registros'),
        ),
        const SizedBox(height: 30),

        _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ElevatedButton(
          onPressed: _searchOfficialRecord,
          style: ElevatedButton.styleFrom(backgroundColor: _brandBlue, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16)),
          child: const Text('BUSCAR MI FICHA', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 10),
        TextButton(
          onPressed: () => Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen())),
          child: const Text('Volver al Login', style: TextStyle(color: Colors.grey)),
        ),
      ],
    );
  }

  // ==========================================
  // PANTALLA 2: CREACIÓN DE CREDENCIALES
  // ==========================================
  Widget _buildClaimPhase() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Tarjeta de Validación Visual
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.green.shade200)),
            child: Column(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 32),
                const SizedBox(height: 8),
                const Text('¡Ficha Encontrada!', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                const SizedBox(height: 8),
                Text('${_foundUser!.firstName} ${_foundUser!.lastName}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                Text('${_foundUser!.primaryCalling} • ${_foundUser!.organization}', style: TextStyle(color: Colors.grey.shade700, fontSize: 14), textAlign: TextAlign.center),
              ],
            ),
          ),
          const SizedBox(height: 25),

          Text('Completa tu cuenta', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: _brandBlue)),
          const Divider(),
          const SizedBox(height: 15),

          TextFormField(
            controller: _phoneController,
            decoration: const InputDecoration(labelText: 'Celular / WhatsApp', border: OutlineInputBorder(), prefixIcon: Icon(Icons.phone_android), isDense: true),
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 15),

          InkWell(
            onTap: () async {
              final picked = await showDatePicker(context: context, initialDate: DateTime(2000), firstDate: DateTime(1920), lastDate: DateTime.now(), locale: const Locale('es', 'ES'));
              if (picked != null) setState(() => _selectedBirthDate = picked);
            },
            child: InputDecorator(
              decoration: const InputDecoration(labelText: 'Fecha de Nacimiento', prefixIcon: Icon(Icons.cake), border: OutlineInputBorder(), isDense: true),
              child: Text(_selectedBirthDate == null ? 'Toca para seleccionar' : DateFormat('dd/MM/yyyy').format(_selectedBirthDate!), style: TextStyle(color: _selectedBirthDate == null ? Colors.grey : Colors.black87)),
            ),
          ),
          const SizedBox(height: 15),

          TextFormField(
            controller: _usernameController,
            decoration: const InputDecoration(labelText: 'Crear Usuario', prefixIcon: Icon(Icons.person), border: OutlineInputBorder(), isDense: true, helperText: 'Minúsculas, sin espacios (ej. juanperez)'),
            validator: (v) => v!.isEmpty ? 'Requerido' : null,
          ),
          const SizedBox(height: 15),

          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(labelText: 'Correo Electrónico', prefixIcon: Icon(Icons.email), border: OutlineInputBorder(), isDense: true),
            validator: (v) => !v!.contains('@') ? 'Correo inválido' : null,
          ),
          const SizedBox(height: 15),

          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: 'Contraseña',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.lock),
              isDense: true,
              suffixIcon: IconButton(icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off), onPressed: () => setState(() => _obscurePassword = !_obscurePassword)),
            ),
            validator: (v) => v!.length < 6 ? 'Mínimo 6 caracteres' : null,
          ),
          const SizedBox(height: 30),

          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ElevatedButton(
                onPressed: _claimAccount,
                style: ElevatedButton.styleFrom(backgroundColor: _brandBlue, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16)),
                child: const Text('SOLICITAR ACTIVACIÓN', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => setState(() { _currentStep = 0; _foundUser = null; }),
                child: const Text('No soy yo, regresar', style: TextStyle(color: Colors.grey)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}