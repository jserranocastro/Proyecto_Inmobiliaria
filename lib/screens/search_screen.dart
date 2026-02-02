import 'package:flutter/material.dart';
import '../models/property.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  String _city = '';
  RangeValues _priceRange = const RangeValues(0, 1000000);
  int _minBedrooms = 0;
  int _minBathrooms = 0;
  PropertyType? _selectedType;
  bool _isForRent = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buscar Inmuebles'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Búsqueda por Ciudad
            TextField(
              decoration: const InputDecoration(
                labelText: 'Ciudad',
                prefixIcon: Icon(Icons.location_city),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => setState(() => _city = value),
            ),
            const SizedBox(height: 25),

            // Filtro de Precio
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

            // Compra o Alquiler
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

            // Habitaciones y Baños
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

            // Tipo de Inmueble
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
                  // TODO: Implementar consulta compleja a Firestore
                  print('Buscando: $_city, ${_priceRange.start}-${_priceRange.end}, Rent: $_isForRent');
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
