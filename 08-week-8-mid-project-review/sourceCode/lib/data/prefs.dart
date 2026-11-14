import 'package:shared_preferences/shared_preferences.dart';

class PrefsRepository {
  static const _darkModeKey = 'dark_mode';
  static const _lastOpenedKey = 'last_opened_at';

  Future<bool> getDarkMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_darkModeKey) ?? false;
  }

  Future<void> setDarkMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_darkModeKey, value);
  }

  static String? _previousSessionTime;

  Future<void> initLastOpened() async {
    final prefs = await SharedPreferences.getInstance();
    // Baca waktu dari sesi sebelumnya
    _previousSessionTime = prefs.getString(_lastOpenedKey);
    // Catat waktu sesi sekarang
    await prefs.setString(_lastOpenedKey, DateTime.now().toIso8601String());
  }

  Future<String?> getLastOpened() async {
    // Kembalikan waktu dari sesi sebelumnya
    return _previousSessionTime;
  }
}
