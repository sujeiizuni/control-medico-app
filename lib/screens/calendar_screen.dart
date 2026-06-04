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
  static const List<String> categories = [
    'General',
    'Sintomas',
    'Medicina',
    'Cita',
    'Estudio',
  ];

  static const List<String> priorities = ['Normal', 'Importante', 'Urgente'];

  DateTime selectedDay = DateTime.now();
  DateTime focusedDay = DateTime.now();
  CalendarFormat calendarFormat = CalendarFormat.month;

  final noteController = TextEditingController();
  final searchController = TextEditingController();
  final Map<String, List<Map<String, dynamic>>> notesByDate = {};

  String selectedCategory = categories.first;
  String selectedPriority = priorities.first;
  String searchQuery = '';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    searchController.addListener(() {
      setState(() => searchQuery = searchController.text.trim().toLowerCase());
    });
    loadNotes();
  }

  @override
  void dispose() {
    noteController.dispose();
    searchController.dispose();
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Escribe una nota primero')));
      return;
    }

    await NotesDatabase.instance.insertNote(
      formatDate(selectedDay),
      text,
      category: selectedCategory,
      priority: selectedPriority,
    );
    noteController.clear();
    setState(() {
      selectedCategory = categories.first;
      selectedPriority = priorities.first;
    });
    await loadNotes();

    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Nota guardada')));
  }

  Future<void> deleteNote(int id) async {
    await NotesDatabase.instance.deleteNote(id);
    await loadNotes();
  }

  Future<void> editNote(Map<String, dynamic> note) async {
    final textController = TextEditingController(text: note['note'] as String);
    String category = noteCategory(note);
    String priority = notePriority(note);

    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Editar nota'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: textController,
                      minLines: 3,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        hintText: 'Actualiza la nota',
                        prefixIcon: Padding(
                          padding: EdgeInsets.only(bottom: 58),
                          child: Icon(Icons.edit_note_rounded),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      initialValue: category,
                      decoration: const InputDecoration(
                        labelText: 'Tipo',
                        prefixIcon: Icon(Icons.sell_outlined),
                      ),
                      items: categories
                          .map(
                            (item) => DropdownMenuItem(
                              value: item,
                              child: Text(item),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setDialogState(() => category = value);
                      },
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      initialValue: priority,
                      decoration: const InputDecoration(
                        labelText: 'Prioridad',
                        prefixIcon: Icon(Icons.flag_outlined),
                      ),
                      items: priorities
                          .map(
                            (item) => DropdownMenuItem(
                              value: item,
                              child: Text(item),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setDialogState(() => priority = value);
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );

    if (shouldSave != true) {
      textController.dispose();
      return;
    }

    final updatedText = textController.text.trim();
    textController.dispose();

    if (updatedText.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La nota no puede quedar vacia')),
      );
      return;
    }

    await NotesDatabase.instance.updateNote(
      note['id'] as int,
      note: updatedText,
      category: category,
      priority: priority,
    );
    await loadNotes();

    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Nota actualizada')));
  }

  String noteCategory(Map<String, dynamic> note) {
    final value = note['category'] as String?;
    return categories.contains(value) ? value! : categories.first;
  }

  String notePriority(Map<String, dynamic> note) {
    final value = note['priority'] as String?;
    return priorities.contains(value) ? value! : priorities.first;
  }

  List<Map<String, dynamic>> get selectedNotes {
    return notesByDate[formatDate(selectedDay)] ?? [];
  }

  List<Map<String, dynamic>> get visibleNotes {
    if (searchQuery.isEmpty) return selectedNotes;

    return selectedNotes.where((note) {
      final text = (note['note'] as String).toLowerCase();
      final category = noteCategory(note).toLowerCase();
      final priority = notePriority(note).toLowerCase();
      return text.contains(searchQuery) ||
          category.contains(searchQuery) ||
          priority.contains(searchQuery);
    }).toList();
  }

  List<Map<String, dynamic>> markerNotes(DateTime day) {
    return notesByDate[formatDate(day)] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    final notes = selectedNotes;
    final filteredNotes = visibleNotes;

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
                        searchController.clear();
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  _SelectedDayHeader(
                    dateText: displayDate(selectedDay),
                    noteCount: notes.length,
                    urgentCount: notes
                        .where((note) => notePriority(note) == 'Urgente')
                        .length,
                  ),
                  const SizedBox(height: 14),
                  _NoteComposer(
                    noteController: noteController,
                    selectedCategory: selectedCategory,
                    selectedPriority: selectedPriority,
                    categories: categories,
                    priorities: priorities,
                    onCategoryChanged: (value) {
                      setState(() => selectedCategory = value);
                    },
                    onPriorityChanged: (value) {
                      setState(() => selectedPriority = value);
                    },
                    onSave: saveNote,
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      hintText: 'Buscar en las notas del dia',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: searchQuery.isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'Limpiar busqueda',
                              onPressed: searchController.clear,
                              icon: const Icon(Icons.close_rounded),
                            ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  if (notes.isEmpty)
                    const _EmptyNotes()
                  else if (filteredNotes.isEmpty)
                    const _NoMatches()
                  else
                    ...filteredNotes.map(
                      (note) => _NoteCard(
                        text: note['note'] as String,
                        category: noteCategory(note),
                        priority: notePriority(note),
                        onEdit: () => editNote(note),
                        onDelete: () => deleteNote(note['id'] as int),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}

class _NoteComposer extends StatelessWidget {
  const _NoteComposer({
    required this.noteController,
    required this.selectedCategory,
    required this.selectedPriority,
    required this.categories,
    required this.priorities,
    required this.onCategoryChanged,
    required this.onPriorityChanged,
    required this.onSave,
  });

  final TextEditingController noteController;
  final String selectedCategory;
  final String selectedPriority;
  final List<String> categories;
  final List<String> priorities;
  final ValueChanged<String> onCategoryChanged;
  final ValueChanged<String> onPriorityChanged;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE7ECEA)),
      ),
      child: Column(
        children: [
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
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Tipo',
                    prefixIcon: Icon(Icons.sell_outlined),
                  ),
                  items: categories
                      .map(
                        (item) =>
                            DropdownMenuItem(value: item, child: Text(item)),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    onCategoryChanged(value);
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: selectedPriority,
                  decoration: const InputDecoration(
                    labelText: 'Prioridad',
                    prefixIcon: Icon(Icons.flag_outlined),
                  ),
                  items: priorities
                      .map(
                        (item) =>
                            DropdownMenuItem(value: item, child: Text(item)),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    onPriorityChanged(value);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onSave,
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('Guardar nota del dia'),
            ),
          ),
        ],
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
    required this.urgentCount,
  });

  final String dateText;
  final int noteCount;
  final int urgentCount;

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
        _CountPill(
          text: '$noteCount notas',
          color: const Color(0xFFF97316),
          background: const Color(0xFFFFEDD5),
        ),
        if (urgentCount > 0) ...[
          const SizedBox(width: 8),
          _CountPill(
            text: '$urgentCount urg.',
            color: const Color(0xFFBE123C),
            background: const Color(0xFFFFE4E6),
          ),
        ],
      ],
    );
  }
}

