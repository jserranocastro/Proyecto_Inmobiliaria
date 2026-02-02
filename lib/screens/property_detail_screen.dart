import 'package:flutter/material.dart';
import '../models/property.dart';

class PropertyDetailScreen extends StatelessWidget {
  final Property property;

  const PropertyDetailScreen({super.key, required this.property});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(property.title, style: const TextStyle(fontSize: 16)),
              background: Container(
                color: Colors.grey[300],
                child: property.images.isNotEmpty
                    ? Image.network(property.images[0], fit: BoxFit.cover)
                    : const Icon(Icons.home, size: 100, color: Colors.white),
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${property.price.toStringAsFixed(0)} €${property.isForRent ? "/mes" : ""}',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueAccent,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${property.city} - ${property.address}',
                      style: TextStyle(fontSize: 18, color: Colors.grey[700]),
                    ),
                    const Divider(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _FeatureIcon(icon: Icons.king_bed, label: '${property.bedrooms} hab.'),
                        _FeatureIcon(icon: Icons.bathtub, label: '${property.bathrooms} baños'),
                        _FeatureIcon(icon: Icons.square_foot, label: '${property.area} m²'),
                      ],
                    ),
                    const Divider(height: 32),
                    const Text(
                      'Descripción',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      property.description,
                      style: const TextStyle(fontSize: 16, height: 1.5),
                    ),
                    const SizedBox(height: 100), // Space for button
                  ],
                ),
              ),
            ]),
          ),
        ],
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(16),
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
        ),
        child: ElevatedButton(
          onPressed: () {
            // TODO: Implement contact logic
          },
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 15),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: const Text('Contactar', style: TextStyle(fontSize: 18)),
        ),
      ),
    );
  }
}

class _FeatureIcon extends StatelessWidget {
  final IconData icon;
  final String label;

  const _FeatureIcon({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 30, color: Colors.blueAccent),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
      ],
    );
  }
}
