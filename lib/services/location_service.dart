import 'package:flutter/services.dart';
import 'package:csv/csv.dart';

/// Servicio para gestionar la carga y filtrado de provincias y municipios desde un CSV
class LocationService {
  // Cache en memoria para evitar recargar el CSV constantemente
  static final Map<String, List<String>> _provinceMunicipios = {};
  
  // Mapeo de códigos de provincia INE a nombres legibles
  static final Map<String, String> _provinceNames = {
    '01': 'Álava', '02': 'Albacete', '03': 'Alicante', '04': 'Almería', '05': 'Ávila',
    '06': 'Badajoz', '07': 'Baleares', '08': 'Barcelona', '09': 'Burgos', '10': 'Cáceres',
    '11': 'Cádiz', '12': 'Castellón', '13': 'Ciudad Real', '14': 'Córdoba', '15': 'A Coruña',
    '16': 'Cuenca', '17': 'Girona', '18': 'Granada', '19': 'Guadalajara', '20': 'Gipuzkoa',
    '21': 'Huelva', '22': 'Huesca', '23': 'Jaén', '24': 'León', '25': 'Lleida',
    '26': 'La Rioja', '27': 'Lugo', '28': 'Madrid', '29': 'Málaga', '30': 'Murcia',
    '31': 'Navarra', '32': 'Ourense', '33': 'Asturias', '34': 'Palencia', '35': 'Las Palmas',
    '36': 'Pontevedra', '37': 'Salamanca', '38': 'S.C. Tenerife', '39': 'Cantabria', '40': 'Segovia',
    '41': 'Sevilla', '42': 'Soria', '43': 'Tarragona', '44': 'Teruel', '45': 'Toledo',
    '46': 'Valencia', '47': 'Valladolid', '48': 'Bizkaia', '49': 'Zamora', '50': 'Zaragoza',
    '51': 'Ceuta', '52': 'Melilla',
  };

  /// Inicializa el servicio cargando y procesando el archivo municipios.csv
  Future<void> init() async {
    if (_provinceMunicipios.isNotEmpty) return; // Ya inicializado

    // Cargamos el asset como String
    final rawData = await rootBundle.loadString('municipios.csv');
    List<List<dynamic>> listData = const CsvToListConverter().convert(rawData);

    // Iteramos el CSV saltando la cabecera
    for (var i = 1; i < listData.length; i++) {
      final row = listData[i];
      if (row.length < 3) continue;

      String municipio = row[1].toString().trim();
      String codProvincia = row[2].toString().trim().padLeft(2, '0');
      String? provinceName = _provinceNames[codProvincia];

      if (provinceName != null) {
        if (!_provinceMunicipios.containsKey(provinceName)) {
          _provinceMunicipios[provinceName] = [];
        }
        // Control de duplicados para no romper los DropdownButtons de Flutter
        if (!_provinceMunicipios[provinceName]!.contains(municipio)) {
          _provinceMunicipios[provinceName]!.add(municipio);
        }
      }
    }

    // Ordenamos alfabéticamente cada lista de municipios
    _provinceMunicipios.forEach((key, value) => value.sort());
  }

  /// Devuelve la lista ordenada de todas las provincias disponibles
  List<String> getProvinces() {
    final provinces = _provinceMunicipios.keys.toList();
    provinces.sort();
    return provinces;
  }

  /// Devuelve los municipios asociados a una provincia concreta
  List<String> getMunicipios(String province) {
    return _provinceMunicipios[province] ?? [];
  }
}
