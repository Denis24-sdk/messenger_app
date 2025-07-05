import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:messenger_flutter/services/storage/storage_service.dart';
import 'package:photo_view/photo_view.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final StorageService _storageService = StorageService();

  User? _currentUser;
  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  bool _isEditingName = false;
  bool _isEditingBio = false; // Добавлено состояние редактирования описания
  bool _isUploading = false;

  late TextEditingController _nameController;
  late TextEditingController _bioController; // Контроллер для описания

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _bioController = TextEditingController(); // Инициализация контроллера описания
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose(); // Освобождение ресурсов
    super.dispose();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    _currentUser = _auth.currentUser;
    if (_currentUser != null) {
      try {
        DocumentSnapshot userDoc =
        await _firestore.collection('Users').doc(_currentUser!.uid).get();
        if (mounted && userDoc.exists) {
          setState(() {
            _userData = userDoc.data() as Map<String, dynamic>;
            _nameController.text = _userData?['username'] ?? '';
            // Загрузка описания из базы данных
            _bioController.text = _userData?['bio'] ?? '';
          });
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ошибка загрузки данных: $e')),
          );
        }
      }
    }
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

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

  // Метод для обновления описания
  Future<void> _updateBio() async {
    if (_currentUser != null) {
      try {
        await _firestore
            .collection('Users')
            .doc(_currentUser!.uid)
            .update({'bio': _bioController.text.trim()});

        setState(() {
          _userData?['bio'] = _bioController.text.trim();
          _isEditingBio = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Описание успешно обновлено')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка обновления описания: $e')),
        );
      }
    }
  }

  Future<void> _uploadAvatar() async {
    File? image = await _storageService.pickImage();
    if (image == null) return;

    if (mounted) setState(() => _isUploading = true);

    if (_userData?['avatarFileId'] != null) {
      await _storageService.deleteFile(_userData!['avatarFileId']);
    }

    Map<String, String>? uploadResult = await _storageService.uploadFile(image);

    if (uploadResult != null) {
      String downloadUrl = uploadResult['url']!;
      String fileId = uploadResult['fileId']!;

      await _firestore.collection('Users').doc(_currentUser!.uid).update({
        'avatarUrl': downloadUrl,
        'avatarFileId': fileId,
      });

      if (mounted) {
        setState(() {
          _userData?['avatarUrl'] = downloadUrl;
          _userData?['avatarFileId'] = fileId;
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Аватар успешно обновлен!')));
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ошибка загрузки аватара.')));
      }
    }
    if (mounted) {
      setState(() => _isUploading = false);
    }
  }


  void _openFullScreenAvatar(BuildContext context, String imageUrl) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              Positioned.fill(
                child: PhotoView(
                  imageProvider: NetworkImage(imageUrl),
                  minScale: PhotoViewComputedScale.contained * 0.8,
                  maxScale: PhotoViewComputedScale.covered * 3,
                  backgroundDecoration: const BoxDecoration(color: Colors.black),
                  loadingBuilder: (context, event) => const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                  errorBuilder: (context, error, stackTrace) => const Center(
                    child: Icon(Icons.broken_image, color: Colors.white, size: 60),
                  ),
                ),
              ),
              Positioned(
                top: MediaQuery.of(context).padding.top + 16,
                left: 16,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
    final avatarUrl = _userData?['avatarUrl'];

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        Center(
          child: Stack(
            children: [
              GestureDetector(
                onTap: avatarUrl != null && !_isUploading
                    ? () => _openFullScreenAvatar(context, avatarUrl)
                    : null,
                child: CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.grey.shade300,
                  backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                  child: avatarUrl == null
                      ? Icon(Icons.person, size: 60, color: Colors.grey.shade800)
                      : null,
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: CircleAvatar(
                  backgroundColor: Theme.of(context).primaryColor,
                  child: IconButton(
                    icon: const Icon(Icons.camera_alt, color: Colors.white),
                    onPressed: _isUploading ? null : _uploadAvatar,
                  ),
                ),
              ),
              if (_isUploading)
                const Positioned.fill(
                  child: Center(child: CircularProgressIndicator()),
                )
            ],
          ),
        ),
        const SizedBox(height: 24),
        _isEditingName ? _buildNameEditor() : _buildNameDisplay(),
        const SizedBox(height: 8),
        Center(
          child: Text(
            _userData?['email'] ?? 'Email не найден',
            style: const TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ),
        const SizedBox(height: 24),

        // Секция с описанием
        _isEditingBio ? _buildBioEditor() : _buildBioDisplay(),
        const SizedBox(height: 24),

        const Divider(),
        const SizedBox(height: 16),
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

  // Виджет для отображения описания
  Widget _buildBioDisplay() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 16.0),
          child: Text(
            'Описание:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () {
            setState(() {
              _isEditingBio = true;
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _userData?['bio']?.isNotEmpty == true
                        ? _userData!['bio']
                        : 'Добавьте описание...',
                    style: TextStyle(
                      color: _userData?['bio']?.isNotEmpty == true
                          ? Colors.black
                          : Colors.grey,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.edit, size: 18, color: Colors.grey),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Виджет для редактирования описания
  Widget _buildBioEditor() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 16.0),
          child: Text(
            'Описание:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: _bioController,
            maxLines: 3,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Расскажите о себе...',
              border: InputBorder.none,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () {
                setState(() {
                  _isEditingBio = false;
                  _bioController.text = _userData?['bio'] ?? '';
                });
              },
              child: const Text('Отмена'),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _updateBio,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
              ),
              child: const Text('Сохранить'),
            ),
          ],
        ),
      ],
    );
  }
}