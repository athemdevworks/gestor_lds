import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gestor_lds/core/constants/wards_list.dart';
import 'package:gestor_lds/core/constants/organizations_list.dart';
import 'package:gestor_lds/features/auth/models/user_model.dart';

class FamilyHistoryListScreen extends StatefulWidget {
  final String title;
  final String fieldKey;
  final String initialWard;
  final String initialMonth;
  final String initialOrg;

  const FamilyHistoryListScreen({
    super.key,
    required this.title,
    required this.fieldKey,
    this.initialWard = 'Todos',
    this.initialMonth = '01',
    this.initialOrg = 'Todos',
  });

  @override
  State<FamilyHistoryListScreen> createState() => _FamilyHistoryListScreenState();
}

class _FamilyHistoryListScreenState extends State<FamilyHistoryListScreen> {
  final Color _brandBlue = const Color(0xFF22539A);

  UserModel? _currentUser;
  bool _isLoadingUser = true;

  late String _barrio;
  late String _mes;
  late String _org;

  final int _anioActual = DateTime.now().year;

  // 🚀 TÁCTICA 1: Diccionario de Meses amigables
  final Map<String, String> _nombresMeses = {
    '01': 'Ene', '02': 'Feb', '03': 'Mar', '04': 'Abr', '05': 'May', '06': 'Jun',
    '07': 'Jul', '08': 'Ago', '09': 'Sep', '10': 'Oct', '11': 'Nov', '12': 'Dic'
  };

