import 'package:cloud_firestore/cloud_firestore.dart';

class ChatRoom {
  final String id;
  final List<String> participants;
  final String lastMessage;
  final DateTime lastMessageTime;

  ChatRoom({
    required this.id,
    required this.participants,
    required this.lastMessage,
    required this.lastMessageTime,
  });

  factory ChatRoom.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map;
    return ChatRoom(
      id: doc.id,
      participants: List<String>.from(data['participants'] ?? []),
      lastMessage: data['lastMessage'] ?? '',
      lastMessageTime: (data['lastMessageTime'] as Timestamp).toDate(),
    );
  }
}
