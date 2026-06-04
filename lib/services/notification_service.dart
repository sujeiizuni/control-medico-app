import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService instance = NotificationService._init();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _ready = false;

  NotificationService._init();

  Future<void> init() async {
    if (_ready) return;

    tz_data.initializeTimeZones();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    const settings = InitializationSettings(android: android, iOS: ios);

    await _notifications.initialize(settings);

    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    await _notifications
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    _ready = true;
  }

  Future<void> scheduleAppointment({
    required int id,
    required String title,
    required DateTime date,
    required String time,
  }) async {
    await init();
    final scheduledDate = _dateWithTime(date, time);

    if (scheduledDate.isBefore(DateTime.now())) return;

    await _notifications.zonedSchedule(
      id,
      'Cita medica',
      title,
      tz.TZDateTime.from(scheduledDate, tz.local),
      _details(),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> scheduleMedication({
    required int id,
    required String name,
    required String dose,
    required String schedule,
    required String startTime,
  }) async {
    await init();
    final times = _timesForSchedule(schedule, startTime);

    for (var index = 0; index < times.length; index++) {
      final time = times[index];
      await _notifications.zonedSchedule(
        id + index,
        'Medicamento',
        '$name - $dose',
        tz.TZDateTime.from(_nextTime(time), tz.local),
        _details(),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }
  }

  Future<void> cancelMedication(int id) async {
    for (var index = 0; index < 3; index++) {
      await _notifications.cancel(id + index);
    }
  }

  NotificationDetails _details() {
    const android = AndroidNotificationDetails(
      'medical_reminders',
      'Recordatorios medicos',
      channelDescription: 'Avisos para citas y medicamentos',
      importance: Importance.max,
      priority: Priority.high,
    );
    const ios = DarwinNotificationDetails();
    return const NotificationDetails(android: android, iOS: ios);
  }

  DateTime _dateWithTime(DateTime date, String time) {
    final parts = time.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    return DateTime(date.year, date.month, date.day, hour, minute);
  }

  DateTime _nextTime(String time) {
    final now = DateTime.now();
    var next = _dateWithTime(now, time);

    if (next.isBefore(now)) {
      next = next.add(const Duration(days: 1));
    }

    return next;
  }

  List<String> _timesForSchedule(String schedule, String startTime) {
    final first = _dateWithTime(DateTime.now(), startTime);

    if (schedule == 'Cada 8 horas') {
      return [
        _formatTime(first),
        _formatTime(first.add(const Duration(hours: 8))),
        _formatTime(first.add(const Duration(hours: 16))),
      ];
    }

    if (schedule == 'Cada 12 horas') {
      return [
        _formatTime(first),
        _formatTime(first.add(const Duration(hours: 12))),
      ];
    }

    return [startTime];
  }

  String _formatTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
