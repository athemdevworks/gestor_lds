import 'package:flutter/material.dart';
import 'package:gestor_lds/features/members/models/member_model.dart';
import 'package:gestor_lds/features/members/services/member_service.dart';
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
        actions: [
          IconButton(
            icon: const Icon(Icons.cloud_download),
            tooltip: 'Importar Usuarios',
            onPressed: () async {
              // Confirmación de seguridad
              bool? confirm = await showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('¿Importar Usuarios?'),
                    content: const Text('Esto creará fichas de miembro para todos los usuarios que tengan cuenta y aún no estén en el directorio.'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
                      ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Importar')),
                    ],
                  )
              );

              if (confirm == true) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Procesando...')));
                await _memberService.importUsersToMembers();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('¡Importación Lista! Recarga la pantalla.')));
                setState(() {}); // Recargar lista
              }
            },
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navegar al formulario para CREAR (sin pasar miembro)
          Navigator.push(context, MaterialPageRoute(builder: (_) => const MemberFormScreen()));
        },
        child: const Icon(Icons.person_add),
      ),
      body: Column(
        children: [
          // 1. BARRA DE BÚSQUEDA
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar por nombre o apellido...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
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
            child: StreamBuilder<List<MemberModel>>(
              stream: _memberService.getMembers(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return const Center(child: Text('Error al cargar miembros'));
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final allMembers = snapshot.data ?? [];

                // Lógica de Filtrado Local
                final filteredMembers = allMembers.where((m) {
                  return m.fullName.toLowerCase().contains(_searchQuery) ||
                      (m.calling?.toLowerCase().contains(_searchQuery) ?? false);
                }).toList();

                if (filteredMembers.isEmpty) {
                  return const Center(child: Text('No se encontraron miembros.', style: TextStyle(color: Colors.grey)));
                }

                return ListView.builder(
                  itemCount: filteredMembers.length,
                  itemBuilder: (context, index) {
                    final member = filteredMembers[index];
                    final isMale = member.gender == 'M';

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      elevation: 1,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isMale ? Colors.indigo.shade100 : Colors.pink.shade100,
                          child: Text(
                            _getInitials(member.firstName, member.lastName),
                            style: TextStyle(
                                color: isMale ? Colors.indigo.shade800 : Colors.pink.shade800,
                                fontWeight: FontWeight.bold
                            ),
                          ),
                        ),
                        title: Text(member.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${member.organization} ${member.calling != null ? "• ${member.calling}" : ""}'),
                        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                        onTap: () {
                          // Navegar al formulario para EDITAR (pasando el miembro)
                          Navigator.push(context, MaterialPageRoute(
                            builder: (_) => MemberFormScreen(memberToEdit: member),
                          ));
                        },
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

  String _getInitials(String first, String last) {
    if (first.isEmpty && last.isEmpty) return '?';
    String f = first.isNotEmpty ? first[0] : '';
    String l = last.isNotEmpty ? last[0] : '';
    return (f + l).toUpperCase();
  }
}