import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

enum AuthStatus { uninitialized, authenticated, authenticating, unauthenticated }

class AuthService with ChangeNotifier, WidgetsBindingObserver {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  StreamSubscription<User?>? _authStateSubscription;

  AuthStatus _status = AuthStatus.uninitialized;
  User? _user;

  AuthService({required FirebaseAuth auth, required FirebaseFirestore firestore})
      : _auth = auth,
        _firestore = firestore {
    WidgetsBinding.instance.addObserver(this);
    _authStateSubscription = _auth.authStateChanges().listen(_onAuthStateChanged);
  }

  AuthStatus get status => _status;
  User? get user => _user;

  Future<void> _onAuthStateChanged(User? user) async {
    if (user == null) {
      _status = AuthStatus.unauthenticated;
    } else {
      _user = user;
      await _updateUserStatus(true);
      _status = AuthStatus.authenticated;
    }
    notifyListeners();
  }

  Future<void> login(String username, String password) async {
    _status = AuthStatus.authenticating;
    notifyListeners();

    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('Users')
          .where('username', isEqualTo: username)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        throw Exception('Пользователь с таким логином не найден');
      }
      String userEmail = querySnapshot.docs.first['email'];

      await _auth.signInWithEmailAndPassword(
          email: userEmail, password: password);
    } catch (e) {
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> register(String username, String email, String password, String confirmPassword) async {
    _status = AuthStatus.authenticating;
    notifyListeners();

    try {
      if (password != confirmPassword) {
        throw Exception("Пароли не совпадают!");
      }

      if (username.trim().isEmpty) {
        throw Exception("Логин не может быть пустым");
      }

      final existingUser = await _firestore
          .collection('Users')
          .where('username', isEqualTo: username.trim())
          .limit(1)
          .get();

      if (existingUser.docs.isNotEmpty) {
        throw Exception("Этот логин уже занят");
      }

      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      await _firestore.collection("Users").doc(userCredential.user!.uid).set({
        'uid': userCredential.user!.uid,
        'email': email.trim(),
        'username': username.trim(),
        'isOnline': true,
        'last_seen': Timestamp.now(),
      });
    } catch (e) {
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _updateUserStatus(false);
    await _auth.signOut();
  }

  Future<void> _updateUserStatus(bool isOnline) async {
    if (_user == null) return;
    try {
      await _firestore
          .collection("Users")
          .doc(_user!.uid)
          .update({'isOnline': isOnline, 'last_seen': Timestamp.now()});
    } catch (e) {
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (_user == null) return;

    switch (state) {
      case AppLifecycleState.resumed:
        _updateUserStatus(true);
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        _updateUserStatus(false);
        break;
    }
  }

  @override
  void dispose() {
    _authStateSubscription?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}