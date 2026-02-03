import 'package:flutter/material.dart';
import '../models/property.dart';
import '../services/location_service.dart';
import 'search_results_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final LocationService _locationService = LocationService();

  String? _selectedProvince;
  String? _selectedCity;
  RangeValues _priceRange = const RangeValues(0, 1000000);
  int _minBedrooms = 0;
  int _minBathrooms = 0;
  PropertyType? _selectedType;
  bool _isForRent = true;

  List<String> _provinces = [];
  List<String> _municipios = [];
  bool _isLoadingLocations = true;

  @override
  void initState() {
    super.initState();
    _loadLocations();
  }

  Future<void> _loadLocations() async {
    await _locationService.init();
    setState(() {
      _provinces = _locationService.getProvinces();
      _isLoadingLocations = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    bool canSearch = _selectedProvince != null && _selectedCity != null;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Buscar Inmuebles'),
        surfaceTintColor: Colors.transparent,
      ),
      body: _isLoadingLocations
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Ubicación obligatoria',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0052D4)),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedProvince,
                    decoration: const InputDecoration(
                      labelText: 'Provincia *',
                      prefixIcon: Icon(Icons.map_outlined),
                    ),
                    items: _provinces.map((p) => DropdownMenuItem(value: p, child: Text(p, style: const TextStyle(fontSize: 14)))).toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedProvince = val;
                        _selectedCity = null;
                        _municipios = _locationService.getMunicipios(val!);
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedCity,
                    decoration: const InputDecoration(
                      labelText: 'Municipio *',
                      prefixIcon: Icon(Icons.location_city),
                    ),
                    disabledHint: const Text('Seleccionar provincia antes'),
                    items: _municipios.map((m) => DropdownMenuItem(value: m, child: Text(m, style: const TextStyle(fontSize: 14)))).toList(),
                    onChanged: _selectedProvince == null ? null : (val) {
                      setState(() => _selectedCity = val);
                    },
                  ),
                  const SizedBox(height: 32),
                  const Text('Filtros adicionales', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: const Center(child: Text('Alquiler')),
                          selected: _isForRent,
                          selectedColor: const Color(0xFF0052D4).withOpacity(0.2),
                          onSelected: (val) => setState(() => _isForRent = true),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ChoiceChip(
                          label: const Center(child: Text('Compra')),
                          selected: !_isForRent,
                          selectedColor: const Color(0xFF0052D4).withOpacity(0.2),
                          onSelected: (val) => setState(() => _isForRent = false),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text('Rango de precio: ${_priceRange.start.round()}€ - ${_priceRange.end.round()}€', 
                    style: const TextStyle(fontWeight: FontWeight.w500)),
                  RangeSlider(
                    values: _priceRange,
                    min: 0,
                    max: 1000000,
                    divisions: 100,
                    activeColor: const Color(0xFF0052D4),
                    onChanged: (values) => setState(() => _priceRange = values),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          value: _minBedrooms,
                          decoration: const InputDecoration(labelText: 'Hab. mín.'),
                          items: List.generate(6, (i) => DropdownMenuItem(value: i, child: Text('$i+'))),
                          onChanged: (val) => setState(() => _minBedrooms = val!),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          value: _minBathrooms,
                          decoration: const InputDecoration(labelText: 'Baños mín.'),
                          items: List.generate(4, (i) => DropdownMenuItem(value: i, child: Text('$i+'))),
                          onChanged: (val) => setState(() => _minBathrooms = val!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<PropertyType>(
                    value: _selectedType,
                    decoration: const InputDecoration(labelText: 'Tipo de inmueble'),
                    hint: const Text('Todos los tipos'),
                    items: PropertyType.values.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(type.name[0].toUpperCase() + type.name.substring(1)),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedType = val),
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: canSearch
                          ? () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => SearchResultsScreen(
                                    province: _selectedProvince!,
                                    city: _selectedCity!,
                                    priceRange: _priceRange,
                                    minBedrooms: _minBedrooms,
                                    minBathrooms: _minBathrooms,
                                    type: _selectedType,
                                    isForRent: _isForRent,
                                  ),
                                ),
                              );
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        backgroundColor: const Color(0xFF0052D4),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey[300],
                      ),
                      child: const Text('BUSCAR AHORA', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  if (!canSearch)
                    const Padding(
                      padding: EdgeInsets.only(top: 12),
                      child: Center(
                        child: Text(
                          'Selecciona provincia y municipio para buscar',
                          style: TextStyle(color: Colors.redAccent, fontSize: 12),
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}
