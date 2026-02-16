import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/chat_room.dart';
import '../services/firebase_service.dart';
import 'chat_screen.dart';

class InboxScreen extends StatelessWidget {
  const InboxScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final FirebaseService firebaseService = FirebaseService();

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        final user = authSnapshot.data;

        if (user == null) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Mensajes'),
              surfaceTintColor: Colors.transparent,
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock_outline, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  const Text(
                    'Inicia sesión para ver tus mensajes',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Mensajes'),
            surfaceTintColor: Colors.transparent,
          ),
          body: StreamBuilder<List<ChatRoom>>(
            stream: firebaseService.getUserChatRooms(user.uid),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final rooms = snapshot.data ?? [];

              if (rooms.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.chat_bubble_outline, size: 80, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      const Text(
                        'No tienes conversaciones aún',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                itemCount: rooms.length,
                itemBuilder: (context, index) {
                  final room = rooms[index];
                  final bool isSeller = user.uid == room.sellerId;
                  final otherUserId = room.participants.firstWhere(
                    (id) => id != user.uid,
                    orElse: () => '',
                  );

                  return FutureBuilder<Map<String, dynamic>?>(
                    future: firebaseService.getUserData(otherUserId),
                    builder: (context, userSnapshot) {
                      final userData = userSnapshot.data;
                      final otherUserName = userData?['username'] ?? 'Usuario';
                      
                      // Lógica de visualización:
                      // Si soy el vendedor -> veo el nombre del interesado.
                      // Si soy el interesado -> veo el título del anuncio.
                      final String displayTitle = isSeller ? otherUserName : room.propertyTitle;

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                          child: Text(displayTitle[0].toUpperCase()),
                        ),
                        title: Text(
                          displayTitle,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          room.lastMessage.isEmpty ? 'Nueva conversación' : room.lastMessage,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: const Icon(Icons.chevron_right, size: 20),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChatScreen(
                                chatRoomId: room.id,
                                otherUserId: otherUserId,
                                otherUserName: otherUserName,
                                propertyTitle: room.propertyTitle,
                                sellerId: room.sellerId,
                              ),
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
