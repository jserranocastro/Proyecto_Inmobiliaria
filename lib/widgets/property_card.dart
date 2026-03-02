import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/property.dart';
import '../services/firebase_service.dart';

class PropertyCard extends StatefulWidget {
  final Property property;
  final VoidCallback onTap;

  const PropertyCard({super.key, required this.property, required this.onTap});

  @override
  State<PropertyCard> createState() => _PropertyCardState();
}

class _PropertyCardState extends State<PropertyCard> {
  int _currentImageIndex = 0;
  final FirebaseService _firebaseService = FirebaseService();

  void _toggleFavorite() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inicia sesión para guardar favoritos')),
      );
      return;
    }
    await _firebaseService.toggleFavorite(user.uid, widget.property.id);
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

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
            onTap: widget.onTap,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Contenedor de la imagen
                Stack(
                  children: [
                    SizedBox(
                      height: 220,
                      width: double.infinity,
                      child: widget.property.images.isNotEmpty
                          ? PageView.builder(
                              itemCount: widget.property.images.length,
                              onPageChanged: (index) {
                                setState(() {
                                  _currentImageIndex = index;
                                });
                              },
                              itemBuilder: (context, index) {
                                return Image.memory(
                                  base64Decode(widget.property.images[index]),
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Center(child: Icon(Icons.broken_image, size: 50, color: Colors.grey));
                                  },
                                );
                              },
                            )
                          : Container(
                              color: Colors.grey[100],
                              child: const Center(child: Icon(Icons.home_work_outlined, size: 50, color: Colors.grey)),
                            ),
                    ),
                    // Botón de Favorito
                    Positioned(
                      top: 16,
                      left: 16,
                      child: user == null 
                        ? const SizedBox.shrink()
                        : StreamBuilder<List<String>>(
                          stream: _firebaseService.getUserFavorites(user.uid),
                          builder: (context, snapshot) {
                            final favorites = snapshot.data ?? [];
                            final isFavorite = favorites.contains(widget.property.id);
                            return GestureDetector(
                              onTap: _toggleFavorite,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.9),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  isFavorite ? Icons.favorite : Icons.favorite_border,
                                  color: isFavorite ? Colors.red : Colors.grey,
                                  size: 20,
                                ),
                              ),
                            );
                          }
                        ),
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
                          widget.property.type.name.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF8E44AD),
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),
                    if (widget.property.images.length > 1)
                      Positioned(
                        bottom: 10,
                        left: 0,
                        right: 0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(widget.property.images.length, (index) {
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              width: _currentImageIndex == index ? 12 : 8,
                              height: 8,
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(4),
                                color: _currentImageIndex == index ? Colors.white : Colors.white.withOpacity(0.7),
                              ),
                            );
                          }),
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
                            '${widget.property.price.toStringAsFixed(0)} €${widget.property.isForRent ? "/mes" : ""}',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF8E44AD),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.property.title,
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
                            '${widget.property.city}, ${widget.property.province}',
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
                          _buildInfoItem(Icons.king_bed_outlined, '${widget.property.bedrooms} hab.'),
                          _buildInfoItem(Icons.bathtub_outlined, '${widget.property.bathrooms} baños'),
                          _buildInfoItem(Icons.square_foot, '${widget.property.area.toStringAsFixed(0)} m²'),
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
        Icon(icon, size: 18, color: const Color(0xFFBB8FCE)),
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