  @override
  void initState() {
    super.initState();
    _barrio = widget.initialWard;
    _mes = widget.initialMonth;
    _org = widget.initialOrg;
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
        if (doc.exists) {
          final user = UserModel.fromMap(doc.data()!, doc.id);
          if (mounted) {
            setState(() {
              _currentUser = user;
              // Fuerza Bruta para asegurar que arranque en tu propio barrio
              if (_barrio == 'Todos' && !user.canSeeAllWards) {
                _barrio = user.ward;
              }
              _isLoadingUser = false;
            });
          }
          return;
        }
      }
    } catch (e) {
      debugPrint('Error cargando usuario: $e');
    }
    if (mounted) {
      setState(() => _isLoadingUser = false);
    }
  }

  void _mostrarPanelFiltros() {
    final bool esAdminEstaca = _currentUser?.canSeeAllWards ?? false;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
            builder: (BuildContext context, StateSetter setModalState) {
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('Filtrar esta lista', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _barrio,
                            decoration: InputDecoration(
                              labelText: 'Barrio',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              isDense: true,
                              filled: !esAdminEstaca,
                              fillColor: esAdminEstaca ? Colors.white : Colors.grey.shade100,
                            ),
                            items: esAdminEstaca
                                ? ['Todos', ...kWardsList].map((b) => DropdownMenuItem(value: b, child: Text(b, style: const TextStyle(fontSize: 14)))).toList()
                                : [_currentUser!.ward].map((b) => DropdownMenuItem(value: b, child: Text(b, style: const TextStyle(fontSize: 14)))).toList(),
                            onChanged: esAdminEstaca ? (val) {
                              setModalState(() => _barrio = val!);
                              setState(() {});
                            } : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _mes,
                            decoration: InputDecoration(labelText: 'Hasta el mes de', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), isDense: true),
                            // 🚀 TÁCTICA 1: Mostrar los nombres amigables de los meses
                            items: List.generate(12, (i) => (i + 1).toString().padLeft(2, '0'))
                                .map((m) => DropdownMenuItem(value: m, child: Text(_nombresMeses[m]!))).toList(),
                            onChanged: (val) {
                              setModalState(() => _mes = val!);
                              setState(() {});
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _org,
                      decoration: InputDecoration(labelText: 'Organización', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), isDense: true),
                      items: ['Todos', 'JAS', 'Hombres', 'Mujeres', 'Jóvenes', ...kOrganizationsList].map((o) => DropdownMenuItem(value: o, child: Text(o, style: const TextStyle(fontSize: 14)))).toList(),
                      onChanged: (val) {
                        setModalState(() => _org = val!);
                        setState(() {});
                      },
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: _brandBlue, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      onPressed: () => Navigator.pop(context),
                      child: const Text('CERRAR', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              );
            }
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingUser) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    Query query = FirebaseFirestore.instance.collection('users');
    if (_barrio != 'Todos') {
      query = query.where('ward', isEqualTo: _barrio);
    }

    final String keyRegistroAnio = 'registro_$_anioActual';

    return Scaffold(
      backgroundColor: const Color(0xFFEEF2F6),
      appBar: AppBar(
        title: Text(widget.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: _brandBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.filter_list_alt), onPressed: _mostrarPanelFiltros),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.white,
            child: SingleChildScrollView( // Por si la pantalla es pequeña y los tags no caben
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _tag(Icons.location_city, _barrio),
                  const SizedBox(width: 8),
                  // 🚀 TÁCTICA 1: Etiqueta más clara
                  _tag(Icons.show_chart, 'Acumulado a: ${_nombresMeses[_mes]}'),
                  if (_org != 'Todos') ...[const SizedBox(width: 8), _tag(Icons.group, _org)],
                ],
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: query.snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return Center(child: Text('No hay registros disponibles.', style: TextStyle(color: Colors.grey.shade600)));

                final filteredDocs = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;

                  // 🚀 TÁCTICA 2: Lógica Acumulativa Anual (Desde Enero hasta el Mes Seleccionado)
                  final reg = data[keyRegistroAnio] as Map<String, dynamic>? ?? {};
                  bool metaCumplidaEnElAnio = false;

                  int mesLimite = int.parse(_mes);
                  for (int i = 1; i <= mesLimite; i++) {
                    String mesAnalizado = i.toString().padLeft(2, '0');
                    final mesData = reg[mesAnalizado] as Map<String, dynamic>? ?? {};
                    if (mesData[widget.fieldKey] == true) {
                      metaCumplidaEnElAnio = true;
                      break; // Si ya lo hizo en algún mes, no hace falta seguir buscando
                    }
                  }

                  // Si revisó desde Enero hasta el mes de corte y no encontró la meta, se descarta
                  if (!metaCumplidaEnElAnio) return false;

                  final userOrg = data['organization'] ?? 'Miembro General';
                  if (_org == 'JAS' && data['isYSA'] != true) return false;
                  if (_org == 'Hombres' && data['gender'] != 'M') return false;
                  if (_org == 'Mujeres' && data['gender'] != 'F') return false;
                  if (_org == 'Jóvenes' && !['Hombres Jóvenes', 'Mujeres Jóvenes'].contains(userOrg)) return false;
                  if (kOrganizationsList.contains(_org) && userOrg != _org) return false;

                  return true;
                }).toList();

                if (filteredDocs.isEmpty) {
                  return Center(child: Text('Ningún miembro ha completado esta meta aún.', style: TextStyle(color: Colors.grey.shade600)));
                }

                filteredDocs.sort((a, b) {
                  String nameA = (a.data() as Map<String, dynamic>)['lastName'] ?? '';
                  String nameB = (b.data() as Map<String, dynamic>)['lastName'] ?? '';
                  return nameA.compareTo(nameB);
                });

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    final data = filteredDocs[index].data() as Map<String, dynamic>;
                    final isMale = data['gender'] == 'M';
                    final userOrg = data['organization'] ?? 'Miembro General';

                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isMale ? Colors.blue.shade50 : Colors.pink.shade50,
                          child: Icon(Icons.person, color: isMale ? Colors.blue : Colors.pink, size: 20),
                        ),
                        title: Text("${data['firstName']} ${data['lastName']}", style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text("${data['ward']} • $userOrg", style: const TextStyle(fontSize: 12)),
                        trailing: const Icon(Icons.check_circle, color: Colors.green, size: 20),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _tag(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: _brandBlue.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: _brandBlue),
          const SizedBox(width: 4),
          Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _brandBlue)),
        ],
      ),
    );
  }
}