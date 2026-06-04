import 'package:shared_preferences/shared_preferences.dart';

class PinDatabase {
  static final PinDatabase instance = PinDatabase._init();

  static const String _pinKey = 'security_pin';

  PinDatabase._init();

  Future<bool> hasPin() async {
    final prefs = await SharedPreferences.getInstance();
    final pin = prefs.getString(_pinKey);
    return pin != null && pin.isNotEmpty;
  }

  Future<void> savePin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pinKey, pin);
  }

  Future<bool> verifyPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_pinKey) == pin;
  }

  Future<void> removePin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pinKey);
  }
}
