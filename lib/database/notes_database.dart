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

  Future<void> insertNote(String date, String note) async {
    final notes = await _getStoredNotes();

    notes.add({
      'id': DateTime.now().millisecondsSinceEpoch,
      'date': date,
      'note': note.trim(),
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
}
