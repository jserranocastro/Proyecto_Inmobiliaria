import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/property.dart';
import '../widgets/property_card.dart';
import '../services/firebase_service.dart';
import '../services/location_service.dart';
import 'property_detail_screen.dart';
import 'add_property_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final LocationService _locationService = LocationService();

  String? _selectedProvince;
  String? _selectedCity;
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

  void _onAddProperty() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes iniciar sesión para publicar un anuncio'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const AddPropertyScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inmuebles Disponibles'),
      ),
      body: _isLoadingLocations
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        children: [
                          const Text(
                            'Selecciona ubicación para ver anuncios',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 10),
                          DropdownButtonFormField<String>(
                            value: _selectedProvince,
                            decoration: const InputDecoration(labelText: 'Provincia', border: OutlineInputBorder()),
                            items: _provinces.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                            onChanged: (val) {
                              setState(() {
                                _selectedProvince = val;
                                _selectedCity = null;
                                _municipios = _locationService.getMunicipios(val!);
                              });
                            },
                          ),
                          const SizedBox(height: 10),
                          DropdownButtonFormField<String>(
                            value: _selectedCity,
                            decoration: const InputDecoration(labelText: 'Municipio', border: OutlineInputBorder()),
                            disabledHint: const Text('Elige una provincia'),
                            items: _municipios.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                            onChanged: _selectedProvince == null
                                ? null
                                : (val) {
                                    setState(() => _selectedCity = val);
                                  },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: (_selectedProvince == null || _selectedCity == null)
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.location_on_outlined, size: 60, color: Colors.grey),
                              SizedBox(height: 10),
                              Text('Elige una ubicación para empezar', style: TextStyle(color: Colors.grey, fontSize: 16)),
                            ],
                          ),
                        )
                      : StreamBuilder<List<Property>>(
                          stream: _firebaseService.getPropertiesByLocation(_selectedProvince!, _selectedCity!),
                          builder: (context, snapshot) {
                            if (snapshot.hasError) {
                              return Center(child: Text('Error: ${snapshot.error}'));
                            }
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Center(child: CircularProgressIndicator());
                            }

                            final properties = snapshot.data ?? [];

                            if (properties.isEmpty) {
                              return const Center(
                                child: Text('No hay inmuebles en esta zona. ¡Sé el primero!'),
                              );
                            }

                            return ListView.builder(
                              itemCount: properties.length,
                              itemBuilder: (context, index) {
                                return PropertyCard(
                                  property: properties[index],
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => PropertyDetailScreen(property: properties[index]),
                                      ),
                                    );
                                  },
                                );
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _onAddProperty,
        child: const Icon(Icons.add),
      ),
    );
  }
}
