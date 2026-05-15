import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../database/notes_database.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime today = DateTime.now();

  final noteController = TextEditingController();

  Map<String, String> notes = {};

  String formatDate(DateTime date) {
    return "${date.year}-${date.month}-${date.day}";
  }

  Future saveNote() async {
    String date = formatDate(today);

    await NotesDatabase.instance.insertNote(
      date,
      noteController.text,
    );

    setState(() {
      notes[date] = noteController.text;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Nota guardada'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String currentDate = formatDate(today);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendario Médico'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TableCalendar(
              focusedDay: today,
              firstDay: DateTime.utc(2020),
              lastDay: DateTime.utc(2030),
              selectedDayPredicate: (day) =>
                  isSameDay(today, day),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  today = selectedDay;
                });
              },
            ),

            const SizedBox(height: 20),

            TextField(
              controller: noteController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'Escribe tu nota médica...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: saveNote,
                child: const Text('Guardar nota'),
              ),
            ),

            const SizedBox(height: 20),

            if (notes.containsKey(currentDate))
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.teal.shade100,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Text(notes[currentDate]!),
              ),
          ],
        ),
      ),
    );
  }
}