import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:gestor_lds/core/constants/wards_list.dart';
import 'package:gestor_lds/features/auth/models/user_model.dart';

class AttendanceScreen extends StatefulWidget {
  final bool isStakeMode;
  final UserModel currentUser;

  const AttendanceScreen({
    super.key,
    required this.isStakeMode,
    required this.currentUser,
  });

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen>
    with SingleTickerProviderStateMixin {
  static const Color _brandBlue = Color(0xFF22539A);

  late TabController _tabController;
  late String _targetWard;

  // Controladores de Registro Dominical
  late DateTime _selectedDate;
  String _filterStatus = 'Todos'; // 'Todos', 'Presentes', 'Ausentes'
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  // Memoria compartida para ahorro de lecturas
  List<DocumentSnapshot> _cachedWardMembers = [];
  bool _isLoadingMembers = true;

  final Set<String> _presentUserIds = {};
  bool _isLoadingSession = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Si es modo estaca, seleccionamos el primer barrio real de la lista (nunca 'Estaca' ni 'Todos' para sacramental)
    if (widget.isStakeMode) {
      _targetWard = kWardsList.isNotEmpty ? kWardsList.first : widget.currentUser.ward;
    } else {
      _targetWard = widget.currentUser.ward;
    }

    _selectedDate = _getInitialSunday();
    _loadWardMembersAndSession();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  DateTime _getInitialSunday() {
    final now = DateTime.now();
    int difference = now.weekday == DateTime.sunday ? 0 : now.weekday;
    final sunday = now.subtract(Duration(days: difference));
    return DateTime(sunday.year, sunday.month, sunday.day);
  }

  String _getSessionDocId() {
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final safeWard = _targetWard.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_').toLowerCase();
    return '${safeWard}_sacramental_$dateStr';
  }

  // 🚀 CARGA ÚNICA OPTIMIZADA: Descarga los miembros del barrio una sola vez
  Future<void> _loadWardMembersAndSession() async {
    setState(() {
      _isLoadingMembers = true;
      _isLoadingSession = true;
    });

    try {
      // 1. Lectura de todo el censo del barrio seleccionado (con o sin cuenta)
      final membersSnap = await FirebaseFirestore.instance
          .collection('users')
          .where('ward', isEqualTo: _targetWard)
          .get();

      _cachedWardMembers = membersSnap.docs.where((doc) {
        final data = doc.data();
        return data['isActive'] != false; // Incluye activos y fichas sin cuenta (isRegistered: false)
      }).toList();

      // 2. Lectura de la sesión del domingo actual
      final docId = _getSessionDocId();
      final sessionDoc = await FirebaseFirestore.instance.collection('attendance_sessions').doc(docId).get();
      _presentUserIds.clear();

      if (sessionDoc.exists && sessionDoc.data() != null) {
        final List<dynamic> presentList = sessionDoc.data()!['presentUserIds'] ?? [];
        _presentUserIds.addAll(presentList.map((e) => e.toString()));
      }
    } catch (e) {
      debugPrint('Error cargando miembros o sesión: $e');
    }

    if (mounted) {
      setState(() {
        _isLoadingMembers = false;
        _isLoadingSession = false;
      });
    }
  }

  Future<void> _loadOnlySession() async {
    setState(() => _isLoadingSession = true);
    final docId = _getSessionDocId();

    try {
      final sessionDoc = await FirebaseFirestore.instance.collection('attendance_sessions').doc(docId).get();
      _presentUserIds.clear();

      if (sessionDoc.exists && sessionDoc.data() != null) {
        final List<dynamic> presentList = sessionDoc.data()!['presentUserIds'] ?? [];
        _presentUserIds.addAll(presentList.map((e) => e.toString()));
      }
    } catch (e) {
      debugPrint('Error cargando sesión dominical: $e');
    }

    if (mounted) setState(() => _isLoadingSession = false);
  }

  Future<void> _saveAttendance() async {
    setState(() => _isSaving = true);
    final docId = _getSessionDocId();

    try {
      await FirebaseFirestore.instance.collection('attendance_sessions').doc(docId).set({
        'ward': _targetWard,
        'meetingType': 'Reunión Sacramental',
        'date': Timestamp.fromDate(_selectedDate),
        'presentUserIds': _presentUserIds.toList(),
        'presentCount': _presentUserIds.length,
        'lastUpdated': FieldValue.serverTimestamp(),
        'updatedBy': '${widget.currentUser.firstName} ${widget.currentUser.lastName}'.trim(),
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Asistencia Sacramental guardada correctamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar asistencia: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEF2F6),
      appBar: AppBar(
        title: Text(
          widget.isStakeMode ? 'Reunión Sacramental (Estaca)' : 'Reunión Sacramental',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: _brandBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.amber.shade600,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(icon: Icon(Icons.home_outlined, size: 20), text: 'REUNIÓN SACRAMENTAL'),
            Tab(icon: Icon(Icons.analytics_outlined, size: 20), text: 'REPORTE MENSUAL'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Selector de Barrio estricto (solo barrios donde hay reuniones sacramentales)
          if (widget.isStakeMode)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.white,
              child: DropdownButtonFormField<String>(
                value: _targetWard,
                decoration: InputDecoration(
                  labelText: 'Seleccionar Barrio',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  isDense: true,
                  prefixIcon: const Icon(Icons.location_city),
                ),
                items: kWardsList
                    .map((b) => DropdownMenuItem(value: b, child: Text(b, style: const TextStyle(fontSize: 14))))
                    .toList(),
                onChanged: (val) {
                  if (val != null && val != _targetWard) {
                    setState(() => _targetWard = val);
                    _loadWardMembersAndSession(); // Recarga solo al cambiar de unidad
                  }
                },
              ),
            ),

          Expanded(
            child: _isLoadingMembers
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
              controller: _tabController,
              children: [
                _buildSacramentalTab(),
                _buildReporteMensualTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 1. PESTAÑA: REUNIÓN SACRAMENTAL (PASE NOMINAL)
  // ===========================================================================
  Widget _buildSacramentalTab() {
    final formattedDate = DateFormat("EEEE d 'de' MMMM, yyyy", 'es_ES').format(_selectedDate);

    // Filtro por buscador sobre los miembros en memoria
    final filteredMembers = _cachedWardMembers.where((doc) {
      if (_searchQuery.isNotEmpty) {
        final data = doc.data() as Map<String, dynamic>;
        final fName = (data['firstName'] ?? '').toString().toLowerCase();
        final lName = (data['lastName'] ?? '').toString().toLowerCase();
        return fName.contains(_searchQuery) || lName.contains(_searchQuery);
      }
      return true;
    }).toList();

    final int totalEligible = filteredMembers.length;
    final int presentCount = filteredMembers.where((m) => _presentUserIds.contains(m.id)).length;
    final double ratio = totalEligible > 0 ? presentCount / totalEligible : 0.0;

    final displayedMembers = filteredMembers.where((m) {
      final isPresent = _presentUserIds.contains(m.id);
      if (_filterStatus == 'Presentes') return isPresent;
      if (_filterStatus == 'Ausentes') return !isPresent;
      return true;
    }).toList();

    displayedMembers.sort((a, b) {
      final aData = a.data() as Map<String, dynamic>;
      final bData = b.data() as Map<String, dynamic>;
      final aName = (aData['lastName'] ?? '').toString();
      final bName = (bData['lastName'] ?? '').toString();
      return aName.compareTo(bName);
    });

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _brandBlue,
        foregroundColor: Colors.white,
        icon: _isSaving
            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Icon(Icons.save),
        label: Text(_isSaving ? 'Guardando...' : 'Guardar Asistencia', style: const TextStyle(fontWeight: FontWeight.bold)),
        onPressed: _isSaving ? null : _saveAttendance,
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime(2025),
                        lastDate: DateTime(2030),
                        selectableDayPredicate: (d) => d.weekday == DateTime.sunday,
                      );
                      if (picked != null && picked != _selectedDate) {
                        setState(() => _selectedDate = picked);
                        _loadOnlySession(); // Solo lee la sesión de 1 doc, no todos los usuarios
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: _brandBlue.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_month, color: _brandBlue, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Domingo de Reunión Sacramental', style: TextStyle(fontSize: 11, color: Colors.grey)),
                                Text(
                                  formattedDate[0].toUpperCase() + formattedDate.substring(1),
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: _brandBlue),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_drop_down, color: _brandBlue),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Buscador de miembro
          Container(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
            color: Colors.white,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar hermano(a) por nombre o apellido...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.grey),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
                    : null,
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 15),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.grey.shade100,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.pie_chart, size: 18, color: Colors.blue.shade700),
                    const SizedBox(width: 6),
                    Text(
                      '$presentCount de $totalEligible (${(ratio * 100).toStringAsFixed(0)}%)',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blue.shade900),
                    ),
                  ],
                ),
                Row(
                  children: [
                    _buildStatusChip('Todos'),
                    const SizedBox(width: 4),
                    _buildStatusChip('Presentes'),
                    const SizedBox(width: 4),
                    _buildStatusChip('Ausentes'),
                  ],
                ),
              ],
            ),
          ),

