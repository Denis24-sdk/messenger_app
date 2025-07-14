import 'package:flutter/material.dart';
import 'package:messenger_flutter/main.dart';
import 'package:messenger_flutter/providers/account_provider.dart';
import 'package:messenger_flutter/services/auth_service.dart';
import 'package:photo_view/photo_view.dart';
import 'package:provider/provider.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AccountProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Ваш профиль'),
        titleTextStyle: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
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
      children: [
        const _AvatarSection(),
        const SizedBox(height: 24),
        const _NameSection(),
        const SizedBox(height: 8),
        const _EmailSection(),
        const SizedBox(height: 24),
        const _BioSection(),
        const SizedBox(height: 24),
        Divider(color: AppColors.accentGray.withOpacity(0.3)),
        const SizedBox(height: 16),
        const _SettingsSection(),
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
          PhotoView(
            imageProvider: NetworkImage(imageUrl),
            heroAttributes: PhotoViewHeroAttributes(tag: imageUrl),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 10,
            child: CircleAvatar(
              backgroundColor: Colors.black.withOpacity(0.5),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
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
        alignment: Alignment.center,
        children: [
          GestureDetector(
            onTap: avatarUrl != null && !provider.isUploading
                ? () => _openFullScreenAvatar(context, avatarUrl)
                : null,
            child: Hero(
              tag: avatarUrl ?? 'avatar',
              child: CircleAvatar(
                radius: 60,
                backgroundColor: AppColors.card,
                backgroundImage:
                avatarUrl != null ? NetworkImage(avatarUrl) : null,
                child: avatarUrl == null
                    ? Icon(Icons.person, size: 60, color: AppColors.textSecondary)
                    : null,
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: CircleAvatar(
              radius: 22,
              backgroundColor: AppColors.background,
              child: CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.accent,
                child: IconButton(
                  icon: const Icon(Icons.camera_alt, color: AppColors.background, size: 22),
                  onPressed: provider.isUploading
                      ? null
                      : context.read<AccountProvider>().uploadAvatar,
                ),
              ),
            ),
          ),
          if (provider.isUploading)
            const Positioned.fill(
              child: CircleAvatar(
                  backgroundColor: Colors.black54,
                  child: CircularProgressIndicator(color: AppColors.accent)),
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
        const SizedBox(width: 44),
        Text(
          provider.userData?['username'] ?? 'Имя не указано',
          style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary),
        ),
        IconButton(
          icon: Icon(Icons.edit, size: 20, color: AppColors.textSecondary),
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
            style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary),
            decoration: InputDecoration.collapsed(
              hintText: 'Введите имя',
              hintStyle: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.check, color: AppColors.accent),
          onPressed: _updateUsername,
        ),
        IconButton(
          icon: const Icon(Icons.close, color: Colors.redAccent),
          onPressed: () =>
              context.read<AccountProvider>().setEditingName(false),
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
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 16),
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
        Text('О себе:',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: AppColors.textPrimary)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => context.read<AccountProvider>().setEditingBio(true),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    hasBio ? bio : 'Нет информации',
                    style: TextStyle(
                        color: hasBio
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                        height: 1.5),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.edit, size: 18, color: AppColors.textSecondary),
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
        Text('О себе:',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: AppColors.textPrimary)),
        const SizedBox(height: 8),
        TextField(
          controller: _controller,
          maxLines: 4,
          minLines: 2,
          autofocus: true,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: 'Расскажите о себе...',
            hintStyle: const TextStyle(color: AppColors.textSecondary),
            filled: true,
            fillColor: AppColors.card,
            contentPadding: const EdgeInsets.all(12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.accentGray,
                width: 1.5,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () =>
                  context.read<AccountProvider>().setEditingBio(false),
              child: const Text('Отмена', style: TextStyle(color: AppColors.textSecondary)),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: () =>
                  context.read<AccountProvider>().updateBio(_controller.text),
              style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: AppColors.background,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)
                  )
              ),
              child: const Text('Сохранить'),
            ),
          ],
        ),
      ],
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection();

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.card,
          title: const Text("Выход из аккаунта", style: TextStyle(color: AppColors.textPrimary)),
          content: const Text("Вы уверены, что хотите выйти?", style: TextStyle(color: AppColors.textSecondary)),
          actions: <Widget>[
            TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text("Отмена", style: TextStyle(color: AppColors.textSecondary))),
            TextButton(
              child: const Text("Выйти", style: TextStyle(color: Colors.redAccent)),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                context.read<AuthService>().signOut();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          leading: Icon(Icons.settings, color: AppColors.textSecondary),
          title: Text('Настройки', style: TextStyle(color: AppColors.textPrimary)),
          onTap: () {
            // TODO: Navigate to settings screen
          },
        ),
        ListTile(
          leading: Icon(Icons.logout, color: Colors.redAccent),
          title: const Text('Выйти', style: TextStyle(color: Colors.redAccent)),
          onTap: () => _confirmLogout(context),
        ),
      ],
    );
  }
}