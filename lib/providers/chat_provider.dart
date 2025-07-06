import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:messenger_flutter/models/message.dart';
import 'package:messenger_flutter/services/chat/chat_service.dart';
import 'package:messenger_flutter/services/storage/storage_service.dart';

class ChatProvider with ChangeNotifier {
  final ChatService _chatService;
  final StorageService _storageService;
  final String chatRoomId;
  StreamSubscription? _messagesSubscription;

  List<Message> _messages = [];
  bool _isLoading = true;
  final Map<String, Map<String, dynamic>> _userCache = {};
  Map<String, dynamic>? _receiverData;

  ChatProvider({
    required this.chatRoomId,
    required ChatService chatService,
    required StorageService storageService,
  })  : _chatService = chatService,
        _storageService = storageService {
    _listenToMessages();
  }

  List<Message> get messages => _messages;
  bool get isLoading => _isLoading;
  Map<String, Map<String, dynamic>> get userCache => _userCache;
  Map<String, dynamic>? get receiverData => _receiverData;

  void _listenToMessages() {
    _messagesSubscription =
        _chatService.getMessagesStream(chatRoomId).listen((messages) {
          _messages = messages;
          if (_isLoading) _isLoading = false;
          notifyListeners();
        });
  }

  Future<void> loadInitialData(bool isGroup, String? receiverId) async {
    if (isGroup) {
      await _loadGroupMembersData();
    } else {
      await _loadReceiverData(receiverId);
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _loadReceiverData(String? receiverId) async {
    if (receiverId == null) return;
    final doc =
    await FirebaseFirestore.instance.collection('Users').doc(receiverId).get();
    if (doc.exists) {
      _receiverData = doc.data();
    }
  }

  Future<void> _loadGroupMembersData() async {
    final chatRoomDoc = await FirebaseFirestore.instance
        .collection('chat_rooms')
        .doc(chatRoomId)
        .get();
    if (!chatRoomDoc.exists || chatRoomDoc.data()?['members'] == null) return;

    List<String> memberIds = List<String>.from(chatRoomDoc.data()!['members']);
    var userFutures = memberIds
        .where((id) => !_userCache.containsKey(id))
        .map((id) => FirebaseFirestore.instance.collection('Users').doc(id).get());

    final userDocs = await Future.wait(userFutures);
    for (var doc in userDocs) {
      if (doc.exists) {
        _userCache[doc.id] = doc.data()!;
      }
    }
  }

  Future<void> sendMessage(String text, String? receiverId,
      {String? replyToMessage, String? replyToSenderName}) async {
    if (text.trim().isEmpty) return;
    await _chatService.sendMessage(chatRoomId, text.trim(), receiverId,
        replyToMessage: replyToMessage, replyToSenderName: replyToSenderName);
  }

  Future<void> sendImage(String? receiverId) async {
    File? imageFile = await _storageService.pickImage();
    if (imageFile == null) return;

    DocumentReference messageRef =
    await _chatService.sendImageMessage(chatRoomId, imageFile: imageFile, receiverID: receiverId);

    try {
      final uploadResult = await _storageService.uploadFile(imageFile);
      if (uploadResult != null) {
        await _chatService.updateMessageWithImageUrl(
            messageRef, uploadResult['url']!, uploadResult['fileId']!);
      } else {
        await messageRef.delete();
      }
    } catch (e) {
      await messageRef.delete();
    }
  }

  void markMessagesAsRead() {
    _chatService.markMessagesAsRead(chatRoomId);
  }

  Future<void> deleteMessage(String messageId) async {
    await _chatService.deleteMessage(chatRoomId, messageId);
  }

  Future<void> editMessage(String messageId, String newText) async {
    await _chatService.editMessage(chatRoomId, messageId, newText);
  }

  Future<void> clearChatHistory() async {
    await _chatService.clearChatHistory(chatRoomId);
  }

  @override
  void dispose() {
    _messagesSubscription?.cancel();
    super.dispose();
  }
}