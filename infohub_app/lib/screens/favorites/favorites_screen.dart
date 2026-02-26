import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/news_portal.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/news_card.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final ApiService _api = ApiService();
  List<NewsPortal> _favorites = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    setState(() => _isLoading = true);

    // 1) Берём сервис ДО await
    final auth = context.read<AuthService>();

    // 2) Убедимся, что авторизация прогружена (подтянет email/role/id из storage)
    await auth.checkAuth();

    // 3) Достаём id: сперва из стораджа, если нет — из поля сервиса
    final userId = await auth.getStoredUserId() ?? auth.userId;

    if (!mounted) return;

    if (userId == null) {
      // Если id всё ещё нет — отправляем на логин
      await auth.logout();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Пользователь не найден. Войдите заново.')),
      );
      Navigator.of(context).popUntil((route) => route.isFirst);
      return;
    }

    try {
      final favorites = await _api.getFavorites(userId);
      if (!mounted) return;
      setState(() {
        _favorites = favorites;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка загрузки избранного: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Избранное'),
        actions: [
          IconButton(
            onPressed: _loadFavorites,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadFavorites,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _favorites.isEmpty
            ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.favorite_border, size: 80, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'Нет избранных новостей',
                style: TextStyle(fontSize: 18, color: Colors.grey[600]),
              ),
            ],
          ),
        )
            : ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _favorites.length,
          itemBuilder: (context, index) {
            return NewsCard(
              news: _favorites[index],
              onRefresh: _loadFavorites,
            );
          },
        ),
      ),
    );
  }
}
