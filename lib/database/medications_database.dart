import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class MedicationsDatabase {
  static final MedicationsDatabase instance = MedicationsDatabase._init();

  static const String _medicationsKey = 'medications';

  MedicationsDatabase._init();

  Future<List<Map<String, dynamic>>> _getStoredMedications() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_medicationsKey);

    if (data == null || data.isEmpty) return [];

    final decoded = jsonDecode(data) as List<dynamic>;
    return decoded.cast<Map<String, dynamic>>();
  }

  Future<void> _saveStoredMedications(
    List<Map<String, dynamic>> medications,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_medicationsKey, jsonEncode(medications));
  }

  Future<int> insertMedication({
    required String name,
    required String dose,
    required String schedule,
    required String startTime,
    required String duration,
    required bool reminderEnabled,
  }) async {
    final medications = await _getStoredMedications();
    final now = DateTime.now();
    final id = now.millisecondsSinceEpoch;

    medications.add({
      'id': id,
      'name': name.trim(),
      'dose': dose.trim(),
      'schedule': schedule,
      'startTime': startTime,
      'duration': duration.trim(),
      'status': 'Activo',
      'reminderEnabled': reminderEnabled,
      'createdAt': now.toIso8601String(),
    });

    await _saveStoredMedications(medications);
    return id;
  }

  Future<List<Map<String, dynamic>>> getMedications() async {
    final medications = await _getStoredMedications();
    medications.sort((a, b) => (b['id'] as int).compareTo(a['id'] as int));
    return medications;
  }

  Future<void> updateStatus(int id, String status) async {
    final medications = await _getStoredMedications();
    final index = medications.indexWhere((item) => item['id'] == id);

    if (index == -1) return;

    medications[index] = {
      ...medications[index],
      'status': status,
      'updatedAt': DateTime.now().toIso8601String(),
    };

    await _saveStoredMedications(medications);
  }

  Future<void> deleteMedication(int id) async {
    final medications = await _getStoredMedications();
    medications.removeWhere((item) => item['id'] == id);
    await _saveStoredMedications(medications);
  }
}