          Expanded(
            child: _isLoadingSession
                ? const Center(child: CircularProgressIndicator())
                : displayedMembers.isEmpty
                ? Center(
              child: Text(
                'No hay miembros con el filtro: $_filterStatus',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 80),
              itemCount: displayedMembers.length,
              itemBuilder: (context, index) {
                final doc = displayedMembers[index];
                final data = doc.data() as Map<String, dynamic>;
                final String uid = doc.id;
                final String fullName = '${data['firstName'] ?? ''} ${data['lastName'] ?? ''}'.trim();
                final String calling = data['primaryCalling'] ?? data['organization'] ?? 'Miembro';
                final String? phone = data['phone'];
                final bool isPresent = _presentUserIds.contains(uid);

                return Card(
                  elevation: 1.5,
                  margin: const EdgeInsets.only(bottom: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        if (isPresent) {
                          _presentUserIds.remove(uid);
                        } else {
                          _presentUserIds.add(uid);
                        }
                      });
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      child: Row(
                        children: [
                          Checkbox(
                            value: isPresent,
                            activeColor: Colors.green.shade700,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                            onChanged: (val) {
                              setState(() {
                                if (val == true) {
                                  _presentUserIds.add(uid);
                                } else {
                                  _presentUserIds.remove(uid);
                                }
                              });
                            },
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  fullName,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: isPresent ? Colors.black87 : Colors.grey.shade800,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  calling,
                                  style: TextStyle(color: Colors.grey.shade600, fontSize: 11.5),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          if (!isPresent && phone != null && phone.trim().isNotEmpty)
                            IconButton(
                              icon: const Icon(Icons.message, color: Color(0xFF25D366), size: 20),
                              tooltip: 'Escribir por WhatsApp',
                              onPressed: () => _sendPastoralMessage(phone, fullName),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 2. PESTAÑA: REPORTE MENSUAL (REUTILIZA MIEMBROS EN MEMORIA)
  // ===========================================================================
  Widget _buildReporteMensualTab() {
    // 🚀 CONSULTA ULTRALIGERA: Solo lee los documentos de las sesiones (4 o 5 docs), sin volver a consultar users
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('attendance_sessions')
          .where('ward', isEqualTo: _targetWard)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error al cargar reporte: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
        }

        final rawDocs = snapshot.data?.docs ?? [];

        // Filtrado y ordenamiento en memoria para no requerir índices compuestos
        final sessionDocs = rawDocs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return data['meetingType'] == 'Reunión Sacramental' && data['date'] != null;
        }).toList();

        sessionDocs.sort((a, b) {
          final aDate = (a.data() as Map<String, dynamic>)['date'] as Timestamp;
          final bDate = (b.data() as Map<String, dynamic>)['date'] as Timestamp;
          return bDate.compareTo(aDate);
        });

        final recentSessions = sessionDocs.take(5).toList();

        if (recentSessions.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.calendar_today_outlined, size: 60, color: Colors.grey.shade300),
                  const SizedBox(height: 12),
                  Text(
                    'No hay reuniones sacramentales guardadas para Barrio $_targetWard.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ],
              ),
            ),
          );
        }

        final int totalSessions = recentSessions.length;

        // Conteo de asistencias usando la lista de miembros ya cargada en memoria (_cachedWardMembers)
        final Map<String, int> attendanceCounts = {};
        for (var s in recentSessions) {
          final data = s.data() as Map<String, dynamic>;
          final List<dynamic> presentIds = data['presentUserIds'] ?? [];
          for (var uid in presentIds) {
            final uidStr = uid.toString();
            attendanceCounts[uidStr] = (attendanceCounts[uidStr] ?? 0) + 1;
          }
        }

        final List<DocumentSnapshot> sinAsistencia = [];
        final List<DocumentSnapshot> siempreAsisten = [];
        final List<DocumentSnapshot> intermitentes = [];

        for (var u in _cachedWardMembers) {
          final int count = attendanceCounts[u.id] ?? 0;
          if (count == 0) {
            sinAsistencia.add(u);
          } else if (count == totalSessions) {
            siempreAsisten.add(u);
          } else {
            intermitentes.add(u);
          }
        }

        return DefaultTabController(
          length: 3,
          child: Column(
            children: [
              Container(
                color: Colors.white,
                child: TabBar(
                  labelColor: _brandBlue,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: _brandBlue,
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  tabs: [
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 16),
                          const SizedBox(width: 4),
                          Text('Sin Asistencia (${sinAsistencia.length})'),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.verified, color: Colors.green, size: 16),
                          const SizedBox(width: 4),
                          Text('Siempre (${siempreAsisten.length})'),
                        ],
                      ),
                    ),
                    Tab(text: 'Intermitentes (${intermitentes.length})'),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: Colors.blue.shade50.withOpacity(0.5),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, size: 16, color: _brandBlue),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Evaluando las últimas $totalSessions reuniones en Barrio $_targetWard (${_cachedWardMembers.length} miembros evaluados).',
                        style: const TextStyle(fontSize: 12, color: _brandBlue, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _buildReportList(sinAsistencia, attendanceCounts, totalSessions, isRedAlert: true),
                    _buildReportList(siempreAsisten, attendanceCounts, totalSessions, isPerfect: true),
                    _buildReportList(intermitentes, attendanceCounts, totalSessions),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildReportList(
      List<DocumentSnapshot> members,
      Map<String, int> counts,
      int totalSessions, {
        bool isRedAlert = false,
        bool isPerfect = false,
      }) {
    if (members.isEmpty) {
      return Center(
        child: Text(
          isRedAlert ? '¡Excelente! Todos los miembros asistieron al menos una vez.' : 'No hay hermanos en esta lista.',
          style: const TextStyle(color: Colors.grey, fontSize: 14),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(14),
      itemCount: members.length,
      itemBuilder: (context, index) {
        final doc = members[index];
        final data = doc.data() as Map<String, dynamic>;
        final String fullName = '${data['firstName'] ?? ''} ${data['lastName'] ?? ''}'.trim();
        final String calling = data['primaryCalling'] ?? data['organization'] ?? 'Miembro';
        final String? phone = data['phone'];
        final int attended = counts[doc.id] ?? 0;

        return Card(
          elevation: 1.5,
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: isRedAlert
                ? BorderSide(color: Colors.red.shade300, width: 1.2)
                : (isPerfect ? BorderSide(color: Colors.green.shade300, width: 1.2) : BorderSide.none),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            leading: CircleAvatar(
              backgroundColor: isRedAlert
                  ? Colors.red.shade50
                  : (isPerfect ? Colors.green.shade50 : Colors.blue.shade50),
              child: Icon(
                isRedAlert
                    ? Icons.person_off_outlined
                    : (isPerfect ? Icons.star_rounded : Icons.person_outline),
                color: isRedAlert
                    ? Colors.red.shade700
                    : (isPerfect ? Colors.green.shade700 : _brandBlue),
              ),
            ),
            title: Text(fullName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: Text(
              '$calling • Asistió $attended de $totalSessions domingos',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            trailing: phone != null && phone.trim().isNotEmpty
                ? IconButton(
              icon: const Icon(Icons.message, color: Color(0xFF25D366)),
              tooltip: 'Escribir por WhatsApp',
              onPressed: () {
                final msg = isRedAlert
                    ? 'Hola $fullName, le saludamos con mucho aprecio. Queríamos saber cómo se encuentra usted y su familia, le hemos extrañado mucho en el barrio estos domingos.'
                    : 'Hola $fullName, le saludamos con aprecio y le agradecemos por su fiel asistencia y ejemplo en la reunión sacramental.';
                _sendCustomWhatsApp(phone, msg);
              },
            )
                : null,
          ),
        );
      },
    );
  }

  Widget _buildStatusChip(String label) {
    final bool isSelected = _filterStatus == label;
    return InkWell(
      onTap: () => setState(() => _filterStatus = label),
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? _brandBlue : Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: isSelected ? _brandBlue : Colors.grey.shade300),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }

  void _sendPastoralMessage(String phone, String name) async {
    final text = 'Hola $name, esperamos que te encuentres muy bien. Te extrañamos hoy en nuestra Reunión Sacramental. ¡Que tengas una bendecida semana!';
    _sendCustomWhatsApp(phone, text);
  }

  void _sendCustomWhatsApp(String phone, String text) async {
    String clean = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (!clean.startsWith('51') && clean.length == 9) clean = '51$clean';
    final uri = Uri.parse('https://wa.me/$clean?text=${Uri.encodeComponent(text)}');

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }
}