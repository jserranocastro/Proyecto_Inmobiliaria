import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/property.dart';

class FirebaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference get _propertiesRef => _db.collection('properties');
  CollectionReference get _usersRef => _db.collection('users');

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

  // --- Favoritos ---

  Future<void> toggleFavorite(String userId, String propertyId) async {
    final userDoc = _usersRef.doc(userId);
    final doc = await userDoc.get();

    if (!doc.exists) {
      await userDoc.set({'favorites': [propertyId]});
      return;
    }

    final data = doc.data() as Map<String, dynamic>;
    List<String> favorites = List<String>.from(data['favorites'] ?? []);

    if (favorites.contains(propertyId)) {
      favorites.remove(propertyId);
    } else {
      favorites.add(propertyId);
    }

    await userDoc.update({'favorites': favorites});
  }

  Stream<List<String>> getUserFavorites(String userId) {
    return _usersRef.doc(userId).snapshots().map((snapshot) {
      if (!snapshot.exists) return [];
      final data = snapshot.data() as Map<String, dynamic>;
      return List<String>.from(data['favorites'] ?? []);
    });
  }

  Stream<List<Property>> getFavoriteProperties(List<String> favoriteIds) {
    if (favoriteIds.isEmpty) return Stream.value([]);
    
    // Firestore whereIn tiene límite de 10 elementos, para este ejemplo básico lo usaremos así
    // En una app real con muchos favoritos habría que paginar o pedir uno a uno
    return _propertiesRef
        .where(FieldPath.documentId, whereIn: favoriteIds.take(10).toList())
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Property.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }
}
