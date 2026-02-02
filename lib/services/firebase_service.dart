import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/property.dart';

class FirebaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Collection reference
  CollectionReference get _propertiesRef => _db.collection('properties');

  // Get all properties
  Stream<List<Property>> getProperties() {
    return _propertiesRef.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return Property.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }

  // Add a new property
  Future<void> addProperty(Property property) {
    return _propertiesRef.add(property.toMap());
  }

  // Update a property
  Future<void> updateProperty(Property property) {
    return _propertiesRef.doc(property.id).update(property.toMap());
  }

  // Delete a property
  Future<void> deleteProperty(String id) {
    return _propertiesRef.doc(id).delete();
  }
}
