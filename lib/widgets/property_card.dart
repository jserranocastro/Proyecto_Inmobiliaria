import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/property.dart';

class PropertyCard extends StatelessWidget {
  final Property property;
  final VoidCallback onTap;

  const PropertyCard({super.key, required this.property, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(10),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Contenedor de la imagen
            Container(
              height: 200,
              width: double.infinity,
              color: Colors.grey[300],
              child: property.images.isNotEmpty
                  ? Image.memory(
                      base64Decode(property.images[0]),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Center(child: Icon(Icons.broken_image, size: 50));
                      },
                    )
                  : const Icon(Icons.home, size: 50, color: Colors.white),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${property.price.toStringAsFixed(0)} €${property.isForRent ? "/mes" : ""}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueAccent,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    property.title,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${property.city} - ${property.province}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.king_bed_outlined, size: 20, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text('${property.bedrooms} hab.'),
                      const SizedBox(width: 15),
                      Icon(Icons.bathtub_outlined, size: 20, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text('${property.bathrooms} baños'),
                      const SizedBox(width: 15),
                      Icon(Icons.square_foot, size: 20, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text('${property.area.toStringAsFixed(0)} m²'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
