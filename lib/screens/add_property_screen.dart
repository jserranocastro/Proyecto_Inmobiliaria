import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/property.dart';
import '../services/firebase_service.dart';
import '../services/location_service.dart';

class AddPropertyScreen extends StatefulWidget {
  const AddPropertyScreen({super.key});

  @override
  State<AddPropertyScreen> createState() => _AddPropertyScreenState();
}

class _AddPropertyScreenState extends State<AddPropertyScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseService _firebaseService = FirebaseService();
  final LocationService _locationService = LocationService();

  String _title = '';
  String _description = '';
  double _price = 0;
  String _address = '';
  String? _selectedProvince;
  String? _selectedCity;
  int _bedrooms = 1;
  int _bathrooms = 1;
  double _area = 0;
  PropertyType _type = PropertyType.piso;
  bool _isForRent = false;

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

  void _saveProperty() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Necesitas iniciar sesión para publicar')),
      );
      return;
    }

    if (_formKey.currentState!.validate() && _selectedProvince != null && _selectedCity != null) {
      _formKey.currentState!.save();
      
      final newProperty = Property(
        id: '', 
        userId: user.uid, // <-- AQUÍ ESTÁ LA MAGIA
        title: _title,
        description: _description,
        price: _price,
        address: _address,
        city: _selectedCity!,
        province: _selectedProvince!,
        bedrooms: _bedrooms,
        bathrooms: _bathrooms,
        area: _area,
        images: [], 
        type: _type,
        isForRent: _isForRent,
      );

      try {
        await _firebaseService.addProperty(newProperty);
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Propiedad añadida con éxito')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al añadir: $e')),
        );
      }
    } else if (_selectedProvince == null || _selectedCity == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, selecciona provincia y municipio')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Añadir Inmueble')),
      body: _isLoadingLocations 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  // ... (el resto del formulario no cambia)
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Título'),
                    validator: (value) => value!.isEmpty ? 'Campo obligatorio' : null,
                    onSaved: (value) => _title = value!,
                  ),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Descripción'),
                    maxLines: 3,
                    onSaved: (value) => _description = value!,
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          decoration: const InputDecoration(labelText: 'Precio (€)'),
                          keyboardType: TextInputType.number,
                          validator: (value) => value!.isEmpty ? 'Obligatorio' : null,
                          onSaved: (value) => _price = double.parse(value!),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: SwitchListTile(
                          title: const Text('¿Alquiler?'),
                          value: _isForRent,
                          onChanged: (val) => setState(() => _isForRent = val),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  DropdownButtonFormField<String>(
                    value: _selectedProvince,
                    decoration: const InputDecoration(labelText: 'Provincia'),
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
                  DropdownButtonFormField<String>(
                    value: _selectedCity,
                    decoration: const InputDecoration(labelText: 'Municipio'),
                    disabledHint: const Text('Selecciona primero una provincia'),
                    items: _municipios.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                    onChanged: _selectedProvince == null ? null : (val) {
                      setState(() => _selectedCity = val);
                    },
                  ),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Dirección (Calle, número...)'),
                    onSaved: (value) => _address = value!,
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          value: _bedrooms,
                          decoration: const InputDecoration(labelText: 'Habitaciones'),
                          items: List.generate(10, (index) => index + 1)
                              .map((val) => DropdownMenuItem(value: val, child: Text('$val')))
                              .toList(),
                          onChanged: (val) => setState(() => _bedrooms = val!),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          value: _bathrooms,
                          decoration: const InputDecoration(labelText: 'Baños'),
                          items: List.generate(6, (index) => index + 1)
                              .map((val) => DropdownMenuItem(value: val, child: Text('$val')))
                              .toList(),
                          onChanged: (val) => setState(() => _bathrooms = val!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Área (m²)'),
                    keyboardType: TextInputType.number,
                    onSaved: (value) => _area = double.parse(value ?? '0'),
                  ),
                  const SizedBox(height: 15),
                  DropdownButtonFormField<PropertyType>(
                    value: _type,
                    decoration: const InputDecoration(labelText: 'Tipo de inmueble'),
                    items: PropertyType.values.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(type.name.toUpperCase()),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _type = val!),
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saveProperty,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(15),
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Guardar Inmueble', style: TextStyle(fontSize: 18)),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }
}
