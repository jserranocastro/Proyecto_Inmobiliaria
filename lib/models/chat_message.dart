import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageType { text, image }

class ChatMessage {
  final String id;
  final String senderId;
  final String receiverId;
  final String text;
  final String? imageBase64;
  final DateTime timestamp;
  final MessageType type;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.receiverId,
    this.text = '',
    this.imageBase64,
    required this.timestamp,
    this.type = MessageType.text,
  });

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'receiverId': receiverId,
      'text': text,
      'imageBase64': imageBase64,
      'timestamp': Timestamp.fromDate(timestamp),
      'type': type.index,
    };
  }

  factory ChatMessage.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map;
    return ChatMessage(
      id: doc.id,
      senderId: data['senderId'] ?? '',
      receiverId: data['receiverId'] ?? '',
      text: data['text'] ?? '',
      imageBase64: data['imageBase64'],
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      type: MessageType.values[data['type'] ?? 0],
    );
  }
}
