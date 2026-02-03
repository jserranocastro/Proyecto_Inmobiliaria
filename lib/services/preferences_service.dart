import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static const String _keyProvince = 'default_province';
  static const String _keyCity = 'default_city';

  Future<void> setDefaultLocation(String province, String city) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyProvince, province);
    await prefs.setString(_keyCity, city);
  }

  Future<Map<String, String?>> getDefaultLocation() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'province': prefs.getString(_keyProvince),
      'city': prefs.getString(_keyCity),
    };
  }

  Future<void> clearDefaultLocation() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyProvince);
    await prefs.remove(_keyCity);
  }
}
