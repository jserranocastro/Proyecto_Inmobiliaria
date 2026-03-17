import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/property.dart';
import '../widgets/property_card.dart';
import '../services/firebase_service.dart';
import '../services/location_service.dart';
import '../services/preferences_service.dart';
import 'property_detail_screen.dart';
import 'add_property_screen.dart';

/// Pantalla principal que muestra el listado de inmuebles según la ubicación seleccionada
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
    // Escuchamos cambios en las preferencias de ubicación (ej. desde ajustes)
    PreferencesService.locationNotifier.addListener(_onLocationPreferenceChanged);
  }

  @override
  void dispose() {
    PreferencesService.locationNotifier.removeListener(_onLocationPreferenceChanged);
    super.dispose();
  }

  /// Actualiza la UI cuando cambia la ubicación global
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

  /// Carga inicial: inicializa el servicio de localización y recupera la última ubicación guardada
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

  /// Navega a la pantalla de publicación, verificando sesión previa
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

  /// Despliega el panel inferior para seleccionar provincia y municipio
  void _showChangeLocationSheet() {
    final primaryColor = Theme.of(context).colorScheme.primary;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Permite que el modal crezca con el teclado
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          top: 12,
          left: 24,
          right: 24,
        ),
        child: StatefulBuilder(
          builder: (context, setSheetState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(height: 24),
              const Text('Cambiar Ubicación', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              // Selector de Provincia
              DropdownButtonFormField<String>(
                isExpanded: true,
                value: _selectedProvince,
                decoration: const InputDecoration(labelText: 'Provincia'),
                items: _provinces.map((p) => DropdownMenuItem(
                  value: p, 
                  child: Text(p, overflow: TextOverflow.ellipsis)
                )).toList(),
                onChanged: (val) {
                  setSheetState(() {
                    _selectedProvince = val;
                    _selectedCity = null; // Reiniciamos ciudad al cambiar provincia
                    _municipios = _locationService.getMunicipios(val!);
                  });
                },
              ),
              const SizedBox(height: 16),
              // Selector de Municipio (bloqueado hasta elegir provincia)
              DropdownButtonFormField<String>(
                isExpanded: true,
                value: _selectedCity,
                decoration: const InputDecoration(labelText: 'Municipio'),
                items: _municipios.map((m) => DropdownMenuItem(
                  value: m, 
                  child: Text(m, overflow: TextOverflow.ellipsis)
                )).toList(),
                onChanged: _selectedProvince == null ? null : (val) {
                  setSheetState(() => _selectedCity = val);
                },
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _selectedProvince != null && _selectedCity != null
                      ? () {
                          setState(() {}); // Forzamos reconstrucción del StreamBuilder principal
                          Navigator.pop(context);
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    elevation: 4,
                    shadowColor: primaryColor.withOpacity(0.4),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('APLICAR FILTRO', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: const Text('Inmuebles en tu zona'),
        surfaceTintColor: Colors.transparent,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Selector de ubicación (Header)
                GestureDetector(
                  onTap: _showChangeLocationSheet,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 5)),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.location_on, color: primaryColor, size: 20),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _selectedCity ?? 'Seleccionar ubicación',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (_selectedProvince != null)
                                Text(
                                  _selectedProvince!, 
                                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: (_selectedProvince == null || _selectedCity == null)
                      ? Center(
                          // Pantalla de bienvenida / Empty state cuando no hay ubicación
                          child: SingleChildScrollView(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.location_city_rounded, size: 100, color: primaryColor.withOpacity(0.1)),
                                  const SizedBox(height: 24),
                                  const Text(
                                    'Encuentra tu próximo hogar',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Elige una ubicación para ver los mejores inmuebles disponibles en tu zona.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: Colors.grey[600], height: 1.5),
                                  ),
                                  const SizedBox(height: 32),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: _showChangeLocationSheet,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: primaryColor,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 18),
                                        elevation: 8,
                                        shadowColor: primaryColor.withOpacity(0.5),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                      ),
                                      child: const Text('BUSCAR AHORA', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
                                    ),
                                  )
                                ],
                              ),
                            ),
                          ),
                        )
                      : StreamBuilder<List<Property>>(
                          // Carga de inmuebles en tiempo real desde Firestore
                          stream: _firebaseService.getPropertiesByLocation(_selectedProvince!, _selectedCity!),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Center(child: CircularProgressIndicator());
                            }
                            
                            final properties = snapshot.data ?? [];

                            if (properties.isEmpty) {
                              return Center(
                                child: SingleChildScrollView(
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
                                ),
                              );
                            }

                            return ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
      // Botón flotante para publicar un nuevo anuncio
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _onAddProperty,
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 12,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: const Icon(Icons.add, size: 24),
        label: const Text('Publicar', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5)),
      ),
    );
  }
}
