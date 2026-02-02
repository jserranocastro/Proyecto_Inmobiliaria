import 'package:flutter/material.dart';
import '../models/property.dart';
import '../widgets/property_card.dart';
import '../services/firebase_service.dart';
import 'property_detail_screen.dart';
import 'add_property_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final FirebaseService firebaseService = FirebaseService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inmuebles Disponibles'),
      ),
      body: StreamBuilder<List<Property>>(
        stream: firebaseService.getProperties(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final properties = snapshot.data ?? [];

          if (properties.isEmpty) {
            return const Center(
              child: Text('No hay inmuebles disponibles. ¡Añade el primero!'),
            );
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddPropertyScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
