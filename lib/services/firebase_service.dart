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

  // Obtener solo las propiedades de un usuario
  Stream<List<Property>> getPropertiesForUser(String userId) {
    return _propertiesRef
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
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

    query = query.where('isForRent', isEqualTo: isForRent);
    
    if (city.isNotEmpty) {
      query = query.where('city', isEqualTo: city);
    }
    
    if (type != null) {
      query = query.where('type', isEqualTo: type.index);
    }

    query = query.where('price', isGreaterThanOrEqualTo: minPrice)
                 .where('price', isLessThanOrEqualTo: maxPrice);

    return query.snapshots().map((snapshot) {
      final results = snapshot.docs.map((doc) {
        return Property.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }).where((p) {
        return p.bedrooms >= minBedrooms && p.bathrooms >= minBathrooms;
      }).toList();
      
      return results;
    });
  }

  Future<void> addProperty(Property property) async {
    try {
      await _propertiesRef.add(property.toMap());
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateProperty(Property property) {
    return _propertiesRef.doc(property.id).update(property.toMap());
  }

  Future<void> deleteProperty(String propertyId) {
    return _propertiesRef.doc(propertyId).delete();
  }
}
