import 'package:flutter/material.dart';
import 'package:gestor_lds/features/meetings/services/meeting_service.dart';
import 'package:intl/intl.dart';

class SpeakerListScreen extends StatefulWidget {
  const SpeakerListScreen({super.key});

  @override
  State<SpeakerListScreen> createState() => _SpeakerListScreenState();
}

class _SpeakerListScreenState extends State<SpeakerListScreen> {
  final MeetingService _meetingService = MeetingService();
  final Color _brandBlue = const Color(0xFF164772);

  int _currentYear = DateTime.now().year;

  List<MapEntry<String, List<Map<String, dynamic>>>>? _allSpeakers;
  List<MapEntry<String, List<Map<String, dynamic>>>>? _filteredSpeakers;

  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    final history = await _meetingService.getYearlySpeakerHistory(_currentYear);

    if (mounted) {
      setState(() {
        _allSpeakers = history;
        _filteredSpeakers = history;
        _isLoading = false;
      });
      if (_searchController.text.isNotEmpty) {
        _filterSpeakers(_searchController.text);
      }
    }
  }

  void _previousYear() {
    setState(() => _currentYear--);
    _loadHistory();
  }

  void _nextYear() {
    setState(() => _currentYear++);
    _loadHistory();
  }

  void _filterSpeakers(String query) {
    if (query.isEmpty) {
      setState(() => _filteredSpeakers = _allSpeakers);
      return;
    }
    final lowerQuery = query.toLowerCase();
    setState(() {
      _filteredSpeakers = _allSpeakers?.where((speaker) {
        return speaker.key.toLowerCase().contains(lowerQuery);
      }).toList();
    });
  }

  // --- PANEL INFERIOR CON FECHAS Y TEMAS ---
  void _showHistoryBottomSheet(String speakerName, List<Map<String, dynamic>> history) {
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
                speakerName,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _brandBlue),
              ),
              const SizedBox(height: 5),
              Text(
                'Discursó ${history.length} ${history.length == 1 ? "vez" : "veces"} en este año:',
                style: const TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
              ),
              const Divider(height: 20),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: history.length,
                  itemBuilder: (context, index) {
                    final data = history[index];
                    final dateStr = DateFormat('EEEE, d MMMM yyyy', 'es_ES').format(data['date']);
                    final topic = data['topic'];

                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.record_voice_over, color: Colors.blue.shade600, size: 24),
                      title: Text(
                        dateStr[0].toUpperCase() + dateStr.substring(1),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      subtitle: Text(
                        'Tema: $topic',
                        style: TextStyle(color: Colors.grey.shade700, fontStyle: FontStyle.italic),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 15),
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
        title: const Text('Historial de Discursantes'),
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
              onChanged: _filterSpeakers,
              decoration: InputDecoration(
                hintText: 'Buscar hermano(a)...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.grey),
                  onPressed: () {
                    _searchController.clear();
                    _filterSpeakers('');
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

          if (!_isLoading && _allSpeakers != null && _allSpeakers!.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              color: Colors.grey.shade50,
              child: Row(
                children: [
                  Icon(Icons.people_alt, color: Colors.grey.shade600, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Hermanos que discursaron: ${_allSpeakers!.length}',
                    style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredSpeakers == null || _filteredSpeakers!.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(_searchController.text.isNotEmpty ? Icons.search_off : Icons.mic_off, size: 60, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    _searchController.text.isNotEmpty
                        ? 'No se encontraron registros para "${_searchController.text}"'
                        : 'No hay discursantes registrados en $_currentYear.',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
                  ),
                ],
              ),
            )
                : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _filteredSpeakers!.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final speaker = _filteredSpeakers![index];

                return InkWell(
                  onTap: () => _showHistoryBottomSheet(speaker.key, speaker.value),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    leading: CircleAvatar(
                      backgroundColor: _brandBlue.withOpacity(0.1),
                      child: Icon(Icons.person, color: _brandBlue),
                    ),
                    title: Text(
                        speaker.key,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(20)
                      ),
                      child: Text(
                          '${speaker.value.length} veces',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue.shade700, fontSize: 13)
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