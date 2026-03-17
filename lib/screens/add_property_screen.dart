import 'dart:convert';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/property.dart';
import '../services/firebase_service.dart';
import '../services/location_service.dart';

/// Pantalla para crear o editar un anuncio de inmueble
class AddPropertyScreen extends StatefulWidget {
  final Property? propertyToEdit; // Si viene informado, la pantalla entra en modo edición

  const AddPropertyScreen({super.key, this.propertyToEdit});

  @override
  State<AddPropertyScreen> createState() => _AddPropertyScreenState();
}

class _AddPropertyScreenState extends State<AddPropertyScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseService _firebaseService = FirebaseService();
  final LocationService _locationService = LocationService();
  final ImagePicker _picker = ImagePicker();

  // Controladores para los campos del formulario
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _addressController = TextEditingController();
  final _areaController = TextEditingController();

  // Estado del formulario
  String? _selectedProvince;
  String? _selectedCity;
  int _bedrooms = 1;
  int _bathrooms = 1;
  PropertyType _type = PropertyType.piso;
  bool _isForRent = false;

  List<String> _provinces = [];
  List<String> _municipios = [];
  List<String> _base64Images = []; // Guardamos las imágenes codificadas para Firestore
  bool _isLoadingLocations = true;

  bool get _isEditing => widget.propertyToEdit != null;

  @override
  void initState() {
    super.initState();
    _loadLocations();
  }

  /// Carga inicial de datos geográficos y pre-rellenado si es edición
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
      _base64Images = List.from(p.images);
      
      if (_selectedProvince != null) {
        _municipios = _locationService.getMunicipios(_selectedProvince!);
      }
    }

    setState(() {
      _provinces = _locationService.getProvinces();
      _isLoadingLocations = false;
    });
  }

  /// Selecciona una imagen de la galería y la convierte a Base64
  Future<void> _pickImage() async {
    if (_base64Images.length >= 7) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Máximo 7 fotos por anuncio')),
      );
      return;
    }

    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50, // Reducimos calidad para ahorrar espacio en Firestore
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

  /// Elimina una imagen de la lista temporal
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

  /// Valida el formulario y persiste los datos en Firebase
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
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar Inmueble' : 'Añadir Inmueble'),
        surfaceTintColor: Colors.transparent,
        leading: Navigator.canPop(context) 
          ? IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            )
          : null,
      ),
      body: _isLoadingLocations 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Selector de imágenes con scroll horizontal
                  const Text('Fotos del inmueble (Máx. 7)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 12),
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
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.grey[300]!, width: 1),
                              ),
                              child: Icon(Icons.add_a_photo_outlined, color: primaryColor, size: 30),
                            ),
                          );
                        }
                        return Container(
                          width: 100,
                          margin: const EdgeInsets.only(right: 12),
                          child: Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.memory(
                                  base64Decode(_base64Images[index]),
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                right: 4,
                                top: 4,
                                child: GestureDetector(
                                  onTap: () => _removeImage(index),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                                    child: const Icon(Icons.close, color: Colors.red, size: 16),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Selector Venta vs Alquiler
                  const Text('¿Qué deseas hacer?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: const Center(child: Text('Vender')),
                          selected: !_isForRent,
                          onSelected: (val) => setState(() => _isForRent = false),
                          showCheckmark: false,
                          selectedColor: primaryColor.withOpacity(0.1),
                          labelStyle: TextStyle(
                            color: !_isForRent ? primaryColor : Colors.grey[600],
                            fontWeight: !_isForRent ? FontWeight.bold : FontWeight.normal,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: !_isForRent ? primaryColor : Colors.grey[300]!),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ChoiceChip(
                          label: const Center(child: Text('Alquilar')),
                          selected: _isForRent,
                          onSelected: (val) => setState(() => _isForRent = true),
                          showCheckmark: false,
                          selectedColor: primaryColor.withOpacity(0.1),
                          labelStyle: TextStyle(
                            color: _isForRent ? primaryColor : Colors.grey[600],
                            fontWeight: _isForRent ? FontWeight.bold : FontWeight.normal,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: _isForRent ? primaryColor : Colors.grey[300]!),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Campos de texto básicos
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(labelText: 'Título del anuncio', prefixIcon: Icon(Icons.title)),
                    validator: (value) => value!.isEmpty ? 'Campo obligatorio' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(labelText: 'Descripción detallada', prefixIcon: Icon(Icons.description_outlined)),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _priceController,
                          decoration: InputDecoration(
                            labelText: _isForRent ? 'Precio/mes' : 'Precio/venta',
                            prefixIcon: const Icon(Icons.euro),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) => value!.isEmpty ? 'Obligatorio' : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _areaController,
                          decoration: const InputDecoration(labelText: 'Área (m²)', prefixIcon: Icon(Icons.square_foot)),
                          keyboardType: TextInputType.number,
                          validator: (value) => value!.isEmpty ? 'Obligatorio' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Selectores de ubicación anidados
                  const Text('Ubicación', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _selectedProvince,
                    decoration: const InputDecoration(labelText: 'Provincia', prefixIcon: Icon(Icons.map_outlined)),
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
                    decoration: const InputDecoration(labelText: 'Municipio', prefixIcon: Icon(Icons.location_city)),
                    disabledHint: const Text('Selecciona provincia'),
                    items: _municipios.map((m) => DropdownMenuItem(value: m, child: Text(m, style: const TextStyle(fontSize: 14)))).toList(),
                    onChanged: _selectedProvince == null ? null : (val) {
                      setState(() => _selectedCity = val);
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _addressController,
                    decoration: const InputDecoration(labelText: 'Dirección (Calle, número...)', prefixIcon: Icon(Icons.place_outlined)),
                  ),
                  const SizedBox(height: 24),
                  // Características técnicas
                  const Text('Características', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          value: _bedrooms,
                          decoration: const InputDecoration(labelText: 'Hab.', prefixIcon: Icon(Icons.bed_outlined)),
                          items: List.generate(10, (index) => index + 1).map((val) => DropdownMenuItem(value: val, child: Text('$val'))).toList(),
                          onChanged: (val) => setState(() => _bedrooms = val!),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          value: _bathrooms,
                          decoration: const InputDecoration(labelText: 'Baños', prefixIcon: Icon(Icons.bathtub_outlined)),
                          items: List.generate(6, (index) => index + 1).map((val) => DropdownMenuItem(value: val, child: Text('$val'))).toList(),
                          onChanged: (val) => setState(() => _bathrooms = val!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<PropertyType>(
                    value: _type,
                    decoration: const InputDecoration(labelText: 'Tipo de inmueble', prefixIcon: Icon(Icons.home_work_outlined)),
                    items: PropertyType.values.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(type.name[0].toUpperCase() + type.name.substring(1)),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _type = val!),
                  ),
                  const SizedBox(height: 40),
                  // Botón de acción final
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saveProperty,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(18),
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text(
                        _isEditing ? 'GUARDAR CAMBIOS' : 'PUBLICAR ANUNCIO',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
    );
  }
}
