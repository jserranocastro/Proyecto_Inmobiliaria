import 'package:cloud_firestore/cloud_firestore.dart';

class ChatRoom {
  final String id;
  final List<String> participants;
  final String lastMessage;
  final DateTime lastMessageTime;
  final String propertyTitle;
  final String sellerId;
  final Map<String, bool> readStatus; // userId -> isRead

  ChatRoom({
    required this.id,
    required this.participants,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.propertyTitle,
    required this.sellerId,
    required this.readStatus,
  });

  factory ChatRoom.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map;
    Map<String, dynamic> rawReadStatus = data['readStatus'] ?? {};
    
    return ChatRoom(
      id: doc.id,
      participants: List<String>.from(data['participants'] ?? []),
      lastMessage: data['lastMessage'] ?? '',
      lastMessageTime: (data['lastMessageTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      propertyTitle: data['propertyTitle'] ?? 'Consulta Inmueble',
      sellerId: data['sellerId'] ?? '',
      readStatus: rawReadStatus.map((key, value) => MapEntry(key, value as bool)),
    );
  }
}
