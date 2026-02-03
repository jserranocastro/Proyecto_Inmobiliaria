import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static const String _keyProvince = 'default_province';
  static const String _keyCity = 'default_city';

  // Notificador para que las pantallas se enteren de cambios en tiempo real
  static final ValueNotifier<Map<String, String?>> locationNotifier = 
      ValueNotifier({'province': null, 'city': null});

  Future<void> setDefaultLocation(String province, String city) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyProvince, province);
    await prefs.setString(_keyCity, city);
    locationNotifier.value = {'province': province, 'city': city};
  }

  Future<Map<String, String?>> getDefaultLocation() async {
    final prefs = await SharedPreferences.getInstance();
    final province = prefs.getString(_keyProvince);
    final city = prefs.getString(_keyCity);
    
    final location = {'province': province, 'city': city};
    locationNotifier.value = location;
    return location;
  }

  Future<void> clearDefaultLocation() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyProvince);
    await prefs.remove(_keyCity);
    locationNotifier.value = {'province': null, 'city': null};
  }
}
