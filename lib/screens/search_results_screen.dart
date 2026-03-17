import 'package:flutter/material.dart';
import '../models/property.dart';
import '../widgets/property_card.dart';
import '../services/firebase_service.dart';
import 'property_detail_screen.dart';

/// Pantalla que muestra el listado de inmuebles filtrados tras una búsqueda
class SearchResultsScreen extends StatelessWidget {
  final String province;
  final String city;
  final RangeValues priceRange;
  final int minBedrooms;
  final int minBathrooms;
  final PropertyType? type;
  final bool isForRent;

  const SearchResultsScreen({
    super.key,
    required this.province,
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
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Resultados'),
        surfaceTintColor: Colors.transparent,
      ),
      body: Column(
        children: [
          // Cabecera con resumen de los filtros aplicados (Ubicación y modo)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              children: [
                const Icon(Icons.location_on, color: Color(0xFF0052D4), size: 18),
                const SizedBox(width: 8),
                Text(
                  '$city, $province',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const Spacer(),
                Text(
                  isForRent ? 'Alquiler' : 'Compra',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Property>>(
              // Ejecutamos la búsqueda con todos los criterios seleccionados
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

                // Empty state por si no hay coincidencias
                if (properties.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off_rounded, size: 80, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        const Text(
                          'No hay resultados',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Prueba con otros filtros',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
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
          ),
        ],
      ),
    );
  }
}
