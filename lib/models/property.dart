/// Tipos de inmuebles disponibles en la plataforma
enum PropertyType { chalet, piso, casa, atico, duplex }

/// Modelo que representa una propiedad o anuncio inmobiliario
class Property {
  final String id;
  final String userId; // ID del usuario que publicó el anuncio
  final String title;
  final String description;
  final double price;
  final String address;
  final String city;
  final String province;
  final int bedrooms;
  final int bathrooms;
  final double area; 
  final List<String> images; // Lista de imágenes en base64
  final PropertyType type;
  final bool isForRent;

  Property({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.price,
    required this.address,
    required this.city,
    required this.province,
    required this.bedrooms,
    required this.bathrooms,
    required this.area,
    required this.images,
    required this.type,
    required this.isForRent,
  });

  /// Convierte el objeto a un Map para guardarlo en Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'description': description,
      'price': price,
      'address': address,
      'city': city,
      'province': province,
      'bedrooms': bedrooms,
      'bathrooms': bathrooms,
      'area': area,
      'images': images,
      'type': type.index, // Guardamos el índice del enum
      'isForRent': isForRent,
    };
  }

  /// Crea una instancia de Property a partir de un documento de Firestore
  factory Property.fromMap(String id, Map<String, dynamic> map) {
    // Control de seguridad para el índice del enum
    int typeIndex = 0;
    if (map['type'] != null) {
      int val = (map['type'] as num).toInt();
      typeIndex = (val >= 0 && val < PropertyType.values.length) ? val : 0;
    }

    return Property(
      id: id,
      userId: map['userId']?.toString() ?? '',
      title: map['title']?.toString() ?? 'Sin título',
      description: map['description']?.toString() ?? '',
      price: (map['price'] ?? 0).toDouble(),
      address: map['address']?.toString() ?? '',
      city: map['city']?.toString() ?? '',
      province: map['province']?.toString() ?? '',
      bedrooms: (map['bedrooms'] ?? 0).toInt(),
      bathrooms: (map['bathrooms'] ?? 0).toInt(),
      area: (map['area'] ?? 0).toDouble(),
      images: map['images'] != null ? List<String>.from(map['images']) : [],
      type: PropertyType.values[typeIndex],
      isForRent: map['isForRent'] ?? false,
    );
  }
}
