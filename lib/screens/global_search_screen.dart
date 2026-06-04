import 'package:flutter/material.dart';

import '../database/medications_database.dart';
import '../database/notes_database.dart';

class GlobalSearchScreen extends StatefulWidget {
  const GlobalSearchScreen({super.key});

  @override
  State<GlobalSearchScreen> createState() => _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends State<GlobalSearchScreen> {
  final searchController = TextEditingController();

  List<Map<String, dynamic>> notes = [];
  List<Map<String, dynamic>> medications = [];
  String query = '';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    searchController.addListener(() {
      setState(() => query = searchController.text.trim().toLowerCase());
    });
    loadData();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> loadData() async {
    final loadedNotes = await NotesDatabase.instance.getNotes();
    final loadedMedications =
        await MedicationsDatabase.instance.getMedications();

    if (!mounted) return;

    setState(() {
      notes = loadedNotes;
      medications = loadedMedications;
      isLoading = false;
    });
  }

  List<Map<String, dynamic>> get filteredNotes {
    if (query.isEmpty) return notes;

    return notes.where((note) {
      final text = (note['note'] as String).toLowerCase();
      final category =
          ((note['category'] as String?) ?? 'General').toLowerCase();
      final priority =
          ((note['priority'] as String?) ?? 'Normal').toLowerCase();
      final date = (note['date'] as String).toLowerCase();
      return text.contains(query) ||
          category.contains(query) ||
          priority.contains(query) ||
          date.contains(query);
    }).toList();
  }

  List<Map<String, dynamic>> get filteredMedications {
    if (query.isEmpty) return medications;

    return medications.where((medication) {
      final name = (medication['name'] as String).toLowerCase();
      final dose = (medication['dose'] as String).toLowerCase();
      final schedule = (medication['schedule'] as String).toLowerCase();
      final status =
          ((medication['status'] as String?) ?? 'Activo').toLowerCase();
      return name.contains(query) ||
          dose.contains(query) ||
          schedule.contains(query) ||
          status.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final noteResults = filteredNotes;
    final medicationResults = filteredMedications;

    return Scaffold(
      appBar: AppBar(title: const Text('Busqueda global')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      hintText: 'Buscar notas, citas o medicamentos',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: query.isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'Limpiar busqueda',
                              onPressed: searchController.clear,
                              icon: const Icon(Icons.close_rounded),
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _SectionTitle(
                    title: 'Notas y citas',
                    count: noteResults.length,
                  ),
                  const SizedBox(height: 10),
                  if (noteResults.isEmpty)
                    const _EmptySearch(text: 'No hay notas que coincidan.')
                  else
                    ...noteResults.map(
                      (note) => _ResultCard(
                        icon: Icons.event_note_outlined,
                        title: note['note'] as String,
                        subtitle:
                            '${note['date']} - ${(note['category'] as String?) ?? 'General'} - ${(note['priority'] as String?) ?? 'Normal'}',
                        color: const Color(0xFF4F46E5),
                      ),
                    ),
                  const SizedBox(height: 18),
                  _SectionTitle(
                    title: 'Medicamentos',
                    count: medicationResults.length,
                  ),
                  const SizedBox(height: 10),
                  if (medicationResults.isEmpty)
                    const _EmptySearch(
                      text: 'No hay medicamentos que coincidan.',
                    )
                  else
                    ...medicationResults.map(
                      (medication) => _ResultCard(
                        icon: Icons.medication_outlined,
                        title: medication['name'] as String,
                        subtitle:
                            '${medication['dose']} - ${medication['schedule']} - ${medication['startTime']}',
                        color: const Color(0xFF0F766E),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    required this.count,
  });

  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: Color(0xFF12312F),
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFFFEDD5),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            '$count',
            style: const TextStyle(
              color: Color(0xFFF97316),
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE7ECEA)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF12312F),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(color: Color(0xFF5F6F6B)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptySearch extends StatelessWidget {
  const _EmptySearch({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE0F7F3),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Color(0xFF12312F)),
      ),
    );
  }
}
