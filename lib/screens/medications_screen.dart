import 'package:flutter/material.dart';

import '../database/medications_database.dart';
import '../services/notification_service.dart';

class MedicationsScreen extends StatefulWidget {
  const MedicationsScreen({super.key});

  @override
  State<MedicationsScreen> createState() => _MedicationsScreenState();
}

class _MedicationsScreenState extends State<MedicationsScreen> {
  static const List<String> schedules = [
    'Diario',
    'Cada 8 horas',
    'Cada 12 horas',
  ];

  final nameController = TextEditingController();
  final doseController = TextEditingController();
  final durationController = TextEditingController();

  List<Map<String, dynamic>> medications = [];
  String selectedSchedule = schedules.first;
  TimeOfDay selectedTime = const TimeOfDay(hour: 8, minute: 0);
  bool reminderEnabled = true;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadMedications();
  }

  @override
  void dispose() {
    nameController.dispose();
    doseController.dispose();
    durationController.dispose();
    super.dispose();
  }

  Future<void> loadMedications() async {
    final data = await MedicationsDatabase.instance.getMedications();

    if (!mounted) return;

    setState(() {
      medications = data;
      isLoading = false;
    });
  }

  Future<void> pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: selectedTime,
    );

    if (time == null) return;

    setState(() => selectedTime = time);
  }

  Future<void> saveMedication() async {
    final name = nameController.text.trim();
    final dose = doseController.text.trim();
    final duration = durationController.text.trim();

    if (name.isEmpty || dose.isEmpty || duration.isEmpty) {
      showMessage('Completa nombre, dosis y duracion');
      return;
    }

    final startTime = formatTime(selectedTime);
    final id = await MedicationsDatabase.instance.insertMedication(
      name: name,
      dose: dose,
      schedule: selectedSchedule,
      startTime: startTime,
      duration: duration,
      reminderEnabled: reminderEnabled,
    );

    if (reminderEnabled) {
      await NotificationService.instance.scheduleMedication(
        id: id,
        name: name,
        dose: dose,
        schedule: selectedSchedule,
        startTime: startTime,
      );
    }

    nameController.clear();
    doseController.clear();
    durationController.clear();
    setState(() {
      selectedSchedule = schedules.first;
      selectedTime = const TimeOfDay(hour: 8, minute: 0);
      reminderEnabled = true;
    });
    await loadMedications();
    showMessage('Medicamento guardado');
  }

  Future<void> toggleStatus(Map<String, dynamic> medication) async {
    final id = medication['id'] as int;
    final currentStatus = medicationStatus(medication);
    final nextStatus = currentStatus == 'Activo' ? 'Finalizado' : 'Activo';

    await MedicationsDatabase.instance.updateStatus(id, nextStatus);

    if (nextStatus == 'Finalizado') {
      await NotificationService.instance.cancelMedication(id);
    } else if (medication['reminderEnabled'] == true) {
      await NotificationService.instance.scheduleMedication(
        id: id,
        name: medication['name'] as String,
        dose: medication['dose'] as String,
        schedule: medication['schedule'] as String,
        startTime: medication['startTime'] as String,
      );
    }

    await loadMedications();
  }

  Future<void> deleteMedication(Map<String, dynamic> medication) async {
    final id = medication['id'] as int;
    await MedicationsDatabase.instance.deleteMedication(id);
    await NotificationService.instance.cancelMedication(id);
    await loadMedications();
  }

  String medicationStatus(Map<String, dynamic> medication) {
    return (medication['status'] as String?) ?? 'Activo';
  }

  String formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  void showMessage(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Medicamentos')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _MedicationForm(
                    nameController: nameController,
                    doseController: doseController,
                    durationController: durationController,
                    selectedSchedule: selectedSchedule,
                    selectedTime: formatTime(selectedTime),
                    reminderEnabled: reminderEnabled,
                    schedules: schedules,
                    onScheduleChanged: (value) {
                      setState(() => selectedSchedule = value);
                    },
                    onReminderChanged: (value) {
                      setState(() => reminderEnabled = value);
                    },
                    onPickTime: pickTime,
                    onSave: saveMedication,
                  ),
                  const SizedBox(height: 22),
                  const Text(
                    'Tratamientos',
                    style: TextStyle(
                      color: Color(0xFF12312F),
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (medications.isEmpty)
                    const _EmptyMedications()
                  else
                    ...medications.map(
                      (medication) => _MedicationCard(
                        name: medication['name'] as String,
                        dose: medication['dose'] as String,
                        schedule: medication['schedule'] as String,
                        startTime: medication['startTime'] as String,
                        duration: medication['duration'] as String,
                        status: medicationStatus(medication),
                        reminderEnabled: medication['reminderEnabled'] == true,
                        onToggleStatus: () => toggleStatus(medication),
                        onDelete: () => deleteMedication(medication),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}

class _MedicationForm extends StatelessWidget {
  const _MedicationForm({
    required this.nameController,
    required this.doseController,
    required this.durationController,
    required this.selectedSchedule,
    required this.selectedTime,
    required this.reminderEnabled,
    required this.schedules,
    required this.onScheduleChanged,
    required this.onReminderChanged,
    required this.onPickTime,
    required this.onSave,
  });

  final TextEditingController nameController;
  final TextEditingController doseController;
  final TextEditingController durationController;
  final String selectedSchedule;
  final String selectedTime;
  final bool reminderEnabled;
  final List<String> schedules;
  final ValueChanged<String> onScheduleChanged;
  final ValueChanged<bool> onReminderChanged;
  final VoidCallback onPickTime;
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
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'Medicamento',
              prefixIcon: Icon(Icons.medication_outlined),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: doseController,
            decoration: const InputDecoration(
              labelText: 'Dosis',
              prefixIcon: Icon(Icons.local_pharmacy_outlined),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: selectedSchedule,
                  decoration: const InputDecoration(
                    labelText: 'Frecuencia',
                    prefixIcon: Icon(Icons.repeat_rounded),
                  ),
                  items: schedules
                      .map(
                        (item) =>
                            DropdownMenuItem(value: item, child: Text(item)),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    onScheduleChanged(value);
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onPickTime,
                  icon: const Icon(Icons.schedule_outlined),
                  label: Text(selectedTime),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: durationController,
            decoration: const InputDecoration(
              labelText: 'Duracion',
              hintText: 'Ej. 7 dias',
              prefixIcon: Icon(Icons.date_range_outlined),
            ),
          ),
          const SizedBox(height: 6),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: reminderEnabled,
            onChanged: onReminderChanged,
            title: const Text('Activar recordatorio'),
            secondary: const Icon(Icons.notifications_active_outlined),
          ),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onSave,
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('Guardar medicamento'),
            ),
          ),
        ],
      ),
    );
  }
}

