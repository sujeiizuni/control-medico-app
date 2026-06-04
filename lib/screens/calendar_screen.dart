import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../database/notes_database.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime selectedDay = DateTime.now();
  DateTime focusedDay = DateTime.now();
  CalendarFormat calendarFormat = CalendarFormat.month;

  final noteController = TextEditingController();
  final Map<String, List<Map<String, dynamic>>> notesByDate = {};

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadNotes();
  }

  @override
  void dispose() {
    noteController.dispose();
    super.dispose();
  }

  String formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  String displayDate(DateTime date) {
    return DateFormat('EEEE, d MMMM', 'es').format(date);
  }

  Future<void> loadNotes() async {
    final notes = await NotesDatabase.instance.getNotes();
    final groupedNotes = <String, List<Map<String, dynamic>>>{};

    for (final note in notes) {
      final date = note['date'] as String;
      groupedNotes.putIfAbsent(date, () => []).add(note);
    }

    if (!mounted) return;

    setState(() {
      notesByDate
        ..clear()
        ..addAll(groupedNotes);
      isLoading = false;
    });
  }

  Future<void> saveNote() async {
    final text = noteController.text.trim();

    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escribe una nota primero')),
      );
      return;
    }

    await NotesDatabase.instance.insertNote(formatDate(selectedDay), text);
    noteController.clear();
    await loadNotes();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Nota guardada')),
    );
  }

  Future<void> deleteNote(int id) async {
    await NotesDatabase.instance.deleteNote(id);
    await loadNotes();
  }

  List<Map<String, dynamic>> get selectedNotes {
    return notesByDate[formatDate(selectedDay)] ?? [];
  }

  List<Map<String, dynamic>> markerNotes(DateTime day) {
    return notesByDate[formatDate(day)] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    final notes = selectedNotes;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendario Medico'),
        actions: [
          IconButton(
            tooltip: 'Recargar notas',
            onPressed: loadNotes,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _CalendarPanel(
                    selectedDay: selectedDay,
                    focusedDay: focusedDay,
                    calendarFormat: calendarFormat,
                    markerNotes: markerNotes,
                    onFormatChanged: (format) {
                      setState(() => calendarFormat = format);
                    },
                    onDaySelected: (newSelectedDay, newFocusedDay) {
                      setState(() {
                        selectedDay = newSelectedDay;
                        focusedDay = newFocusedDay;
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  _SelectedDayHeader(
                    dateText: displayDate(selectedDay),
                    noteCount: notes.length,
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: noteController,
                    minLines: 3,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      hintText: 'Escribe sintomas, medicina, cita o pendiente...',
                      prefixIcon: Padding(
                        padding: EdgeInsets.only(bottom: 58),
                        child: Icon(Icons.edit_note_rounded),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: saveNote,
                      icon: const Icon(Icons.add_circle_outline),
                      label: const Text('Guardar nota del dia'),
                    ),
                  ),
                  const SizedBox(height: 22),
                  if (notes.isEmpty)
                    const _EmptyNotes()
                  else
                    ...notes.map(
                      (note) => _NoteCard(
                        text: note['note'] as String,
                        onDelete: () => deleteNote(note['id'] as int),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}

class _CalendarPanel extends StatelessWidget {
  const _CalendarPanel({
    required this.selectedDay,
    required this.focusedDay,
    required this.calendarFormat,
    required this.markerNotes,
    required this.onFormatChanged,
    required this.onDaySelected,
  });

  final DateTime selectedDay;
  final DateTime focusedDay;
  final CalendarFormat calendarFormat;
  final List<Map<String, dynamic>> Function(DateTime day) markerNotes;
  final void Function(CalendarFormat format) onFormatChanged;
  final void Function(DateTime selectedDay, DateTime focusedDay) onDaySelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: TableCalendar<Map<String, dynamic>>(
        locale: 'es',
        firstDay: DateTime.utc(2020),
        lastDay: DateTime.utc(2035),
        focusedDay: focusedDay,
        selectedDayPredicate: (day) => isSameDay(selectedDay, day),
        calendarFormat: calendarFormat,
        eventLoader: markerNotes,
        startingDayOfWeek: StartingDayOfWeek.monday,
        availableCalendarFormats: const {
          CalendarFormat.month: 'Mes',
          CalendarFormat.twoWeeks: '2 semanas',
          CalendarFormat.week: 'Semana',
        },
        onFormatChanged: onFormatChanged,
        onDaySelected: onDaySelected,
        headerStyle: const HeaderStyle(
          formatButtonShowsNext: false,
          titleCentered: true,
          titleTextStyle: TextStyle(
            color: Color(0xFF12312F),
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        calendarStyle: CalendarStyle(
          outsideDaysVisible: false,
          markerDecoration: const BoxDecoration(
            color: Color(0xFFF97316),
            shape: BoxShape.circle,
          ),
          todayDecoration: BoxDecoration(
            color: const Color(0xFF4F46E5).withValues(alpha: 0.18),
            shape: BoxShape.circle,
          ),
          todayTextStyle: const TextStyle(
            color: Color(0xFF4F46E5),
            fontWeight: FontWeight.w800,
          ),
          selectedDecoration: const BoxDecoration(
            color: Color(0xFF0F766E),
            shape: BoxShape.circle,
          ),
          weekendTextStyle: const TextStyle(color: Color(0xFFF97316)),
        ),
      ),
    );
  }
}

class _SelectedDayHeader extends StatelessWidget {
  const _SelectedDayHeader({
    required this.dateText,
    required this.noteCount,
  });

  final String dateText;
  final int noteCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Dia seleccionado',
                style: TextStyle(color: Color(0xFF5F6F6B), fontSize: 13),
              ),
              Text(
                dateText,
                style: const TextStyle(
                  color: Color(0xFF12312F),
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFFFEDD5),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            '$noteCount notas',
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

class _NoteCard extends StatelessWidget {
  const _NoteCard({
    required this.text,
    required this.onDelete,
  });

  final String text;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE7ECEA)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFFE0F7F3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.favorite_outline,
              color: Color(0xFF0F766E),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFF12312F),
                fontSize: 15,
                height: 1.35,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Eliminar nota',
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline, color: Color(0xFFF97316)),
          ),
        ],
      ),
    );
  }
}

class _EmptyNotes extends StatelessWidget {
  const _EmptyNotes();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFE0F7F3),
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Row(
        children: [
          Icon(Icons.event_available_outlined, color: Color(0xFF0F766E)),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'No hay notas para este dia. Agrega una para marcarlo en el calendario.',
              style: TextStyle(color: Color(0xFF12312F)),
            ),
          ),
        ],
      ),
    );
  }
}
