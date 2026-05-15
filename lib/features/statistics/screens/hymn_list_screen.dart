import 'package:flutter/material.dart';
import 'package:gestor_lds/features/meetings/services/meeting_service.dart';
import 'package:intl/intl.dart';

class HymnListScreen extends StatefulWidget {
  const HymnListScreen({super.key});

  @override
  State<HymnListScreen> createState() => _HymnListScreenState();
}

class _HymnListScreenState extends State<HymnListScreen> {
  final MeetingService _meetingService = MeetingService();
  final Color _brandBlue = const Color(0xFF22539A);

  int _currentYear = DateTime.now().year;

  // ¡ATENCIÓN! Cambió el tipo de int a List<DateTime>
  List<MapEntry<String, List<DateTime>>>? _allHymns;
  List<MapEntry<String, List<DateTime>>>? _filteredHymns;

  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRanking();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadRanking() async {
    setState(() => _isLoading = true);
    final ranking = await _meetingService.getYearlyHymnRanking(_currentYear);

    if (mounted) {
      setState(() {
        _allHymns = ranking;
        _filteredHymns = ranking;
        _isLoading = false;
      });
      if (_searchController.text.isNotEmpty) {
        _filterHymns(_searchController.text);
      }
    }
  }

  void _previousYear() {
    setState(() => _currentYear--);
    _loadRanking();
  }

  void _nextYear() {
    setState(() => _currentYear++);
    _loadRanking();
  }

  void _filterHymns(String query) {
    if (query.isEmpty) {
      setState(() => _filteredHymns = _allHymns);
      return;
    }
    final lowerQuery = query.toLowerCase();
    setState(() {
      _filteredHymns = _allHymns?.where((hymn) {
        return hymn.key.toLowerCase().contains(lowerQuery);
      }).toList();
    });
  }

  // --- NUEVA FUNCIÓN: PANEL INFERIOR CON FECHAS ---
  void _showDatesBottomSheet(String hymnName, List<DateTime> dates) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                hymnName,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _brandBlue),
              ),
              const SizedBox(height: 5),
              Text(
                'Se cantó ${dates.length} ${dates.length == 1 ? "vez" : "veces"} en este año:',
                style: const TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
              ),
              const Divider(height: 30),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: dates.length,
                  itemBuilder: (context, index) {
                    final dateStr = DateFormat('EEEE, d MMMM yyyy', 'es_ES').format(dates[index]);
                    return ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.event_available, color: Colors.green.shade600, size: 20),
                      title: Text(
                        // Ponemos la primera letra del día en mayúscula
                        dateStr[0].toUpperCase() + dateStr.substring(1),
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cerrar'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de Himnos'),
        backgroundColor: _brandBlue,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(color: Colors.white),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(icon: const Icon(Icons.chevron_left, size: 30), onPressed: _previousYear, color: _brandBlue),
                Text('AÑO $_currentYear', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _brandBlue, letterSpacing: 1.5)),
                IconButton(icon: const Icon(Icons.chevron_right, size: 30), onPressed: _nextYear, color: _brandBlue),
              ],
            ),
          ),

          Container(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 4, offset: const Offset(0, 2))],
            ),
            child: TextField(
              controller: _searchController,
              onChanged: _filterHymns,
              decoration: InputDecoration(
                hintText: 'Buscar por número o título...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.grey),
                  onPressed: () {
                    _searchController.clear();
                    _filterHymns('');
                  },
                )
                    : null,
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          if (!_isLoading && _allHymns != null && _allHymns!.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              color: Colors.grey.shade50,
              child: Row(
                children: [
                  Icon(Icons.library_music, color: Colors.grey.shade600, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Himnos distintos cantados: ${_allHymns!.length}',
                    style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredHymns == null || _filteredHymns!.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(_searchController.text.isNotEmpty ? Icons.search_off : Icons.music_off, size: 60, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    _searchController.text.isNotEmpty
                        ? 'No se encontraron himnos con "${_searchController.text}"'
                        : 'No hay himnos registrados en $_currentYear.',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
                  ),
                ],
              ),
            )
                : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _filteredHymns!.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final hymn = _filteredHymns![index];

                // --- AGREGAMOS EL INKWELL/ONTAP AL LIST TILE ---
                return InkWell(
                  onTap: () => _showDatesBottomSheet(hymn.key, hymn.value),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    leading: Icon(Icons.music_note, color: _brandBlue.withOpacity(0.7)),
                    title: Text(
                        hymn.key,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                          color: _brandBlue.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(20)
                      ),
                      child: Text(
                          '${hymn.value.length} veces',
                          style: TextStyle(fontWeight: FontWeight.bold, color: _brandBlue, fontSize: 13)
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
}