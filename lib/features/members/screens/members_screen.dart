import 'package:flutter/material.dart';
import 'package:gestor_lds/features/members/models/member_model.dart';
import 'package:gestor_lds/features/members/services/member_service.dart';
import 'package:gestor_lds/core/constants/wards_list.dart';
import 'package:gestor_lds/core/constants/organizations_list.dart';
import 'package:url_launcher/url_launcher.dart';
import 'member_form_screen.dart';

class MembersScreen extends StatefulWidget {
  const MembersScreen({super.key});

  @override
  State<MembersScreen> createState() => _MembersScreenState();
}

class _MembersScreenState extends State<MembersScreen> {
  final MemberService _memberService = MemberService();
  final TextEditingController _searchController = TextEditingController();

  // --- ESTADO DE FILTROS ---
  String _searchQuery = '';
  String _barrioFiltro = 'Todos';
  String _orgFiltro = 'Todos';
  String _generoFiltro = 'Todos'; // 'Todos', 'M', 'F'
  bool _soloJAS = false;

  final Color _brandBlue = const Color(0xFF22539A);
  final Color _brandGold = const Color(0xFFD4AF37);

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ==========================================
  // 🚀 PANEL DE FILTROS EMERGENTE (BOTTOM SHEET)
  // ==========================================
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
                    top: 24, left: 24, right: 24
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

                    // 1. BARRIO
                    DropdownButtonFormField<String>(
                      value: _barrioFiltro,
                      decoration: InputDecoration(labelText: 'Barrio', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), isDense: true),
                      items: ['Todos', ...kWardsList].map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
                      onChanged: (val) {
                        setModalState(() => _barrioFiltro = val!);
                        setState(() {}); // Actualiza la lista principal
                      },
                    ),
                    const SizedBox(height: 16),

                    // 2. ORGANIZACIÓN
                    DropdownButtonFormField<String>(
                      value: _orgFiltro,
                      decoration: InputDecoration(labelText: 'Organización', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), isDense: true),
                      items: ['Todos', ...kOrganizationsList].map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
                      onChanged: (val) {
                        setModalState(() => _orgFiltro = val!);
                        setState(() {});
                      },
                    ),
                    const SizedBox(height: 16),

                    // 3. GÉNERO (Usando SegmentedButton moderno)
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

                    // 4. SWITCH JAS
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
            }
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEF2F6),
      appBar: AppBar(
        title: const Text('Directorio Oficial', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: _brandBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.cloud_download),
            tooltip: 'Sincronizar Usuarios',
            onPressed: _importUsers,
          ),
          // 🚀 BOTÓN DE FILTROS EN LA BARRA SUPERIOR
          IconButton(
            icon: const Icon(Icons.filter_list_alt),
            tooltip: 'Filtros Avanzados',
            onPressed: _mostrarPanelFiltros,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: _brandGold,
        foregroundColor: Colors.black87,
        elevation: 4,
        onPressed: () {
          Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const MemberFormScreen(),
                settings: const RouteSettings(name: '/member-create'),
              )
          );
        },
        child: const Icon(Icons.person_add_alt_1),
      ),
      body: Column(
        children: [
          // ==========================================
          // 1. ZONA SUPERIOR LIMPIA (Búsqueda + Tags)
          // ==========================================
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Buscar miembro, cargo...',
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

                // 🚀 TAGS DE FILTROS ACTIVOS (Resumen Visual)
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
          ),

          // ==========================================
          // 2. LISTA DE MIEMBROS (Filtrado Maestro)
          // ==========================================
          Expanded(
            child: FutureBuilder<List<MemberModel>>(
              future: _memberService.getMembers(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

                final allMembers = snapshot.data ?? [];

                // 🚀 LÓGICA DE FILTRADO COMBINADO
                final filteredMembers = allMembers.where((m) {
                  // A. Filtro de Texto (Nombre o Llamamiento)
                  final query = _searchQuery.trim();
                  if (query.isNotEmpty) {
                    bool matchNombre = m.fullName.toLowerCase().contains(query);
                    bool matchCargo = m.calling?.toLowerCase().contains(query) ?? false;
                    if (!matchNombre && !matchCargo) return false;
                  }

                  // B. Filtro de Barrio
                  if (_barrioFiltro != 'Todos' && m.ward != _barrioFiltro) return false;

                  // C. Filtro de Organización
                  if (_orgFiltro != 'Todos' && m.primaryOrganization != _orgFiltro) return false;

                  // D. Filtro de Género
                  if (_generoFiltro != 'Todos' && m.gender != _generoFiltro) return false;

                  // E. Filtro JAS
                  if (_soloJAS && !m.isYSA) return false;

                  return true;
                }).toList();

                if (filteredMembers.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.person_search_rounded, size: 80, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text('No hay miembros con estos filtros.', style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: filteredMembers.length,
                  padding: const EdgeInsets.only(bottom: 90, top: 8),
                  itemBuilder: (context, index) {
                    return _buildMemberCard(filteredMembers[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // WIDGETS AUXILIARES
  // ==========================================

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

  // 🚀 TU TARJETA INTACTA
  Widget _buildMemberCard(MemberModel member) {
    final isMale = member.gender == 'M';
    final hasPhone = member.phone != null && member.phone!.trim().isNotEmpty;

    String subtitle = member.primaryOrganization;
    if (member.calling != null && member.calling!.isNotEmpty) {
      subtitle += " • ${member.calling}";
      if (member.servingOrganization != null && member.servingOrganization != member.primaryOrganization) {
        subtitle += " (${member.servingOrganization})";
      }
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MemberFormScreen(memberToEdit: member),
                settings: const RouteSettings(name: '/member-edit'),
              )
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              // AVATAR CON INDICADOR JAS
              Stack(
                children: [
                  CircleAvatar(
                    backgroundColor: isMale ? Colors.blue.shade50 : Colors.pink.shade50,
                    radius: 26,
                    child: Icon(
                      _getIconForOrg(member.primaryOrganization),
                      color: _getColorForOrg(member.primaryOrganization),
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

              // TEXTOS PRINCIPALES
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      member.fullName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // Etiqueta del Barrio
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(member.ward, style: TextStyle(fontSize: 10, color: Colors.grey.shade700, fontWeight: FontWeight.bold)),
                    )
                  ],
                ),
              ),

              // ACCIONES
              if (hasPhone)
                IconButton(
                  icon: const Icon(Icons.message, color: Color(0xFF25D366)),
                  tooltip: 'Enviar WhatsApp',
                  onPressed: () => _launchWhatsApp(member.phone!),
                ),
              const Icon(Icons.chevron_right_rounded, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  void _launchWhatsApp(String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final url = Uri.parse("https://wa.me/51$cleanPhone");

    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw 'No se pudo abrir WhatsApp';
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No se pudo abrir WhatsApp', style: TextStyle(color: Colors.white)), backgroundColor: Colors.red));
    }
  }

  Future<void> _importUsers() async {
    bool? confirm = await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('¿Sincronizar Usuarios?'),
          content: const Text('Se crearán fichas en el directorio para los líderes registrados en la app que aún no estén en la base de datos oficial.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: _brandBlue, foregroundColor: Colors.white),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Sincronizar'),
            ),
          ],
        )
    );

    if (confirm == true) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sincronizando datos...', style: TextStyle(color: Colors.white)), backgroundColor: Colors.blue));

      await _memberService.importUsersToMembers();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Sincronización completada exitosamente.'), backgroundColor: Colors.green));
        setState(() {}); // Refresca la lista
      }
    }
  }

  // 🚀 TUS COLORES E ÍCONOS INTACTOS
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