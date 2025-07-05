import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? _currentUser;
  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  bool _isEditingName = false;

  late TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  // Загружает данные пользователя из Firestore
  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    _currentUser = _auth.currentUser;
    if (_currentUser != null) {
      try {
        DocumentSnapshot userDoc =
        await _firestore.collection('Users').doc(_currentUser!.uid).get();
        if (userDoc.exists) {
          setState(() {
            _userData = userDoc.data() as Map<String, dynamic>;
            _nameController.text = _userData?['username'] ?? '';
          });
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка загрузки данных: $e')),
        );
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  // Обновляет имя пользователя в Firestore
  Future<void> _updateUsername() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Имя не может быть пустым')),
      );
      return;
    }

    if (_currentUser != null) {
      try {
        await _firestore
            .collection('Users')
            .doc(_currentUser!.uid)
            .update({'username': _nameController.text.trim()});

        setState(() {
          _userData?['username'] = _nameController.text.trim();
          _isEditingName = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Имя успешно обновлено')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка обновления имени: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Аккаунт'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _userData == null
          ? const Center(child: Text('Не удалось загрузить данные пользователя.'))
          : _buildUserProfile(),
    );
  }

  Widget _buildUserProfile() {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        Center(
          child: Stack(
            children: [
              const CircleAvatar(
                radius: 60,
                child: Icon(Icons.person, size: 60), // Заглушка
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: CircleAvatar(
                  backgroundColor: Theme.of(context).primaryColor,
                  child: IconButton(
                    icon: const Icon(Icons.camera_alt, color: Colors.white),
                    // TODO: Реализовать загрузку/редактирование аватара
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Редактирование аватара в разработке')),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Блок редактирования имени
        _isEditingName ? _buildNameEditor() : _buildNameDisplay(),

        const SizedBox(height: 8),
        Center(
          child: Text(
            _userData?['email'] ?? 'Email не найден',
            style: const TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ),
        const SizedBox(height: 24),
        const Divider(),
        const SizedBox(height: 16),

        //  Кнопки
        ListTile(
          leading: const Icon(Icons.settings),
          title: const Text('Настройки'),
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Раздел "Настройки" в разработке')),
            );
          },
        ),
        ListTile(
          leading: const Icon(Icons.info_outline),
          title: const Text('Информация'),
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Раздел "Информация" в разработке')),
            );
          },
        ),
      ],
    );
  }

  // Виджет для отображения имени
  Widget _buildNameDisplay() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          _userData?['username'] ?? 'Имя не указано',
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        IconButton(
          icon: const Icon(Icons.edit, size: 20, color: Colors.grey),
          onPressed: () {
            setState(() {
              _isEditingName = true;
            });
          },
        ),
      ],
    );
  }

  // Виджет для редактирования имени
  Widget _buildNameEditor() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _nameController,
            autofocus: true,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            decoration: const InputDecoration(
              hintText: 'Введите имя',
              border: InputBorder.none,
              focusedBorder: UnderlineInputBorder(),
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.check, color: Colors.green),
          onPressed: _updateUsername,
        ),
        IconButton(
          icon: const Icon(Icons.close, color: Colors.red),
          onPressed: () {
            setState(() {
              _isEditingName = false;
              _nameController.text = _userData?['username'] ?? '';
            });
          },
        ),
      ],
    );
  }
}