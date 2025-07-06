import 'dart:async';
import 'package:flutter/material.dart';
import 'package:messenger_flutter/models/chat_room.dart';
import 'package:messenger_flutter/services/chat/chat_service.dart';

enum ChatFilter { all, private, group }

class HomeProvider with ChangeNotifier {
  final ChatService _chatService;
  StreamSubscription? _chatRoomsSubscription;

  List<ChatRoom> _chatRooms = [];
  bool _isLoading = true;
  ChatFilter _currentFilter = ChatFilter.all;

  HomeProvider({required ChatService chatService}) : _chatService = chatService {
    _listenToChatRooms();
  }

  List<ChatRoom> get chatRooms => _chatRooms;
  List<ChatRoom> get filteredChatRooms {
    switch (_currentFilter) {
      case ChatFilter.all:
        return _chatRooms;
      case ChatFilter.private:
        return _chatRooms.where((room) => !room.isGroup).toList();
      case ChatFilter.group:
        return _chatRooms.where((room) => room.isGroup).toList();
    }
  }

  bool get isLoading => _isLoading;
  ChatFilter get currentFilter => _currentFilter;

  void _listenToChatRooms() {
    _chatRoomsSubscription = _chatService.getChatRoomsStream().listen((rooms) {
      _chatRooms = rooms;
      _isLoading = false;
      notifyListeners();
    });
  }

  void setFilter(ChatFilter newFilter) {
    if (_currentFilter != newFilter) {
      _currentFilter = newFilter;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _chatRoomsSubscription?.cancel();
    super.dispose();
  }
}