import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:gestor_lds/features/auth/models/user_model.dart';
import 'package:gestor_lds/core/constants/wards_list.dart';
import 'package:gestor_lds/core/constants/organizations_list.dart';
import 'package:gestor_lds/features/members/screens/member_form_screen.dart';

class MembersScreen extends StatefulWidget {
  final bool isStakeMode;
  final UserModel currentUser;
  final int initialTabIndex;

  const MembersScreen({
    super.key,
    required this.isStakeMode,
    required this.currentUser,
    this.initialTabIndex = 0,
  });

  @override
  State<MembersScreen> createState() => _MembersScreenState();
}

class _MembersScreenState extends State<MembersScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  TabController? _tabController;

  String _searchQuery = '';
  late String _barrioFiltro;
  String _orgFiltro = 'Todos';
  String _generoFiltro = 'Todos';
  bool _soloJAS = false;

  final Color _brandBlue = const Color(0xFF22539A);
  final Color _brandGold = const Color(0xFFD4AF37);

  bool get _isAdminOrStake =>
      widget.currentUser.role == UserRole.admin ||
          widget.currentUser.role == UserRole.presidencia_estaca;

  bool get _isWardLeadership =>
      widget.currentUser.role == UserRole.obispado ||
          (widget.currentUser.callings.any((c) {
            final cLow = c.toLowerCase();
            return cLow.contains('secretario') || cLow.contains('secretaria');
          }));

  bool get _hasManagementAccess => _isAdminOrStake || _isWardLeadership;

  bool _canEditMember(UserModel target) {
    if (_isAdminOrStake) return true;
    if (_isWardLeadership && target.ward == widget.currentUser.ward) return true;
    return target.uid == widget.currentUser.uid;
  }

  @override
  void initState() {
    super.initState();
    _barrioFiltro = widget.isStakeMode ? 'Todos' : widget.currentUser.ward;
    if (_hasManagementAccess) {
      _tabController = TabController(length: 3, vsync: this, initialIndex: widget.initialTabIndex,);

    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController?.dispose();
    super.dispose();
  }

  void _mostrarPanelFiltros() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                top: 24,
                left: 24,
                right: 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Filtrar Directorio', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context))
                    ],
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: _barrioFiltro,
                    decoration: InputDecoration(
                      labelText: 'Barrio / Estaca',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      isDense: true,
                      fillColor: widget.isStakeMode ? Colors.white : Colors.grey.shade100,
                      filled: !widget.isStakeMode,
                    ),
                    items: widget.isStakeMode
                        ? ['Todos', ...kWardsList].map((b) => DropdownMenuItem(value: b, child: Text(b))).toList()
                        : [widget.currentUser.ward].map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
                    onChanged: widget.isStakeMode
                        ? (val) {
                      setModalState(() => _barrioFiltro = val!);
                      setState(() {});
                    }
                        : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _orgFiltro,
                    decoration: InputDecoration(
                      labelText: 'Organización',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      isDense: true,
                    ),
                    items: ['Todos', ...kOrganizationsList].map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
                    onChanged: (val) {
                      setModalState(() => _orgFiltro = val!);
                      setState(() {});
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text('Género:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
                  const SizedBox(height: 8),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'Todos', label: Text('Todos')),
                      ButtonSegment(value: 'M', label: Text('Hombres')),
                      ButtonSegment(value: 'F', label: Text('Mujeres')),
                    ],
                    selected: {_generoFiltro},
                    onSelectionChanged: (newSelection) {
                      setModalState(() => _generoFiltro = newSelection.first);
                      setState(() {});
                    },
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Solo Jóvenes Adultos Solteros', style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: const Text('Miembros de 18-35 años'),
                    value: _soloJAS,
                    activeColor: _brandBlue,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (val) {
                      setModalState(() => _soloJAS = val);
                      setState(() {});
                    },
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _brandBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('APLICAR FILTROS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    Query usersQuery = FirebaseFirestore.instance.collection('users');

    if (_barrioFiltro != 'Todos') {
      usersQuery = usersQuery.where('ward', isEqualTo: _barrioFiltro);
    } else if (!widget.isStakeMode) {
      usersQuery = usersQuery.where('ward', isEqualTo: widget.currentUser.ward);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFEEF2F6),
      appBar: AppBar(
        title: Text(widget.isStakeMode ? 'Directorio de Estaca' : 'Directorio de Barrio', style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: _brandBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list_alt),
            tooltip: 'Filtros Avanzados',
            onPressed: _mostrarPanelFiltros,
          ),
        ],
        bottom: _hasManagementAccess
            ? TabBar(
          controller: _tabController,
          indicatorColor: _brandGold,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'DIRECTORIO', icon: Icon(Icons.people_alt, size: 20)),
            Tab(text: 'PENDIENTES', icon: Icon(Icons.pending_actions, size: 20)),
            Tab(text: 'SIN REGISTRO', icon: Icon(Icons.app_registration, size: 20)),
          ],
        )
            : null,
      ),
      floatingActionButton: _hasManagementAccess
          ? FloatingActionButton.extended(
        backgroundColor: _brandGold,
        foregroundColor: Colors.black87,
        elevation: 4,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => MemberFormScreen(
                isStakeMode: widget.isStakeMode,
                currentUser: widget.currentUser,
              ),
              settings: const RouteSettings(name: '/member-create'),
            ),
          );
        },
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('NUEVO MIEMBRO', style: TextStyle(fontWeight: FontWeight.bold)),
      )
          : null,
      body: StreamBuilder<QuerySnapshot>(
        stream: usersQuery.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

          // Cargamos usuarios asegurando que estén activos en el sistema
          final allMembers = snapshot.data!.docs
              .map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
              .where((m) => m.isActive)
              .toList();

          if (_hasManagementAccess && _tabController != null) {
            return TabBarView(
              controller: _tabController,
              children: [
                // 1. DIRECTORIO: Todo el padrón excepto cuentas de app sin aprobar
                _buildListView(
                  allMembers.where((m) => !(m.isRegistered && !m.isApproved)).toList(),
                ),
                // 2. PENDIENTES: Solo cuentas creadas en la app esperando visto bueno
                _buildListView(
                  allMembers.where((m) => m.isRegistered && !m.isApproved).toList(),
                  isPendingTab: true,
                ),
                // 3. SIN REGISTRO: Fichas del padrón que aún no tienen cuenta en la app
                _buildListView(
                  allMembers.where((m) => !m.isRegistered).toList(),
                ),
              ],
            );
          }

          // Vista única para miembros generales (solo miembros validados)
          return _buildListView(
            allMembers.where((m) => !(m.isRegistered && !m.isApproved)).toList(),
          );
        },
      ),
    );
  }

  Widget _buildListView(List<UserModel> sourceList, {bool isPendingTab = false}) {
    final filteredMembers = sourceList.where((m) {
      final query = _searchQuery.trim();
      if (query.isNotEmpty) {
        bool matchNombre = '${m.firstName} ${m.lastName}'.toLowerCase().contains(query);
        bool matchCargo = m.primaryCalling.toLowerCase().contains(query);
        if (!matchNombre && !matchCargo) return false;
      }

      if (_orgFiltro != 'Todos' && m.organization != _orgFiltro) return false;
      if (_generoFiltro != 'Todos' && m.gender != _generoFiltro) return false;
      if (_soloJAS && !m.isYSA) return false;

      return true;
    }).toList();

    filteredMembers.sort((a, b) => a.lastName.compareTo(b.lastName));

    return Column(
      children: [
        _buildSearchBar(),
        Expanded(
          child: filteredMembers.isEmpty
              ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.person_search_rounded, size: 80, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                Text(
                  isPendingTab
                      ? 'No hay solicitudes de acceso pendientes.'
                      : 'No hay miembros con estos filtros.',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                ),
              ],
            ),
          )
              : ListView.builder(
            itemCount: filteredMembers.length,
            padding: const EdgeInsets.only(bottom: 90, top: 8),
            itemBuilder: (context, index) {
              return _buildMemberCard(filteredMembers[index], isPendingTab: isPendingTab);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Buscar miembro, cargo o llamamiento...',
              prefixIcon: Icon(Icons.search, color: _brandBlue),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 15),
              filled: true,
              fillColor: Colors.grey.shade100,
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                icon: const Icon(Icons.clear, color: Colors.grey),
                onPressed: () {
                  _searchController.clear();
                  setState(() => _searchQuery = '');
                },
              )
                  : null,
            ),
            onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
          ),
          if (_barrioFiltro != 'Todos' || _orgFiltro != 'Todos' || _generoFiltro != 'Todos' || _soloJAS) ...[
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  if (_barrioFiltro != 'Todos') _buildFiltroTag(Icons.location_city, _barrioFiltro),
                  if (_orgFiltro != 'Todos') _buildFiltroTag(Icons.group, _orgFiltro),
                  if (_generoFiltro != 'Todos') _buildFiltroTag(Icons.person, _generoFiltro == 'M' ? 'Hombres' : 'Mujeres'),
                  if (_soloJAS) _buildFiltroTag(Icons.star, 'JAS'),
                ],
              ),
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildFiltroTag(IconData icon, String text) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _brandBlue.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _brandBlue.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: _brandBlue),
          const SizedBox(width: 4),
          Text(text, style: TextStyle(fontSize: 12, color: _brandBlue, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildMemberCard(UserModel member, {bool isPendingTab = false}) {
    final isMale = member.gender == 'M';
    final hasPhone = member.phone != null && member.phone!.trim().isNotEmpty;

    String servingOrg = member.callingOrganizations.isNotEmpty ? member.callingOrganizations.first : member.organization;
    String subtitle = servingOrg;

    if (member.primaryCalling.isNotEmpty && member.primaryCalling != 'Ninguno') {
      subtitle += " • ${member.primaryCalling}";
    }

    final bool canEdit = _canEditMember(member);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          if (canEdit) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MemberFormScreen(
                  memberToEdit: member,
                  isStakeMode: widget.isStakeMode,
                  currentUser: widget.currentUser,
                ),
                settings: const RouteSettings(name: '/member-edit'),
              ),
            );
          } else {
            _showMemberDetailsModal(member);
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    backgroundColor: isMale ? Colors.blue.shade50 : Colors.pink.shade50,
                    radius: 26,
                    child: Icon(
                      _getIconForOrg(member.organization),
                      color: _getColorForOrg(member.organization),
                      size: 24,
                    ),
                  ),
                  if (member.isYSA)
                    Positioned(
                      right: -2,
                      bottom: -2,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 2)],
                        ),
                        child: Icon(Icons.star_rounded, size: 14, color: _brandGold),
                      ),
                    )
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${member.firstName} ${member.lastName}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (member.role != UserRole.miembro) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: _brandBlue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              _getShortRoleLabel(member.role),
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _brandBlue),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(4)),
                          child: Text(member.ward, style: TextStyle(fontSize: 10, color: Colors.grey.shade700, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 6),
                        if (!member.isRegistered)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.orange.shade200),
                            ),
                            child: const Text('Sin Registro App', style: TextStyle(fontSize: 10, color: Colors.orange, fontWeight: FontWeight.bold)),
                          )
                        else if (!member.isApproved)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.red.shade200),
                            ),
                            child: const Text('Pendiente Aprobación', style: TextStyle(fontSize: 10, color: Colors.red, fontWeight: FontWeight.bold)),
                          )
                      ],
                    )
                  ],
                ),
              ),

              if (isPendingTab && _hasManagementAccess)
                IconButton(
                  icon: const Icon(Icons.check_circle, color: Colors.green, size: 28),
                  tooltip: 'Aprobar Miembro',
                  onPressed: () => _approveMemberQuickly(member),
                )
              else if (hasPhone)
                IconButton(
                  icon: const Icon(Icons.message, color: Color(0xFF25D366)),
                  tooltip: 'Enviar WhatsApp',
                  onPressed: () => _launchWhatsApp(member.phone!),
                )
              else
                const SizedBox(width: 48),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _approveMemberQuickly(UserModel member) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(member.uid).update({
        'isApproved': true,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ ${member.firstName} ${member.lastName} fue aprobado(a).'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    }
  }

  void _showMemberDetailsModal(UserModel member) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: _getColorForOrg(member.organization).withOpacity(0.15),
                  radius: 28,
                  child: Icon(_getIconForOrg(member.organization), color: _getColorForOrg(member.organization), size: 28),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${member.firstName} ${member.lastName}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Text('${member.organization} • ${member.ward}', style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 25),
            const Text('Llamamientos Activos:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 6),
            if (member.callings.isEmpty || member.callings.first == 'Ninguno')
              const Text('Sin llamamientos asignados.', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic))
            else
              Wrap(
                spacing: 6,
                children: List.generate(member.callings.length, (i) {
                  final org = i < member.callingOrganizations.length ? member.callingOrganizations[i] : member.organization;
                  return Chip(label: Text('${member.callings[i]} ($org)', style: const TextStyle(fontSize: 12)));
                }),
              ),
            const SizedBox(height: 15),
            if (member.phone != null && member.phone!.isNotEmpty)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.phone, color: Colors.green),
                title: Text(member.phone!),
                subtitle: const Text('Contactar por WhatsApp'),
                onTap: () {
                  Navigator.pop(ctx);
                  _launchWhatsApp(member.phone!);
                },
              ),
            if (member.email != null && member.email!.isNotEmpty)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.email, color: Colors.blue),
                title: Text(member.email!),
                subtitle: const Text('Correo Electrónico'),
              ),
          ],
        ),
      ),
    );
  }

  void _launchWhatsApp(String phone) async {
    String clean = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (!clean.startsWith('51') && clean.length == 9) {
      clean = '51$clean';
    }
    final url = Uri.parse("https://wa.me/$clean");

    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw 'No se pudo abrir WhatsApp';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo abrir WhatsApp'), backgroundColor: Colors.red),
        );
      }
    }
  }

  String _getShortRoleLabel(UserRole role) {
    switch (role) {
      case UserRole.admin: return 'Admin';
      case UserRole.presidencia_estaca: return 'Estaca';
      case UserRole.obispado: return 'Obispado';
      case UserRole.lider_estaca: return 'Líder Estaca';
      case UserRole.lider_barrio: return 'Líder Barrio';
      case UserRole.miembro: return 'Miembro';
    }
  }

  Color _getColorForOrg(String org) {
    switch (org) {
      case 'Primaria': return Colors.yellow.shade800;
      case 'Sociedad de Socorro': return Colors.amber.shade600;
      case 'Mujeres Jóvenes': return Colors.pink.shade400;
      case 'Hombres Jóvenes': return Colors.green.shade600;
      case 'Cuórum de Élderes': return Colors.blue.shade700;
      case 'Escuela Dominical': return Colors.teal.shade600;
      case 'Templo e Historia Familiar': return Colors.cyan.shade700;
      case 'Obra Misional': return Colors.orange.shade700;
      case 'Obispado': return Colors.deepPurple.shade700;
      default: return _brandBlue;
    }
  }

  IconData _getIconForOrg(String org) {
    switch (org) {
      case 'Primaria': return Icons.child_care;
      case 'Sociedad de Socorro': return Icons.volunteer_activism;
      case 'Mujeres Jóvenes': return Icons.face_3;
      case 'Hombres Jóvenes': return Icons.face;
      case 'Cuórum de Élderes': return Icons.groups;
      case 'Escuela Dominical': return Icons.menu_book;
      case 'Templo e Historia Familiar': return Icons.account_tree;
      case 'Obra Misional': return Icons.public;
      case 'Obispado': return Icons.account_balance;
      default: return Icons.person;
    }
  }
}