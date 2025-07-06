import 'package:flutter/material.dart';
import 'package:messenger_flutter/providers/account_provider.dart';
import 'package:photo_view/photo_view.dart';
import 'package:provider/provider.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AccountProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Аккаунт'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.userData == null
          ? const Center(child: Text('Не удалось загрузить данные.'))
          : const _UserProfile(),
    );
  }
}

class _UserProfile extends StatelessWidget {
  const _UserProfile();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: const [
        _AvatarSection(),
        SizedBox(height: 24),
        _NameSection(),
        SizedBox(height: 8),
        _EmailSection(),
        SizedBox(height: 24),
        _BioSection(),
        SizedBox(height: 24),
        Divider(),
        SizedBox(height: 16),
        _SettingsPlaceholder(),
      ],
    );
  }
}

class _AvatarSection extends StatelessWidget {
  const _AvatarSection();

  void _openFullScreenAvatar(BuildContext context, String imageUrl) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => Scaffold(
        backgroundColor: Colors.black,
        body: Stack(children: [
          PhotoView(imageProvider: NetworkImage(imageUrl)),
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ]),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AccountProvider>();
    final avatarUrl = provider.userData?['avatarUrl'];

    return Center(
      child: Stack(
        children: [
          GestureDetector(
            onTap: avatarUrl != null && !provider.isUploading
                ? () => _openFullScreenAvatar(context, avatarUrl)
                : null,
            child: CircleAvatar(
              radius: 60,
              backgroundColor: Colors.grey.shade300,
              backgroundImage:
              avatarUrl != null ? NetworkImage(avatarUrl) : null,
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
                onPressed:
                provider.isUploading ? null : context.read<AccountProvider>().uploadAvatar,
              ),
            ),
          ),
          if (provider.isUploading)
            const Positioned.fill(
              child: Center(child: CircularProgressIndicator()),
            )
        ],
      ),
    );
  }
}

class _NameSection extends StatelessWidget {
  const _NameSection();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AccountProvider>();
    return provider.isEditingName
        ? const _NameEditor()
        : const _NameDisplay();
  }
}

class _NameDisplay extends StatelessWidget {
  const _NameDisplay();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AccountProvider>();
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          provider.userData?['username'] ?? 'Имя не указано',
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        IconButton(
          icon: const Icon(Icons.edit, size: 20, color: Colors.grey),
          onPressed: () => context.read<AccountProvider>().setEditingName(true),
        ),
      ],
    );
  }
}

class _NameEditor extends StatefulWidget {
  const _NameEditor();
  @override
  State<_NameEditor> createState() => _NameEditorState();
}

class _NameEditorState extends State<_NameEditor> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
        text: context.read<AccountProvider>().userData?['username'] ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _updateUsername() async {
    try {
      await context.read<AccountProvider>().updateUsername(_controller.text);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString().replaceAll("Exception: ", ""))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _controller,
            autofocus: true,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            decoration: const InputDecoration.collapsed(hintText: 'Введите имя'),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.check, color: Colors.green),
          onPressed: _updateUsername,
        ),
        IconButton(
          icon: const Icon(Icons.close, color: Colors.red),
          onPressed: () => context.read<AccountProvider>().setEditingName(false),
        ),
      ],
    );
  }
}

class _EmailSection extends StatelessWidget {
  const _EmailSection();
  @override
  Widget build(BuildContext context) {
    final email = context.watch<AccountProvider>().userData?['email'];
    return Center(
      child: Text(
        email ?? 'Email не найден',
        style: const TextStyle(color: Colors.grey, fontSize: 16),
      ),
    );
  }
}

class _BioSection extends StatelessWidget {
  const _BioSection();
  @override
  Widget build(BuildContext context) {
    return context.watch<AccountProvider>().isEditingBio
        ? const _BioEditor()
        : const _BioDisplay();
  }
}

class _BioDisplay extends StatelessWidget {
  const _BioDisplay();
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AccountProvider>();
    final bio = provider.userData?['bio'];
    final hasBio = bio != null && bio.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Описание:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => context.read<AccountProvider>().setEditingBio(true),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    hasBio ? bio : 'Добавьте описание...',
                    style: TextStyle(color: hasBio ? Colors.black : Colors.grey),
                  ),
                ),
                const Icon(Icons.edit, size: 18, color: Colors.grey),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _BioEditor extends StatefulWidget {
  const _BioEditor();
  @override
  State<_BioEditor> createState() => _BioEditorState();
}

class _BioEditorState extends State<_BioEditor> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
        text: context.read<AccountProvider>().userData?['bio'] ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Описание:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        TextField(
          controller: _controller,
          maxLines: 3,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Расскажите о себе...',
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.all(12),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () => context.read<AccountProvider>().setEditingBio(false),
              child: const Text('Отмена'),
            ),
            ElevatedButton(
              onPressed: () => context.read<AccountProvider>().updateBio(_controller.text),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text('Сохранить'),
            ),
          ],
        ),
      ],
    );
  }
}

class _SettingsPlaceholder extends StatelessWidget {
  const _SettingsPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.settings),
          title: const Text('Настройки'),
          onTap: () {},
        ),
        ListTile(
          leading: const Icon(Icons.info_outline),
          title: const Text('Информация'),
          onTap: () {},
        ),
      ],
    );
  }
}