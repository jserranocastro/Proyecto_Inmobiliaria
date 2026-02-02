import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/property.dart';

class FirebaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference get _propertiesRef => _db.collection('properties');

  // Obtener todas las propiedades para la Home
  Stream<List<Property>> getProperties() {
    return _propertiesRef.snapshots().map((snapshot) {
      print("FIREBASE: Recibidos ${snapshot.docs.length} documentos de la colección 'properties'");
      return snapshot.docs.map((doc) {
        return Property.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }

  // BÚSQUEDA CON FILTROS
  Stream<List<Property>> searchProperties({
    required String city,
    required double minPrice,
    required double maxPrice,
    required int minBedrooms,
    required int minBathrooms,
    PropertyType? type,
    required bool isForRent,
  }) {
    print("FIREBASE: Iniciando búsqueda con filtros...");
    print("Filtros: Ciudad=$city, Precio=$minPrice-$maxPrice, Alquiler=$isForRent, Tipo=$type");

    Query query = _propertiesRef;

    // Filtro Alquiler/Compra (Siempre activo)
    query = query.where('isForRent', isEqualTo: isForRent);
    
    if (city.isNotEmpty) {
      query = query.where('city', isEqualTo: city);
    }
    
    if (type != null) {
      query = query.where('type', isEqualTo: type.index);
    }

    // Rango de precio
    query = query.where('price', isGreaterThanOrEqualTo: minPrice)
                 .where('price', isLessThanOrEqualTo: maxPrice);

    return query.snapshots().map((snapshot) {
      print("FIREBASE: Búsqueda completada. Encontrados ${snapshot.docs.length} docs en Firestore");
      
      final results = snapshot.docs.map((doc) {
        return Property.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }).where((p) {
        // Filtro manual para habitaciones y baños
        return p.bedrooms >= minBedrooms && p.bathrooms >= minBathrooms;
      }).toList();
      
      print("FIREBASE: Tras filtros de habitaciones/baños quedan ${results.length} resultados");
      return results;
    });
  }

  Future<void> addProperty(Property property) async {
    try {
      await _propertiesRef.add(property.toMap());
      print("FIREBASE: Propiedad guardada con éxito");
    } catch (e) {
      print("FIREBASE ERROR al guardar: $e");
      rethrow;
    }
  }
}
