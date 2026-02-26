import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../services/auth_service.dart';
import '../../services/theme_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const int _maxAvatarBytes = 1200000;

  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _imagePicker = ImagePicker();

  bool _isLoading = true;
  bool _isSaving = false;
  String? _avatarBase64;
  ThemeMode _selectedTheme = ThemeMode.system;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    final auth = context.read<AuthService>();
    final theme = context.read<ThemeService>();

    try {
      final profile = await auth.getMyProfile(notify: false);
      _usernameController.text = profile?.username ?? auth.username ?? '';
      _avatarBase64 = profile?.avatarBase64 ?? auth.avatarBase64;
      _selectedTheme = _themeModeFromPreference(
        profile?.themePreference ?? auth.themePreference,
        fallback: theme.themeMode,
      );
    } catch (_) {
      _usernameController.text = auth.username ?? '';
      _avatarBase64 = auth.avatarBase64;
      _selectedTheme = theme.themeMode;
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  ThemeMode _themeModeFromPreference(String? preference,
      {ThemeMode fallback = ThemeMode.system}) {
    final normalized = (preference ?? '').toUpperCase();
    switch (normalized) {
      case 'LIGHT':
        return ThemeMode.light;
      case 'DARK':
        return ThemeMode.dark;
      case 'SYSTEM':
        return ThemeMode.system;
      default:
        return fallback;
    }
  }

  Future<void> _pickAvatarFromGallery() async {
    try {
      final picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 75,
        maxWidth: 768,
      );

      if (picked == null) return;

      final bytes = await picked.readAsBytes();
      if (bytes.length > _maxAvatarBytes) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(
                    'Файл слишком большой. Выберите изображение поменьше.')),
          );
        }
        return;
      }

      if (mounted) {
        setState(() => _avatarBase64 = base64Encode(bytes));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Не удалось выбрать изображение: $e')),
        );
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final auth = context.read<AuthService>();
    final themeService = context.read<ThemeService>();

    final result = await auth.updateMyProfile(
      username: _usernameController.text.trim(),
      avatarBase64: _avatarBase64,
      themePreference: ThemeService.toPreference(_selectedTheme),
    );

    if (!mounted) return;

    if (result['success'] == true) {
      await themeService.setThemeMode(_selectedTheme);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Профиль обновлен')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(result['message'] ?? 'Не удалось обновить профиль')),
      );
    }

    setState(() => _isSaving = false);
  }

  Future<void> _logout() async {
    await context.read<AuthService>().logout();
    if (!mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Uint8List? _avatarBytes() {
    if (_avatarBase64 == null || _avatarBase64!.isEmpty) return null;
    try {
      return base64Decode(_avatarBase64!);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final avatarBytes = _avatarBytes();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Профиль'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 48,
                            backgroundImage: avatarBytes != null
                                ? MemoryImage(avatarBytes)
                                : null,
                            child: avatarBytes == null
                                ? const Icon(Icons.person, size: 44)
                                : null,
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            children: [
                              OutlinedButton.icon(
                                onPressed: _pickAvatarFromGallery,
                                icon: const Icon(Icons.photo_library),
                                label: const Text('Выбрать'),
                              ),
                              if (avatarBytes != null)
                                OutlinedButton.icon(
                                  onPressed: () =>
                                      setState(() => _avatarBase64 = null),
                                  icon: const Icon(Icons.delete_outline),
                                  label: const Text('Удалить'),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      initialValue: auth.userEmail ?? '',
                      enabled: false,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _usernameController,
                      decoration: const InputDecoration(
                        labelText: 'Никнейм',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().length < 3) {
                          return 'Никнейм должен быть минимум 3 символа';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      initialValue: auth.userRole ?? 'USER',
                      enabled: false,
                      decoration: const InputDecoration(
                        labelText: 'Роль',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<ThemeMode>(
                      initialValue: _selectedTheme,
                      decoration: const InputDecoration(
                        labelText: 'Тема',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: ThemeMode.system,
                          child: Text('Системная'),
                        ),
                        DropdownMenuItem(
                          value: ThemeMode.light,
                          child: Text('Светлая'),
                        ),
                        DropdownMenuItem(
                          value: ThemeMode.dark,
                          child: Text('Тёмная'),
                        ),
                      ],
                      onChanged: (mode) {
                        if (mode != null) {
                          setState(() => _selectedTheme = mode);
                        }
                      },
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: _isSaving ? null : _saveProfile,
                      icon: const Icon(Icons.save),
                      label: _isSaving
                          ? const Text('Сохранение...')
                          : const Text('Сохранить изменения'),
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: _logout,
                      icon: const Icon(Icons.logout),
                      label: const Text('Выйти из аккаунта'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
