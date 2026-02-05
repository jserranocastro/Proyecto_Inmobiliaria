import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/property.dart';

class PropertyCard extends StatelessWidget {
  final Property property;
  final VoidCallback onTap;

  const PropertyCard({super.key, required this.property, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Contenedor de la imagen
                Stack(
                  children: [
                    Container(
                      height: 220,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                      ),
                      child: property.images.isNotEmpty
                          ? Image.memory(
                              base64Decode(property.images[0]),
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const Center(child: Icon(Icons.broken_image, size: 50, color: Colors.grey));
                              },
                            )
                          : const Center(child: Icon(Icons.home_work_outlined, size: 50, color: Colors.grey)),
                    ),
                    Positioned(
                      top: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          property.type.name.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${property.price.toStringAsFixed(0)} €${property.isForRent ? "/mes" : ""}',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0052D4),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        property.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A1A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            '${property.city}, ${property.province}',
                            style: TextStyle(color: Colors.grey[600], fontSize: 13),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Divider(color: Colors.grey[100], height: 1),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildInfoItem(Icons.king_bed_outlined, '${property.bedrooms} hab.'),
                          _buildInfoItem(Icons.bathtub_outlined, '${property.bathrooms} baños'),
                          _buildInfoItem(Icons.square_foot, '${property.area.toStringAsFixed(0)} m²'),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF4361EE)),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Color(0xFF4A4A4A),
          ),
        ),
      ],
    );
  }
}
