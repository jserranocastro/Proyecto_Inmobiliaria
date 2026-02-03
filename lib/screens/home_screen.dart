import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/property.dart';
import '../widgets/property_card.dart';
import '../services/firebase_service.dart';
import '../services/location_service.dart';
import '../services/preferences_service.dart';
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
  final PreferencesService _prefsService = PreferencesService();

  String? _selectedProvince;
  String? _selectedCity;
  List<String> _provinces = [];
  List<String> _municipios = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeData();
    // Escuchar cambios en la ubicación global (ej: desde AuthScreen)
    PreferencesService.locationNotifier.addListener(_onLocationPreferenceChanged);
  }

  @override
  void dispose() {
    PreferencesService.locationNotifier.removeListener(_onLocationPreferenceChanged);
    super.dispose();
  }

  void _onLocationPreferenceChanged() {
    final newLoc = PreferencesService.locationNotifier.value;
    if (mounted) {
      setState(() {
        _selectedProvince = newLoc['province'];
        _selectedCity = newLoc['city'];
        if (_selectedProvince != null) {
          _municipios = _locationService.getMunicipios(_selectedProvince!);
        }
      });
    }
  }

  Future<void> _initializeData() async {
    await _locationService.init();
    final provinces = _locationService.getProvinces();
    
    final savedLoc = await _prefsService.getDefaultLocation();
    
    if (mounted) {
      setState(() {
        _provinces = provinces;
        _selectedProvince = savedLoc['province'];
        _selectedCity = savedLoc['city'];
        if (_selectedProvince != null) {
          _municipios = _locationService.getMunicipios(_selectedProvince!);
        }
        _isLoading = false;
      });
    }
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

  void _showChangeLocationSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 20,
            left: 20,
            right: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(height: 20),
              const Text('Cambiar Ubicación', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: _selectedProvince,
                decoration: const InputDecoration(labelText: 'Provincia'),
                items: _provinces.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                onChanged: (val) {
                  setSheetState(() {
                    _selectedProvince = val;
                    _selectedCity = null;
                    _municipios = _locationService.getMunicipios(val!);
                  });
                },
              ),
              const SizedBox(height: 15),
              DropdownButtonFormField<String>(
                value: _selectedCity,
                decoration: const InputDecoration(labelText: 'Municipio'),
                items: _municipios.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                onChanged: _selectedProvince == null ? null : (val) {
                  setSheetState(() => _selectedCity = val);
                },
              ),
              const SizedBox(height: 25),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _selectedProvince != null && _selectedCity != null
                      ? () {
                          setState(() {}); // Refrescar pantalla principal
                          Navigator.pop(context);
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Aplicar Filtro'),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Inmuebles'),
        // Botón de filtro eliminado como solicitaste
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                GestureDetector(
                  onTap: _showChangeLocationSheet,
                  child: Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.location_on, color: Color(0xFF0052D4), size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _selectedCity ?? 'Seleccionar ubicación',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              if (_selectedProvince != null)
                                Text(_selectedProvince!, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                            ],
                          ),
                        ),
                        Text(
                          'Cambiar',
                          style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: (_selectedProvince == null || _selectedCity == null)
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.location_city_rounded, size: 80, color: Colors.grey[300]),
                              const SizedBox(height: 16),
                              Text('Elige una ubicación para ver anuncios', style: TextStyle(color: Colors.grey[500], fontSize: 16)),
                              const SizedBox(height: 20),
                              ElevatedButton.icon(
                                onPressed: _showChangeLocationSheet,
                                icon: const Icon(Icons.search),
                                label: const Text('Seleccionar ahora'),
                              )
                            ],
                          ),
                        )
                      : StreamBuilder<List<Property>>(
                          stream: _firebaseService.getPropertiesByLocation(_selectedProvince!, _selectedCity!),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Center(child: CircularProgressIndicator());
                            }
                            
                            final properties = snapshot.data ?? [];

                            if (properties.isEmpty) {
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.sentiment_dissatisfied, size: 64, color: Colors.grey[300]),
                                    const SizedBox(height: 16),
                                    const Text('No hay inmuebles en esta zona', style: TextStyle(fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 8),
                                    Text('¡Sé el primero en publicar uno!', style: TextStyle(color: Colors.grey[600])),
                                  ],
                                ),
                              );
                            }

                            return ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _onAddProperty,
        backgroundColor: const Color(0xFF0052D4),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Publicar'),
      ),
    );
  }
}
