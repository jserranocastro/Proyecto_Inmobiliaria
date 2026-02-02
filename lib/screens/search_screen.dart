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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buscar Inmuebles'),
      ),
      body: _isLoadingLocations
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Desplegable de Provincia
                  DropdownButtonFormField<String>(
                    value: _selectedProvince,
                    decoration: const InputDecoration(
                      labelText: 'Provincia',
                      prefixIcon: Icon(Icons.map_outlined),
                      border: OutlineInputBorder(),
                    ),
                    hint: const Text('Todas las provincias'),
                    items: _provinces.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedProvince = val;
                        _selectedCity = null;
                        _municipios = _locationService.getMunicipios(val!);
                      });
                    },
                  ),
                  const SizedBox(height: 15),
                  // Desplegable de Municipio
                  DropdownButtonFormField<String>(
                    value: _selectedCity,
                    decoration: const InputDecoration(
                      labelText: 'Municipio',
                      prefixIcon: Icon(Icons.location_city),
                      border: OutlineInputBorder(),
                    ),
                    hint: const Text('Todos los municipios'),
                    disabledHint: const Text('Selecciona una provincia primero'),
                    items: _municipios.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                    onChanged: _selectedProvince == null ? null : (val) {
                      setState(() => _selectedCity = val);
                    },
                  ),
                  const SizedBox(height: 25),
                  const Text('Rango de precio (€)', style: TextStyle(fontWeight: FontWeight.bold)),
                  RangeSlider(
                    values: _priceRange,
                    min: 0,
                    max: 1000000,
                    divisions: 20,
                    labels: RangeLabels(
                      '${_priceRange.start.round()} €',
                      '${_priceRange.end.round()} €',
                    ),
                    onChanged: (values) => setState(() => _priceRange = values),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: const Center(child: Text('Alquiler')),
                          selected: _isForRent,
                          onSelected: (val) => setState(() => _isForRent = true),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ChoiceChip(
                          label: const Center(child: Text('Compra')),
                          selected: !_isForRent,
                          onSelected: (val) => setState(() => _isForRent = false),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 25),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          value: _minBedrooms,
                          decoration: const InputDecoration(labelText: 'Habitaciones'),
                          items: List.generate(6, (i) => DropdownMenuItem(value: i, child: Text('$i+'))),
                          onChanged: (val) => setState(() => _minBedrooms = val!),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          value: _minBathrooms,
                          decoration: const InputDecoration(labelText: 'Baños'),
                          items: List.generate(4, (i) => DropdownMenuItem(value: i, child: Text('$i+'))),
                          onChanged: (val) => setState(() => _minBathrooms = val!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 25),
                  DropdownButtonFormField<PropertyType>(
                    value: _selectedType,
                    decoration: const InputDecoration(labelText: 'Tipo de inmueble'),
                    hint: const Text('Todos los tipos'),
                    items: PropertyType.values.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(type.name.toUpperCase()),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedType = val),
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SearchResultsScreen(
                              city: _selectedCity ?? '',
                              priceRange: _priceRange,
                              minBedrooms: _minBedrooms,
                              minBathrooms: _minBathrooms,
                              type: _selectedType,
                              isForRent: _isForRent,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(15),
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('BUSCAR AHORA', style: TextStyle(fontSize: 18)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
