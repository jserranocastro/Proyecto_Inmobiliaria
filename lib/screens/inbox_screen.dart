import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/chat_room.dart';
import '../services/firebase_service.dart';
import 'chat_screen.dart';

class InboxScreen extends StatelessWidget {
  const InboxScreen({super.key});

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) return 'ahora';
    if (difference.inMinutes < 60) return 'hace ${difference.inMinutes} min';
    if (difference.inHours < 24) return 'hace ${difference.inHours} h';
    if (difference.inDays < 7) return DateFormat('EEEE', 'es').format(dateTime);
    return DateFormat('dd/MM/yyyy').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    final FirebaseService firebaseService = FirebaseService();

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        final user = authSnapshot.data;

        if (user == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Mensajes')),
            body: const Center(child: Text('Inicia sesión para ver tus mensajes')),
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
                return const Center(child: Text('No tienes conversaciones aún'));
              }

              return ListView.builder(
                itemCount: rooms.length,
                itemBuilder: (context, index) {
                  final room = rooms[index];
                  final bool isUnread = room.readStatus[user.uid] == false;
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
                      final String displayTitle = isSeller ? otherUserName : room.propertyTitle;

                      return Container(
                        color: isUnread ? Theme.of(context).colorScheme.primary.withOpacity(0.05) : null,
                        child: ListTile(
                          leading: Badge(
                            isLabelVisible: isUnread,
                            backgroundColor: Colors.red,
                            child: CircleAvatar(
                              backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                              child: Text(displayTitle[0].toUpperCase()),
                            ),
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  displayTitle,
                                  style: TextStyle(
                                    fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                                    fontSize: 16,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                _formatDateTime(room.lastMessageTime),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isUnread ? Theme.of(context).colorScheme.primary : Colors.grey,
                                  fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                          subtitle: Text(
                            room.lastMessage.isEmpty ? 'Nueva conversación' : room.lastMessage,
                            style: TextStyle(
                              fontWeight: isUnread ? FontWeight.w600 : FontWeight.normal,
                              color: isUnread ? Colors.black87 : Colors.grey[600],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: () {
                            firebaseService.markAsRead(room.id, user.uid);
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
                        ),
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
