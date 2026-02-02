import 'package:flutter/material.dart';
import '../models/property.dart';
import '../services/firebase_service.dart';

class AddPropertyScreen extends StatefulWidget {
  const AddPropertyScreen({super.key});

  @override
  State<AddPropertyScreen> createState() => _AddPropertyScreenState();
}

class _AddPropertyScreenState extends State<AddPropertyScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseService _firebaseService = FirebaseService();

  String _title = '';
  String _description = '';
  double _price = 0;
  String _address = '';
  String _city = '';
  int _bedrooms = 1;
  int _bathrooms = 1;
  double _area = 0;
  PropertyType _type = PropertyType.piso;
  bool _isForRent = false;

  void _saveProperty() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      
      final newProperty = Property(
        id: '', // Firestore will generate this
        title: _title,
        description: _description,
        price: _price,
        address: _address,
        city: _city,
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
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Añadir Inmueble')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
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
              TextFormField(
                decoration: const InputDecoration(labelText: 'Ciudad'),
                onSaved: (value) => _city = value!,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Dirección'),
                onSaved: (value) => _address = value!,
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  // Desplegable Habitaciones
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
                  // Desplegable Baños
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
              // Desplegable Tipo de Vivienda actualizado
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
