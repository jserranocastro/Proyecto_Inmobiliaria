import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/property.dart';

class FirebaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference get _propertiesRef => _db.collection('properties');

  // Obtener propiedades por ubicación exacta
  Stream<List<Property>> getPropertiesByLocation(String province, String city) {
    return _propertiesRef
        .where('province', isEqualTo: province)
        .where('city', isEqualTo: city)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Property.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }

  // Obtener todas las propiedades (mantenemos por compatibilidad)
  Stream<List<Property>> getProperties() {
    return _propertiesRef.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return Property.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }

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

  // Búsqueda con filtros complejos
  Stream<List<Property>> searchProperties({
    required String city,
    required double minPrice,
    required double maxPrice,
    required int minBedrooms,
    required int minBathrooms,
    PropertyType? type,
    required bool isForRent,
  }) {
    Query query = _propertiesRef;
    query = query.where('isForRent', isEqualTo: isForRent);
    if (city.isNotEmpty) query = query.where('city', isEqualTo: city);
    if (type != null) query = query.where('type', isEqualTo: type.index);
    query = query.where('price', isGreaterThanOrEqualTo: minPrice)
                 .where('price', isLessThanOrEqualTo: maxPrice);

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return Property.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }).where((p) {
        return p.bedrooms >= minBedrooms && p.bathrooms >= minBathrooms;
      }).toList();
    });
  }

  Future<void> addProperty(Property property) async {
    await _propertiesRef.add(property.toMap());
  }

  Future<void> updateProperty(Property property) {
    return _propertiesRef.doc(property.id).update(property.toMap());
  }

  Future<void> deleteProperty(String propertyId) {
    return _propertiesRef.doc(propertyId).delete();
  }
}
