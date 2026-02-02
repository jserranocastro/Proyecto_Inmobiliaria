enum PropertyType { chalet, piso, casa, atico, duplex }

class Property {
  final String id;
  final String title;
  final String description;
  final double price;
  final String address;
  final String city;
  final int bedrooms;
  final int bathrooms;
  final double area; 
  final List<String> images;
  final PropertyType type;
  final bool isForRent;

  Property({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.address,
    required this.city,
    required this.bedrooms,
    required this.bathrooms,
    required this.area,
    required this.images,
    required this.type,
    required this.isForRent,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'price': price,
      'address': address,
      'city': city,
      'bedrooms': bedrooms,
      'bathrooms': bathrooms,
      'area': area,
      'images': images,
      'type': type.index,
      'isForRent': isForRent,
    };
  }

  factory Property.fromMap(String id, Map<String, dynamic> map) {
    // Intentamos obtener el tipo de forma segura
    int typeIndex = 0;
    if (map['type'] != null) {
      int val = (map['type'] as num).toInt();
      // Si el índice es válido para nuestro enum actual, lo usamos. Si no, ponemos 0 (chalet)
      typeIndex = (val >= 0 && val < PropertyType.values.length) ? val : 0;
    }

    return Property(
      id: id,
      title: map['title']?.toString() ?? 'Sin título',
      description: map['description']?.toString() ?? '',
      price: (map['price'] ?? 0).toDouble(),
      address: map['address']?.toString() ?? '',
      city: map['city']?.toString() ?? '',
      bedrooms: (map['bedrooms'] ?? 0).toInt(),
      bathrooms: (map['bathrooms'] ?? 0).toInt(),
      area: (map['area'] ?? 0).toDouble(),
      images: map['images'] != null ? List<String>.from(map['images']) : [],
      type: PropertyType.values[typeIndex],
      isForRent: map['isForRent'] ?? false,
    );
  }
}
