import 'dart:convert';
import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/chat_message.dart';
import '../services/firebase_service.dart';

class ChatScreen extends StatefulWidget {
  final String chatRoomId;
  final String otherUserId;
  final String otherUserName;
  final String propertyTitle;
  final String sellerId;

  const ChatScreen({
    super.key,
    required this.chatRoomId,
    required this.otherUserId,
    required this.otherUserName,
    required this.propertyTitle,
    required this.sellerId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final FirebaseService _firebaseService = FirebaseService();
  final String _currentUserId = FirebaseAuth.instance.currentUser!.uid;
  final ImagePicker _picker = ImagePicker();

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final message = ChatMessage(
      id: '',
      senderId: _currentUserId,
      receiverId: widget.otherUserId,
      text: _messageController.text.trim(),
      timestamp: DateTime.now(),
      type: MessageType.text,
    );

    await _firebaseService.sendMessage(widget.chatRoomId, message);
    _messageController.clear();
  }

  Future<void> _sendImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(
      source: source,
      imageQuality: 50, // Comprimimos para no exceder límites de Firestore (1MB por doc)
      maxWidth: 800,
    );

    if (image != null) {
      final bytes = await image.readAsBytes();
      final String base64Image = base64Encode(bytes);

      final message = ChatMessage(
        id: '',
        senderId: _currentUserId,
        receiverId: widget.otherUserId,
        imageBase64: base64Image,
        timestamp: DateTime.now(),
        type: MessageType.image,
      );

      await _firebaseService.sendMessage(widget.chatRoomId, message);
    }
  }

  void _showImageSourceActionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galería'),
              onTap: () {
                Navigator.of(context).pop();
                _sendImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Cámara'),
              onTap: () {
                Navigator.of(context).pop();
                _sendImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isSeller = _currentUserId == widget.sellerId;
    final String displayTitle = isSeller ? widget.otherUserName : widget.propertyTitle;

    return Scaffold(
      appBar: AppBar(
        title: Text(displayTitle),
        surfaceTintColor: Colors.transparent,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
              stream: _firebaseService.getMessages(widget.chatRoomId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data ?? [];

                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message.senderId == _currentUserId;

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: message.type == MessageType.text 
                          ? const EdgeInsets.symmetric(horizontal: 16, vertical: 10)
                          : const EdgeInsets.all(4),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.7,
                        ),
                        decoration: BoxDecoration(
                          color: isMe ? Theme.of(context).colorScheme.primary : Colors.grey[200],
                          borderRadius: BorderRadius.circular(20).copyWith(
                            bottomRight: isMe ? const Radius.circular(0) : const Radius.circular(20),
                            bottomLeft: !isMe ? const Radius.circular(0) : const Radius.circular(20),
                          ),
                        ),
                        child: message.type == MessageType.text
                            ? Text(
                                message.text,
                                style: TextStyle(
                                  color: isMe ? Colors.white : Colors.black,
                                ),
                              )
                            : ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.memory(
                                  base64Decode(message.imageBase64!),
                                  fit: BoxFit.cover,
                                ),
                              ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => _showImageSourceActionSheet(context),
                  icon: const Icon(Icons.add_a_photo_outlined),
                  color: Theme.of(context).colorScheme.primary,
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Escribe un mensaje...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _sendMessage,
                  icon: const Icon(Icons.send),
                  color: Theme.of(context).colorScheme.primary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
