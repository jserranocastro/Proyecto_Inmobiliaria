import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firebase_service.dart';
import '../models/property.dart';
import '../widgets/property_card.dart';
import 'property_detail_screen.dart';

/// Pantalla que muestra los inmuebles guardados como favoritos por el usuario
class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final FirebaseService firebaseService = FirebaseService();

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        final user = authSnapshot.data;

        // Si no hay sesión, bloqueamos la vista
        if (user == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Mis Favoritos')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock_outline, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  const Text(
                    'Inicia sesión para ver tus favoritos',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: const Color(0xFFF8F9FD),
          appBar: AppBar(
            title: const Text('Mis Favoritos'),
            surfaceTintColor: Colors.transparent,
          ),
          body: StreamBuilder<List<String>>(
            // Primero obtenemos la lista de IDs favoritos del perfil del usuario
            stream: firebaseService.getUserFavorites(user.uid),
            builder: (context, favSnapshot) {
              if (favSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (favSnapshot.hasError) {
                return Center(child: Text('Error al cargar favoritos: ${favSnapshot.error}'));
              }

              final favoriteIds = favSnapshot.data ?? [];

              if (favoriteIds.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.favorite_border, size: 80, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      const Text(
                        'Aún no tienes favoritos',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Toca el corazón en cualquier anuncio para guardarlo.',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                );
              }

              return StreamBuilder<List<Property>>(
                // Con los IDs, recuperamos la información completa de cada inmueble
                stream: firebaseService.getFavoriteProperties(favoriteIds),
                builder: (context, propertiesSnapshot) {
                  if (propertiesSnapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final properties = propertiesSnapshot.data ?? [];

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
              );
            },
          ),
        );
      },
    );
  }
}
