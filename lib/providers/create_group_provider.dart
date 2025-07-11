import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:messenger_flutter/services/chat/chat_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

class CreateGroupProvider with ChangeNotifier {
  final ChatService _chatService;
  final FirebaseAuth _auth;

  CreateGroupProvider({required ChatService chatService, required FirebaseAuth auth})
      : _chatService = chatService,
        _auth = auth;

  final Map<String, Map<String, dynamic>> _selectedUsers = {};
  bool _isLoading = false;

  Map<String, Map<String, dynamic>> get selectedUsers => _selectedUsers;
  bool get isLoading => _isLoading;

  Stream<List<Map<String, dynamic>>> getUsersStream() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return Stream.value([]);
    }

    // Получаем поток чатов текущего пользователя
    return FirebaseFirestore.instance
        .collection('chat_rooms')
        .where('members', arrayContains: currentUser.uid)
        .snapshots()
        .asyncExpand((querySnapshot) {

      final chatPartnerIds = <String>{};
      for (var doc in querySnapshot.docs) {
        final members = List<String>.from(doc.data()['members'] ?? []);
        for (var memberId in members) {
          if (memberId != currentUser.uid) {
            chatPartnerIds.add(memberId);
          }
        }
      }

      if (chatPartnerIds.isEmpty) {
        return Stream.value([]);
      }

      // Получаем поток всех пользователей и фильтруем его
      return _chatService.getUsersStream().map((users) {
        return users.where((user) {
          final uid = user['uid'];
          return uid != currentUser.uid && chatPartnerIds.contains(uid);
        }).toList();
      });
    });
  }

  void toggleUserSelection(String uid, Map<String, dynamic> userData) {
    if (_selectedUsers.containsKey(uid)) {
      _selectedUsers.remove(uid);
    } else {
      _selectedUsers[uid] = userData;
    }
    notifyListeners();
  }

  Future<void> createGroup(String groupName) async {
    if (groupName.trim().isEmpty) {
      throw Exception("Введите название группы");
    }
    if (_selectedUsers.length < 2) {
      throw Exception("Выберите хотя бы двух участников");
    }

    _isLoading = true;
    notifyListeners();

    try {
      // Добавляем текущего пользователя в список участников группы
      final currentUserId = _auth.currentUser!.uid;
      final memberIds = _selectedUsers.keys.toList();
      if (!memberIds.contains(currentUserId)) {
        memberIds.add(currentUserId);
      }

      await _chatService.createGroupChat(groupName.trim(), memberIds);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}