class _MedicationCard extends StatelessWidget {
  const _MedicationCard({
    required this.name,
    required this.dose,
    required this.schedule,
    required this.startTime,
    required this.duration,
    required this.status,
    required this.reminderEnabled,
    required this.onToggleStatus,
    required this.onDelete,
  });

  final String name;
  final String dose;
  final String schedule;
  final String startTime;
  final String duration;
  final String status;
  final bool reminderEnabled;
  final VoidCallback onToggleStatus;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final isActive = status == 'Activo';

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
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color:
                  isActive ? const Color(0xFFE0F7F3) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.medication_liquid_outlined,
              color:
                  isActive ? const Color(0xFF0F766E) : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: Color(0xFF12312F),
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$dose - $schedule - $startTime',
                  style: const TextStyle(color: Color(0xFF5F6F6B)),
                ),
                const SizedBox(height: 4),
                Text(
                  duration,
                  style: const TextStyle(color: Color(0xFF5F6F6B)),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _ChipLabel(
                      text: status,
                      color: isActive
                          ? const Color(0xFF0F766E)
                          : const Color(0xFF64748B),
                    ),
                    if (reminderEnabled)
                      const _ChipLabel(
                        text: 'Recordatorio',
                        color: Color(0xFF4F46E5),
                      ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            children: [
              IconButton(
                tooltip: isActive ? 'Finalizar' : 'Reactivar',
                onPressed: onToggleStatus,
                icon: Icon(
                  isActive
                      ? Icons.check_circle_outline
                      : Icons.restart_alt_rounded,
                  color: const Color(0xFF0F766E),
                ),
              ),
              IconButton(
                tooltip: 'Eliminar',
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

class _ChipLabel extends StatelessWidget {
  const _ChipLabel({
    required this.text,
    required this.color,
  });

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

class _EmptyMedications extends StatelessWidget {
  const _EmptyMedications();

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
          Icon(Icons.medication_outlined, color: Color(0xFF0F766E)),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Agrega tu primer medicamento para controlar dosis y horarios.',
              style: TextStyle(color: Color(0xFF12312F)),
            ),
          ),
        ],
      ),
    );
  }
}
