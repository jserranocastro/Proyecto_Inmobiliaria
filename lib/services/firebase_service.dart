import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/property.dart';
import '../models/chat_message.dart';
import '../models/chat_room.dart';

class FirebaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference get _propertiesRef => _db.collection('properties');
  CollectionReference get _usersRef => _db.collection('users');
  CollectionReference get _chatRoomsRef => _db.collection('chat_rooms');

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

  Stream<List<Property>> getProperties() {
    return _propertiesRef.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return Property.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }

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
    query = query.where('isForRent', isEqualTo: isForRent);
    if (city.isNotEmpty) query = query.where('city', isEqualTo: city);
    if (type != null) query = query.where('type', isEqualTo: type.index);
    query = query.where('price', isGreaterThanOrEqualTo: minPrice)
                 .where('price', isLessThanOrEqualTo: maxPrice);

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return Property.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }).where((p) {
        return p.bedrooms >= minBedrooms && p.bathrooms >= minBathrooms;
      }).toList();
    });
  }

  Future<void> addProperty(Property property) async {
    await _propertiesRef.add(property.toMap());
  }

  Future<void> updateProperty(Property property) {
    return _propertiesRef.doc(property.id).update(property.toMap());
  }

  Future<void> deleteProperty(String propertyId) {
    return _propertiesRef.doc(propertyId).delete();
  }

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

  Stream<List<String>> getUserFavorites(String userId) {
    return _usersRef.doc(userId).snapshots().map((snapshot) {
      if (!snapshot.exists) return [];
      final data = snapshot.data() as Map<String, dynamic>;
      return List<String>.from(data['favorites'] ?? []);
    });
  }

  Stream<List<Property>> getFavoriteProperties(List<String> favoriteIds) {
    if (favoriteIds.isEmpty) return Stream.value([]);
    return _propertiesRef
        .where(FieldPath.documentId, whereIn: favoriteIds.take(10).toList())
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Property.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }

  // --- Mensajería Mejorada con Notificaciones ---

  Future<String> getOrCreateChatRoom(String user1, String user2, String propertyTitle, String sellerId) async {
    List<String> ids = [user1, user2];
    ids.sort();
    String chatRoomId = ids.join('_');

    final doc = await _chatRoomsRef.doc(chatRoomId).get();
    if (!doc.exists) {
      await _chatRoomsRef.doc(chatRoomId).set({
        'participants': ids,
        'lastMessage': '',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'propertyTitle': propertyTitle,
        'sellerId': sellerId,
        'readStatus': {user1: true, user2: true}, // Inicialmente leído por ambos
      });
    }
    return chatRoomId;
  }

  Future<void> sendMessage(String chatRoomId, ChatMessage message) async {
    await _chatRoomsRef.doc(chatRoomId).collection('messages').add(message.toMap());
    
    String lastMessageText = message.type == MessageType.image ? '📷 Foto' : message.text;

    // Al enviar, el receptor tiene el mensaje como "no leído"
    await _chatRoomsRef.doc(chatRoomId).update({
      'lastMessage': lastMessageText,
      'lastMessageTime': FieldValue.serverTimestamp(),
      'readStatus.${message.receiverId}': false,
    });
  }

  Future<void> deleteMessage(String chatRoomId, String messageId) async {
    final roomRef = _chatRoomsRef.doc(chatRoomId);
    
    // 1. Borrar el mensaje de la subcolección
    await roomRef.collection('messages').doc(messageId).delete();

    // 2. Buscar el nuevo mensaje más reciente para actualizar la vista previa en la bandeja de entrada
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
      // Si ya no quedan mensajes en el chat
      await roomRef.update({
        'lastMessage': '',
        // Mantenemos el lastMessageTime anterior o podríamos dejarlo igual
      });
    }
  }

  Future<void> markAsRead(String chatRoomId, String userId) async {
    await _chatRoomsRef.doc(chatRoomId).update({
      'readStatus.$userId': true,
    });
  }

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

  Stream<List<ChatRoom>> getUserChatRooms(String userId) {
    return _chatRoomsRef
        .where('participants', arrayContains: userId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => ChatRoom.fromFirestore(doc)).toList();
    });
  }

  Stream<int> getUnreadCount(String userId) {
    return getUserChatRooms(userId).map((rooms) {
      return rooms.where((room) => room.readStatus[userId] == false).length;
    });
  }

  Future<Map<String, dynamic>?> getUserData(String userId) async {
    final doc = await _usersRef.doc(userId).get();
    return doc.data() as Map<String, dynamic>?;
  }
}
