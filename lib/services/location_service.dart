import 'package:flutter/services.dart';
import 'package:csv/csv.dart';

class LocationService {
  static final Map<String, List<String>> _provinceMunicipios = {};
  
  // Mapa de códigos de provincia a nombres (puedes ampliarlo)
  static final Map<String, String> _provinceNames = {
    '01': 'Álava',
    '02': 'Albacete',
    '03': 'Alicante',
    '04': 'Almería',
    '05': 'Ávila',
    '06': 'Badajoz',
    '07': 'Baleares',
    '08': 'Barcelona',
    '09': 'Burgos',
    '10': 'Cáceres',
    '11': 'Cádiz',
    '12': 'Castellón',
    '13': 'Ciudad Real',
    '14': 'Córdoba',
    '15': 'A Coruña',
    '16': 'Cuenca',
    '17': 'Girona',
    '18': 'Granada',
    '19': 'Guadalajara',
    '20': 'Gipuzkoa',
    '21': 'Huelva',
    '22': 'Huesca',
    '23': 'Jaén',
    '24': 'León',
    '25': 'Lleida',
    '26': 'La Rioja',
    '27': 'Lugo',
    '28': 'Madrid',
    '29': 'Málaga',
    '30': 'Murcia',
    '31': 'Navarra',
    '32': 'Ourense',
    '33': 'Asturias',
    '34': 'Palencia',
    '35': 'Las Palmas',
    '36': 'Pontevedra',
    '37': 'Salamanca',
    '38': 'S.C. Tenerife',
    '39': 'Cantabria',
    '40': 'Segovia',
    '41': 'Sevilla',
    '42': 'Soria',
    '43': 'Tarragona',
    '44': 'Teruel',
    '45': 'Toledo',
    '46': 'Valencia',
    '47': 'Valladolid',
    '48': 'Bizkaia',
    '49': 'Zamora',
    '50': 'Zaragoza',
    '51': 'Ceuta',
    '52': 'Melilla',
  };

  Future<void> init() async {
    if (_provinceMunicipios.isNotEmpty) return;

    final rawData = await rootBundle.loadString('municipios.csv');
    List<List<dynamic>> listData = const CsvToListConverter().convert(rawData);

    // Saltamos la cabecera (Codi, Nom, Codi Província)
    for (var i = 1; i < listData.length; i++) {
      final row = listData[i];
      if (row.length < 3) continue;

      String municipio = row[1].toString();
      String codProvincia = row[2].toString().padLeft(2, '0');
      String? provinceName = _provinceNames[codProvincia];

      if (provinceName != null) {
        if (!_provinceMunicipios.containsKey(provinceName)) {
          _provinceMunicipios[provinceName] = [];
        }
        _provinceMunicipios[provinceName]!.add(municipio);
      }
    }

    // Ordenar alfabéticamente
    _provinceMunicipios.forEach((key, value) => value.sort());
  }

  List<String> getProvinces() {
    final provinces = _provinceMunicipios.keys.toList();
    provinces.sort();
    return provinces;
  }

  List<String> getMunicipios(String province) {
    return _provinceMunicipios[province] ?? [];
  }
}
