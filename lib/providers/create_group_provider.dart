import 'package:flutter/material.dart';
import 'package:messenger_flutter/services/chat/chat_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
    return _chatService.getUsersStream().map((users) =>
        users.where((user) => user['uid'] != _auth.currentUser!.uid).toList());
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
      List<String> memberIds = _selectedUsers.keys.toList();
      await _chatService.createGroupChat(groupName.trim(), memberIds);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}