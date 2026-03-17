import 'package:cloud_firestore/cloud_firestore.dart';

/// Representa una sala de chat entre un comprador y un vendedor
class ChatRoom {
  final String id;
  final List<String> participants; // IDs de los dos usuarios participantes
  final String lastMessage; // Previsualización del último mensaje enviado
  final DateTime lastMessageTime;
  final String propertyTitle; // Título de la propiedad por la que se consulta
  final String sellerId; // Identificador del vendedor para lógica de UI
  final Map<String, bool> readStatus; // Mapa de 'userId: leido(bool)' para notificaciones

  ChatRoom({
    required this.id,
    required this.participants,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.propertyTitle,
    required this.sellerId,
    required this.readStatus,
  });

  /// Crea un objeto ChatRoom a partir de los datos de Firestore
  factory ChatRoom.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map;
    Map<String, dynamic> rawReadStatus = data['readStatus'] ?? {};
    
    return ChatRoom(
      id: doc.id,
      participants: List<String>.from(data['participants'] ?? []),
      lastMessage: data['lastMessage'] ?? '',
      // Si el timestamp es nulo (por latencia), usamos la fecha actual
      lastMessageTime: (data['lastMessageTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      propertyTitle: data['propertyTitle'] ?? 'Consulta Inmueble',
      sellerId: data['sellerId'] ?? '',
      readStatus: rawReadStatus.map((key, value) => MapEntry(key, value as bool)),
    );
  }
}
