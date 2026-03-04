import 'package:flutter/material.dart';
import 'package:gestor_lds/features/members/models/member_model.dart';
import 'package:gestor_lds/features/members/services/member_service.dart';
import 'package:url_launcher/url_launcher.dart'; // Asegúrate de tener esto en pubspec
import 'member_form_screen.dart';

class MembersScreen extends StatefulWidget {
  const MembersScreen({super.key});

  @override
  State<MembersScreen> createState() => _MembersScreenState();
}

class _MembersScreenState extends State<MembersScreen> {
  final MemberService _memberService = MemberService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Directorio del Barrio'),
        centerTitle: true,
        backgroundColor: const Color(0xFF164772), // Azul Corporativo
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.cloud_download),
            tooltip: 'Importar Usuarios',
            onPressed: _importUsers,
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFD4AF37), // Dorado
        onPressed: () {
          // Navegar al formulario para CREAR
          Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const MemberFormScreen(),
                // 👇 AGREGADO: Ruta web para crear miembro
                settings: const RouteSettings(name: '/member-create'),
              )
          );
        },
        child: const Icon(Icons.person_add, color: Colors.black),
      ),
      body: Column(
        children: [
          // 1. BARRA DE BÚSQUEDA
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar por nombre, apellido o llamamiento...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 15),
                filled: true,
                fillColor: Colors.grey.shade100,
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
                    : null,
              ),
              onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
            ),
          ),

          // 2. LISTA DE MIEMBROS
          Expanded(
            child: FutureBuilder<List<MemberModel>>(
              future: _memberService.getMembers(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final allMembers = snapshot.data ?? [];

                // Lógica de Filtrado Local (Actualizada con nuevos campos)
                final filteredMembers = allMembers.where((m) {
                  final query = _searchQuery;
                  return m.fullName.toLowerCase().contains(query) ||
                      (m.calling?.toLowerCase().contains(query) ?? false) ||
                      m.primaryOrganization.toLowerCase().contains(query);
                }).toList();

                if (filteredMembers.isEmpty) {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.person_off, size: 60, color: Colors.grey.shade300),
                      const SizedBox(height: 10),
                      const Text('No se encontraron miembros.', style: TextStyle(color: Colors.grey)),
                    ],
                  );
                }

                return ListView.builder(
                  itemCount: filteredMembers.length,
                  padding: const EdgeInsets.only(bottom: 80), // Espacio para el FAB
                  itemBuilder: (context, index) {
                    final member = filteredMembers[index];
                    return _buildMemberCard(member);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberCard(MemberModel member) {
    final isMale = member.gender == 'M';
    final hasPhone = member.phone != null && member.phone!.isNotEmpty;

    // Construir subtítulo inteligente
    // Ej: "Cuórum de Élderes • Consejero (Primaria)"
    String subtitle = member.primaryOrganization;

    if (member.calling != null && member.calling!.isNotEmpty) {
      subtitle += " • ${member.calling}";
      // Si sirve en una org diferente a la suya, lo mostramos
      if (member.servingOrganization != null && member.servingOrganization != member.primaryOrganization) {
        subtitle += " (${member.servingOrganization})";
      }
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          // Navegar a EDITAR
          Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MemberFormScreen(memberToEdit: member),
                // 👇 AGREGADO: Ruta web para editar miembro
                settings: const RouteSettings(name: '/member-edit'),
              )
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              // AVATAR
              Stack(
                children: [
                  CircleAvatar(
                    backgroundColor: isMale ? Colors.blue.shade100 : Colors.pink.shade100,
                    radius: 24,
                    child: Text(
                      _getInitials(member.firstName, member.lastName),
                      style: TextStyle(
                          color: isMale ? Colors.blue.shade900 : Colors.pink.shade900,
                          fontWeight: FontWeight.bold,
                          fontSize: 16
                      ),
                    ),
                  ),
                  // Indicador JAS (Puntito dorado)
                  if (member.isYSA)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.star, size: 14, color: Colors.orange),
                      ),
                    )
                ],
              ),
              const SizedBox(width: 15),

              // TEXTOS
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            member.fullName,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // BOTONES DE ACCIÓN RÁPIDA
              if (hasPhone)
                IconButton(
                  icon: const Icon(Icons.message, color: Colors.green),
                  tooltip: 'WhatsApp',
                  onPressed: () => _launchWhatsApp(member.phone!),
                ),

              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  // --- LÓGICA AUXILIAR ---

  String _getInitials(String first, String last) {
    if (first.isEmpty && last.isEmpty) return '?';
    String f = first.isNotEmpty ? first[0] : '';
    String l = last.isNotEmpty ? last[0] : '';
    return (f + l).toUpperCase();
  }

  void _launchWhatsApp(String phone) async {
    // Limpieza básica del número
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final url = Uri.parse("https://wa.me/51$cleanPhone"); // Asumiendo prefijo +51 (Perú)

    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw 'No se pudo abrir WhatsApp';
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No se pudo abrir WhatsApp')));
    }
  }

  Future<void> _importUsers() async {
    bool? confirm = await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('¿Importar Usuarios?'),
          content: const Text('Se crearán fichas para los usuarios registrados que no estén en el directorio.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Importar')),
          ],
        )
    );

    if (confirm == true) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Procesando...')));

      await _memberService.importUsersToMembers();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('¡Importación completada!')));
        setState(() {});
      }
    }
  }
}