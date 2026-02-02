enum PropertyType { house, apartment, land, commercial }

class Property {
  final String id;
  final String title;
  final String description;
  final double price;
  final String address;
  final String city;
  final int bedrooms;
  final int bathrooms;
  final double area; // in square meters
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

  // Future method for Firestore
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
    return Property(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      address: map['address'] ?? '',
      city: map['city'] ?? '',
      bedrooms: map['bedrooms'] ?? 0,
      bathrooms: map['bathrooms'] ?? 0,
      area: (map['area'] ?? 0).toDouble(),
      images: List<String>.from(map['images'] ?? []),
      type: PropertyType.values[map['type'] ?? 0],
      isForRent: map['isForRent'] ?? false,
    );
  }
}
