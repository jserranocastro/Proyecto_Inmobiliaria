import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/property.dart';
import '../models/chat_message.dart';
import '../models/chat_room.dart';

/// Servicio centralizado para gestionar todas las operaciones con Firestore
class FirebaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Referencias a las colecciones principales
  CollectionReference get _propertiesRef => _db.collection('properties');
  CollectionReference get _usersRef => _db.collection('users');
  CollectionReference get _chatRoomsRef => _db.collection('chat_rooms');

  /// Obtiene propiedades filtradas por provincia y ciudad
  Stream<List<Property>> getPropertiesByLocation(String province, String city) {
    return _propertiesRef
        .where('province', isEqualTo: province)
        .where('city', isEqualTo: city)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Property.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }

  /// Obtiene todas las propiedades publicadas
  Stream<List<Property>> getProperties() {
    return _propertiesRef.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return Property.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }

  /// Obtiene las propiedades publicadas por un usuario específico
  Stream<List<Property>> getPropertiesForUser(String userId) {
    return _propertiesRef
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Property.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }

  /// Buscador avanzado con múltiples filtros (precio, habitaciones, tipo...)
  Stream<List<Property>> searchProperties({
    required String city,
    required double minPrice,
    required double maxPrice,
    required int minBedrooms,
    required int minBathrooms,
    PropertyType? type,
    required bool isForRent,
  }) {
    Query query = _propertiesRef;
    
    // Filtros de Firestore (indexados)
    query = query.where('isForRent', isEqualTo: isForRent);
    if (city.isNotEmpty) query = query.where('city', isEqualTo: city);
    if (type != null) query = query.where('type', isEqualTo: type.index);
    
    query = query.where('price', isGreaterThanOrEqualTo: minPrice)
                 .where('price', isLessThanOrEqualTo: maxPrice);

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return Property.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }).where((p) {
        // El filtrado de habitaciones/baños se hace en memoria para evitar índices complejos
        return p.bedrooms >= minBedrooms && p.bathrooms >= minBathrooms;
      }).toList();
    });
  }

  // Métodos CRUD para propiedades
  Future<void> addProperty(Property property) async {
    await _propertiesRef.add(property.toMap());
  }

  Future<void> updateProperty(Property property) {
    return _propertiesRef.doc(property.id).update(property.toMap());
  }

  Future<void> deleteProperty(String propertyId) {
    return _propertiesRef.doc(propertyId).delete();
  }

  /// Añade o quita una propiedad de la lista de favoritos del usuario
  Future<void> toggleFavorite(String userId, String propertyId) async {
    final userDoc = _usersRef.doc(userId);
    final doc = await userDoc.get();

    if (!doc.exists) {
      await userDoc.set({'favorites': [propertyId]});
      return;
    }

    final data = doc.data() as Map<String, dynamic>;
    List<String> favorites = List<String>.from(data['favorites'] ?? []);

    if (favorites.contains(propertyId)) {
      favorites.remove(propertyId);
    } else {
      favorites.add(propertyId);
    }

    await userDoc.update({'favorites': favorites});
  }

  /// Escucha en tiempo real los IDs de favoritos del usuario
  Stream<List<String>> getUserFavorites(String userId) {
    return _usersRef.doc(userId).snapshots().map((snapshot) {
      if (!snapshot.exists) return [];
      final data = snapshot.data() as Map<String, dynamic>;
      return List<String>.from(data['favorites'] ?? []);
    });
  }

  /// Obtiene los detalles de las propiedades marcadas como favoritas
  Stream<List<Property>> getFavoriteProperties(List<String> favoriteIds) {
    if (favoriteIds.isEmpty) return Stream.value([]);
    // Limitamos a 10 para evitar errores de la cláusula 'whereIn' de Firestore
    return _propertiesRef
        .where(FieldPath.documentId, whereIn: favoriteIds.take(10).toList())
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Property.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }

  // --- Sistema de Chat ---

  /// Obtiene un chat existente o crea uno nuevo entre dos usuarios
  Future<String> getOrCreateChatRoom(String user1, String user2, String propertyTitle, String sellerId) async {
    List<String> ids = [user1, user2];
    ids.sort(); // Ordenamos para que el ID sea consistente (userA_userB siempre igual)
    String chatRoomId = ids.join('_');

    final doc = await _chatRoomsRef.doc(chatRoomId).get();
    if (!doc.exists) {
      await _chatRoomsRef.doc(chatRoomId).set({
        'participants': ids,
        'lastMessage': '',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'propertyTitle': propertyTitle,
        'sellerId': sellerId,
        'readStatus': {user1: true, user2: true},
      });
    }
    return chatRoomId;
  }

  /// Envía un mensaje y actualiza la previsualización del chat
  Future<void> sendMessage(String chatRoomId, ChatMessage message) async {
    await _chatRoomsRef.doc(chatRoomId).collection('messages').add(message.toMap());
    
    String lastMessageText = message.type == MessageType.image ? '📷 Foto' : message.text;

    // Al enviar, marcamos como "no leído" para el receptor
    await _chatRoomsRef.doc(chatRoomId).update({
      'lastMessage': lastMessageText,
      'lastMessageTime': FieldValue.serverTimestamp(),
      'readStatus.${message.receiverId}': false,
    });
  }

  /// Borra un mensaje y recalcula el último mensaje para la lista de chats
  Future<void> deleteMessage(String chatRoomId, String messageId) async {
    final roomRef = _chatRoomsRef.doc(chatRoomId);
    
    await roomRef.collection('messages').doc(messageId).delete();

    // Actualizamos el 'lastMessage' con el anterior más reciente
    final lastMessages = await roomRef.collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(1)
        .get();

    if (lastMessages.docs.isNotEmpty) {
      final lastMsgDoc = lastMessages.docs.first;
      final lastMsg = ChatMessage.fromFirestore(lastMsgDoc);
      String lastMessageText = lastMsg.type == MessageType.image ? '📷 Foto' : lastMsg.text;

      await roomRef.update({
        'lastMessage': lastMessageText,
        'lastMessageTime': lastMsgDoc['timestamp'],
      });
    } else {
      await roomRef.update({
        'lastMessage': '',
      });
    }
  }

  /// Marca todos los mensajes de un chat como leídos para el usuario
  Future<void> markAsRead(String chatRoomId, String userId) async {
    await _chatRoomsRef.doc(chatRoomId).update({
      'readStatus.$userId': true,
    });
  }

  /// Escucha los mensajes de un chat específico ordenados por tiempo
  Stream<List<ChatMessage>> getMessages(String chatRoomId) {
    return _chatRoomsRef
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => ChatMessage.fromFirestore(doc)).toList();
    });
  }

  /// Obtiene todos los chats donde participa el usuario
  Stream<List<ChatRoom>> getUserChatRooms(String userId) {
    return _chatRoomsRef
        .where('participants', arrayContains: userId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => ChatRoom.fromFirestore(doc)).toList();
    });
  }

  /// Cuenta cuántos chats tienen mensajes sin leer para el usuario
  Stream<int> getUnreadCount(String userId) {
    return getUserChatRooms(userId).map((rooms) {
      return rooms.where((room) => room.readStatus[userId] == false).length;
    });
  }

  /// Obtiene datos básicos de un usuario (para mostrar nombres en el chat, etc)
  Future<Map<String, dynamic>?> getUserData(String userId) async {
    final doc = await _usersRef.doc(userId).get();
    return doc.data() as Map<String, dynamic>?;
  }
}