class _CountPill extends StatelessWidget {
  const _CountPill({
    required this.text,
    required this.color,
    required this.background,
  });

  final String text;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _NoteCard extends StatelessWidget {
  const _NoteCard({
    required this.text,
    required this.category,
    required this.priority,
    required this.onEdit,
    required this.onDelete,
  });

  final String text;
  final String category;
  final String priority;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  Color get priorityColor {
    if (priority == 'Urgente') return const Color(0xFFBE123C);
    if (priority == 'Importante') return const Color(0xFFF97316);
    return const Color(0xFF0F766E);
  }

  Color get priorityBackground {
    if (priority == 'Urgente') return const Color(0xFFFFE4E6);
    if (priority == 'Importante') return const Color(0xFFFFEDD5);
    return const Color(0xFFE0F7F3);
  }

  IconData get categoryIcon {
    switch (category) {
      case 'Sintomas':
        return Icons.sick_outlined;
      case 'Medicina':
        return Icons.medication_outlined;
      case 'Cita':
        return Icons.event_available_outlined;
      case 'Estudio':
        return Icons.science_outlined;
      default:
        return Icons.favorite_outline;
    }
  }

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
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: priorityBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(categoryIcon, color: priorityColor, size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _Tag(text: category, color: const Color(0xFF4F46E5)),
                    _Tag(text: priority, color: priorityColor),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  text,
                  style: const TextStyle(
                    color: Color(0xFF12312F),
                    fontSize: 15,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              IconButton(
                tooltip: 'Editar nota',
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined, color: Color(0xFF4F46E5)),
              ),
              IconButton(
                tooltip: 'Eliminar nota',
                onPressed: onDelete,
                icon: const Icon(
                  Icons.delete_outline,
                  color: Color(0xFFF97316),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
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

class _NoMatches extends StatelessWidget {
  const _NoMatches();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEDD5),
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Row(
        children: [
          Icon(Icons.search_off_rounded, color: Color(0xFFF97316)),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'No hay notas que coincidan con la busqueda.',
              style: TextStyle(color: Color(0xFF12312F)),
            ),
          ),
        ],
      ),
    );
  }
}
