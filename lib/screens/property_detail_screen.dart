import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/property.dart';
import '../services/firebase_service.dart';
import 'chat_screen.dart';

/// Pantalla de detalle de un inmueble específico con carrusel de imágenes y contacto
class PropertyDetailScreen extends StatefulWidget {
  final Property property;

  const PropertyDetailScreen({super.key, required this.property});

  @override
  State<PropertyDetailScreen> createState() => _PropertyDetailScreenState();
}

class _PropertyDetailScreenState extends State<PropertyDetailScreen> {
  final PageController _pageController = PageController();
  final FirebaseService _firebaseService = FirebaseService();
  int _currentPage = 0;

  /// Inicia el flujo de chat con el vendedor del inmueble
  void _contactSeller() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    
    // Verificación de sesión
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes iniciar sesión para contactar')),
      );
      return;
    }

    // Evitar que un usuario se contacte a sí mismo
    if (currentUser.uid == widget.property.userId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Este anuncio es tuyo')),
      );
      return;
    }

    // Loader mientras se crea/recupera la sala de chat
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final chatRoomId = await _firebaseService.getOrCreateChatRoom(
        currentUser.uid,
        widget.property.userId,
        widget.property.title,
        widget.property.userId,
      );

      final userData = await _firebaseService.getUserData(widget.property.userId);
      final sellerName = userData?['username'] ?? 'Vendedor';

      if (mounted) {
        Navigator.pop(context); // Cerramos el loader
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              chatRoomId: chatRoomId,
              otherUserId: widget.property.userId,
              otherUserName: sellerName,
              propertyTitle: widget.property.title,
              sellerId: widget.property.userId,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al crear el chat: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final property = widget.property;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // AppBar flexible con carrusel de imágenes
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(
                backgroundColor: Colors.white.withOpacity(0.9),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black, size: 28),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                children: [
                  if (property.images.isNotEmpty)
                    PageView.builder(
                      controller: _pageController,
                      onPageChanged: (index) {
                        setState(() {
                          _currentPage = index;
                        });
                      },
                      itemCount: property.images.length,
                      itemBuilder: (context, index) {
                        return InteractiveViewer(
                          child: Image.memory(
                            base64Decode(property.images[index]),
                            fit: BoxFit.cover,
                            width: double.infinity,
                          ),
                        );
                      },
                    )
                  else
                    Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.home, size: 100, color: Colors.white),
                    ),
                  
                  // Flechas de navegación para el carrusel
                  if (property.images.length > 1) ...[
                    Positioned(
                      left: 10,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: CircleAvatar(
                          backgroundColor: Colors.black26,
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                            onPressed: () {
                              _pageController.previousPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 10,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: CircleAvatar(
                          backgroundColor: Colors.black26,
                          child: IconButton(
                            icon: const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 20),
                            onPressed: () {
                              _pageController.nextPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ],

                  // Indicador de puntos inferior
                  if (property.images.length > 1)
                    Positioned(
                      bottom: 20,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          property.images.length,
                          (index) => Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _currentPage == index ? Colors.white : Colors.white54,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          // Contenido descriptivo del inmueble
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
                        fontWeight: FontWeight.w900,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${property.city} - ${property.address}',
                      style: TextStyle(fontSize: 18, color: Colors.grey[700]),
                    ),
                    const Divider(height: 32),
                    // Iconos de características
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _FeatureIcon(icon: Icons.king_bed, label: '${property.bedrooms} hab.'),
                        _FeatureIcon(icon: Icons.bathtub, label: '${property.bathrooms} baños'),
                        _FeatureIcon(icon: Icons.square_foot, label: '${property.area.toStringAsFixed(0)} m²'),
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
                    const SizedBox(height: 100), // Espacio para no quedar tapado por el botón de abajo
                  ],
                ),
              ),
            ]),
          ),
        ],
      ),
      // Botón persistente de contacto
      bottomSheet: Container(
        padding: const EdgeInsets.all(16),
        width: double.infinity,
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
        ),
        child: ElevatedButton(
          onPressed: _contactSeller,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 15),
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: const Text('Contactar', style: TextStyle(fontSize: 18)),
        ),
      ),
    );
  }
}

/// Widget interno para mostrar iconos con texto (habitaciones, baños, m2)
class _FeatureIcon extends StatelessWidget {
  final IconData icon;
  final String label;

  const _FeatureIcon({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 30, color: Colors.black),
        const SizedBox(height: 4),
        Text(
          label, 
          style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.black)
        ),
      ],
    );
  }
}
