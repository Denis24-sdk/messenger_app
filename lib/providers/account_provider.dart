import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:messenger_flutter/services/storage/storage_service.dart';

class AccountProvider with ChangeNotifier {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final StorageService _storageService;

  User? _currentUser;
  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  bool _isUploading = false;
  bool _isEditingName = false;
  bool _isEditingBio = false;

  User? get currentUser => _currentUser;
  Map<String, dynamic>? get userData => _userData;
  bool get isLoading => _isLoading;
  bool get isUploading => _isUploading;
  bool get isEditingName => _isEditingName;
  bool get isEditingBio => _isEditingBio;

  AccountProvider({
    required FirebaseAuth auth,
    required FirebaseFirestore firestore,
    required StorageService storageService,
  })  : _auth = auth,
        _firestore = firestore,
        _storageService = storageService {
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    _currentUser = _auth.currentUser;
    if (_currentUser == null) {
      _isLoading = false;
      notifyListeners();
      return;
    }
    try {
      DocumentSnapshot userDoc =
      await _firestore.collection('Users').doc(_currentUser!.uid).get();
      if (userDoc.exists) {
        _userData = userDoc.data() as Map<String, dynamic>;
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setEditingName(bool isEditing, {String? initialValue}) {
    _isEditingName = isEditing;
    if (!isEditing && initialValue != null) {
    }
    notifyListeners();
  }

  void setEditingBio(bool isEditing) {
    _isEditingBio = isEditing;
    notifyListeners();
  }

  Future<void> updateUsername(String newName) async {
    if (newName.trim().isEmpty) throw Exception('Имя не может быть пустым');

    await _firestore.collection('Users').doc(_currentUser!.uid).update({'username': newName.trim()});
    _userData?['username'] = newName.trim();
    _isEditingName = false;
    notifyListeners();
  }

  Future<void> updateBio(String newBio) async {
    await _firestore.collection('Users').doc(_currentUser!.uid).update({'bio': newBio.trim()});
    _userData?['bio'] = newBio.trim();
    _isEditingBio = false;
    notifyListeners();
  }

  Future<void> uploadAvatar() async {
    File? image = await _storageService.pickImage();
    if (image == null) return;

    _isUploading = true;
    notifyListeners();

    try {
      if (_userData?['avatarFileId'] != null) {
        await _storageService.deleteFile(_userData!['avatarFileId']);
      }

      final uploadResult = await _storageService.uploadFile(image);

      if (uploadResult != null) {
        String downloadUrl = uploadResult['url']!;
        String fileId = uploadResult['fileId']!;

        await _firestore.collection('Users').doc(_currentUser!.uid).update({
          'avatarUrl': downloadUrl,
          'avatarFileId': fileId,
        });

        _userData?['avatarUrl'] = downloadUrl;
        _userData?['avatarFileId'] = fileId;
      }
    } finally {
      _isUploading = false;
      notifyListeners();
    }
  }
}