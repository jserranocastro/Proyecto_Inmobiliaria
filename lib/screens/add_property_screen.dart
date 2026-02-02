import 'dart:convert';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/property.dart';
import '../services/firebase_service.dart';
import '../services/location_service.dart';

class AddPropertyScreen extends StatefulWidget {
  final Property? propertyToEdit;

  const AddPropertyScreen({super.key, this.propertyToEdit});

  @override
  State<AddPropertyScreen> createState() => _AddPropertyScreenState();
}

class _AddPropertyScreenState extends State<AddPropertyScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseService _firebaseService = FirebaseService();
  final LocationService _locationService = LocationService();
  final ImagePicker _picker = ImagePicker();

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _addressController = TextEditingController();
  final _areaController = TextEditingController();

  String? _selectedProvince;
  String? _selectedCity;
  int _bedrooms = 1;
  int _bathrooms = 1;
  PropertyType _type = PropertyType.piso;
  bool _isForRent = false;

  List<String> _provinces = [];
  List<String> _municipios = [];
  List<String> _base64Images = []; // Lista para almacenar fotos en Base64
  bool _isLoadingLocations = true;

  bool get _isEditing => widget.propertyToEdit != null;

  @override
  void initState() {
    super.initState();
    _loadLocations();
  }

  Future<void> _loadLocations() async {
    await _locationService.init();
    
    if (_isEditing) {
      final p = widget.propertyToEdit!;
      _titleController.text = p.title;
      _descriptionController.text = p.description;
      _priceController.text = p.price.toString();
      _addressController.text = p.address;
      _areaController.text = p.area.toString();
      _selectedProvince = p.province;
      _selectedCity = p.city;
      _bedrooms = p.bedrooms;
      _bathrooms = p.bathrooms;
      _type = p.type;
      _isForRent = p.isForRent;
      _base64Images = List.from(p.images); // Cargar imágenes existentes
      
      if (_selectedProvince != null) {
        _municipios = _locationService.getMunicipios(_selectedProvince!);
      }
    }

    setState(() {
      _provinces = _locationService.getProvinces();
      _isLoadingLocations = false;
    });
  }

  Future<void> _pickImage() async {
    if (_base64Images.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Máximo 5 fotos por anuncio')),
      );
      return;
    }

    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50, // Comprimimos para que el Base64 no sea gigante
      maxWidth: 800,
    );

    if (image != null) {
      final bytes = await File(image.path).readAsBytes();
      final base64String = base64Encode(bytes);
      setState(() {
        _base64Images.add(base64String);
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _base64Images.removeAt(index);
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _addressController.dispose();
    _areaController.dispose();
    super.dispose();
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
      final property = Property(
        id: _isEditing ? widget.propertyToEdit!.id : '', 
        userId: user.uid,
        title: _titleController.text,
        description: _descriptionController.text,
        price: double.parse(_priceController.text),
        address: _addressController.text,
        city: _selectedCity!,
        province: _selectedProvince!,
        bedrooms: _bedrooms,
        bathrooms: _bathrooms,
        area: double.parse(_areaController.text),
        images: _base64Images, 
        type: _type,
        isForRent: _isForRent,
      );

      try {
        if (_isEditing) {
          await _firebaseService.updateProperty(property);
        } else {
          await _firebaseService.addProperty(property);
        }
        
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(_isEditing ? 'Anuncio actualizado' : 'Propiedad añadida con éxito')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar: $e')),
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
      appBar: AppBar(title: Text(_isEditing ? 'Editar Inmueble' : 'Añadir Inmueble')),
      body: _isLoadingLocations 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Selector de Imágenes
                  const Text('Fotos del inmueble (Máx. 5)', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 100,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _base64Images.length + 1,
                      itemBuilder: (context, index) {
                        if (index == _base64Images.length) {
                          return GestureDetector(
                            onTap: _pickImage,
                            child: Container(
                              width: 100,
                              margin: const EdgeInsets.only(right: 10),
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.grey[400]!),
                              ),
                              child: const Icon(Icons.add_a_photo, color: Colors.blueAccent),
                            ),
                          );
                        }
                        return Stack(
                          children: [
                            Container(
                              width: 100,
                              margin: const EdgeInsets.only(right: 10),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                image: DecorationImage(
                                  image: MemoryImage(base64Decode(_base64Images[index])),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Positioned(
                              right: 5,
                              top: -5,
                              child: IconButton(
                                icon: const Icon(Icons.cancel, color: Colors.red),
                                onPressed: () => _removeImage(index),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(labelText: 'Título'),
                    validator: (value) => value!.isEmpty ? 'Campo obligatorio' : null,
                  ),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(labelText: 'Descripción'),
                    maxLines: 3,
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _priceController,
                          decoration: const InputDecoration(labelText: 'Precio (€)'),
                          keyboardType: TextInputType.number,
                          validator: (value) => value!.isEmpty ? 'Obligatorio' : null,
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
                    controller: _addressController,
                    decoration: const InputDecoration(labelText: 'Dirección (Calle, número...)'),
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          value: _bedrooms,
                          decoration: const InputDecoration(labelText: 'Habitaciones'),
                          items: List.generate(10, (index) => index + 1).map((val) => DropdownMenuItem(value: val, child: Text('$val'))).toList(),
                          onChanged: (val) => setState(() => _bedrooms = val!),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          value: _bathrooms,
                          decoration: const InputDecoration(labelText: 'Baños'),
                          items: List.generate(6, (index) => index + 1).map((val) => DropdownMenuItem(value: val, child: Text('$val'))).toList(),
                          onChanged: (val) => setState(() => _bathrooms = val!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  TextFormField(
                    controller: _areaController,
                    decoration: const InputDecoration(labelText: 'Área (m²)'),
                    keyboardType: TextInputType.number,
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
                      child: Text(_isEditing ? 'Guardar Cambios' : 'Publicar Inmueble', style: const TextStyle(fontSize: 18)),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }
}
