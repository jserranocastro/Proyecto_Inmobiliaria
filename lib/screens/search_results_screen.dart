import 'package:flutter/material.dart';
import '../models/property.dart';
import '../widgets/property_card.dart';
import '../services/firebase_service.dart';
import 'property_detail_screen.dart';

class SearchResultsScreen extends StatelessWidget {
  final String city;
  final RangeValues priceRange;
  final int minBedrooms;
  final int minBathrooms;
  final PropertyType? type;
  final bool isForRent;

  const SearchResultsScreen({
    super.key,
    required this.city,
    required this.priceRange,
    required this.minBedrooms,
    required this.minBathrooms,
    this.type,
    required this.isForRent,
  });

  @override
  Widget build(BuildContext context) {
    final FirebaseService firebaseService = FirebaseService();

    return Scaffold(
      appBar: AppBar(title: const Text('Resultados')),
      body: StreamBuilder<List<Property>>(
        stream: firebaseService.searchProperties(
          city: city,
          minPrice: priceRange.start,
          maxPrice: priceRange.end,
          minBedrooms: minBedrooms,
          minBathrooms: minBathrooms,
          type: type,
          isForRent: isForRent,
        ),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            // AQUÍ SALDRÁ EL BOTÓN PARA CREAR EL ÍNDICE SI HACE FALTA
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text('Error: ${snapshot.error}'),
              ),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final properties = snapshot.data ?? [];

          if (properties.isEmpty) {
            return const Center(child: Text('No hay resultados para estos filtros.'));
          }

          return ListView.builder(
            itemCount: properties.length,
            itemBuilder: (context, index) {
              return PropertyCard(
                property: properties[index],
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PropertyDetailScreen(property: properties[index]),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
