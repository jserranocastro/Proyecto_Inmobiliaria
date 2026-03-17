import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Servicio para gestionar la persistencia de datos locales simples (SharedPreferences)
class PreferencesService {
  static const String _keyProvince = 'default_province';
  static const String _keyCity = 'default_city';

  /// Notificador global para que las pantallas reaccionen a cambios de ubicación en tiempo real
  static final ValueNotifier<Map<String, String?>> locationNotifier = 
      ValueNotifier({'province': null, 'city': null});

  /// Guarda la ubicación preferida del usuario localmente
  Future<void> setDefaultLocation(String province, String city) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyProvince, province);
    await prefs.setString(_keyCity, city);
    
    // Actualizamos el notificador para disparar reconstrucciones de UI
    locationNotifier.value = {'province': province, 'city': city};
  }

  /// Recupera la ubicación guardada o null si no existe
  Future<Map<String, String?>> getDefaultLocation() async {
    final prefs = await SharedPreferences.getInstance();
    final province = prefs.getString(_keyProvince);
    final city = prefs.getString(_keyCity);
    
    final location = {'province': province, 'city': city};
    locationNotifier.value = location; // Sincronizamos el estado actual
    return location;
  }

  /// Elimina los datos de ubicación guardados (útil al cerrar sesión)
  Future<void> clearDefaultLocation() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyProvince);
    await prefs.remove(_keyCity);
    locationNotifier.value = {'province': null, 'city': null};
  }
}
