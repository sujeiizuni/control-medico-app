import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class NotesDatabase {
  static final NotesDatabase instance = NotesDatabase._init();

  static const String _notesKey = 'notes';

  NotesDatabase._init();

  Future<List<Map<String, dynamic>>> _getStoredNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_notesKey);

    if (data == null || data.isEmpty) return [];

    final decoded = jsonDecode(data) as List<dynamic>;
    return decoded.cast<Map<String, dynamic>>();
  }

  Future<void> _saveStoredNotes(List<Map<String, dynamic>> notes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_notesKey, jsonEncode(notes));
  }

  Future<void> insertNote(
    String date,
    String note, {
    String category = 'General',
    String priority = 'Normal',
    String? reminderTime,
    bool reminderEnabled = false,
  }) async {
    final notes = await _getStoredNotes();
    final now = DateTime.now();

    notes.add({
      'id': now.millisecondsSinceEpoch,
      'date': date,
      'note': note.trim(),
      'category': category,
      'priority': priority,
      'reminderTime': reminderTime,
      'reminderEnabled': reminderEnabled,
      'createdAt': now.toIso8601String(),
    });

    await _saveStoredNotes(notes);
  }

  Future<List<Map<String, dynamic>>> getNotes() async {
    final notes = await _getStoredNotes();
    notes.sort((a, b) => (b['id'] as int).compareTo(a['id'] as int));
    return notes;
  }

  Future<List<Map<String, dynamic>>> getNotesByDate(String date) async {
    final notes = await getNotes();
    return notes.where((note) => note['date'] == date).toList();
  }

  Future<void> deleteNote(int id) async {
    final notes = await _getStoredNotes();
    notes.removeWhere((note) => note['id'] == id);
    await _saveStoredNotes(notes);
  }

  Future<void> updateNote(
    int id, {
    required String note,
    required String category,
    required String priority,
  }) async {
    final notes = await _getStoredNotes();
    final index = notes.indexWhere((storedNote) => storedNote['id'] == id);

    if (index == -1) return;

    notes[index] = {
      ...notes[index],
      'note': note.trim(),
      'category': category,
      'priority': priority,
      'updatedAt': DateTime.now().toIso8601String(),
    };

    await _saveStoredNotes(notes);
  }
}
