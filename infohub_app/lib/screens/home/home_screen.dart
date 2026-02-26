import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/category.dart';
import '../../models/news_portal.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/category_filter.dart';
import '../../widgets/news_card.dart';
import '../admin/admin_panel_screen.dart';
import '../favorites/favorites_screen.dart';
import '../profile/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _api = ApiService();
  List<NewsPortal> _allNews = [];
  List<NewsPortal> _filteredNews = [];
  List<Category> _categories = [];
  Category? _selectedCategory;

  bool _isLoading = true;
  String _searchQuery = '';
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final news = await _api.getAllNews();
      final categories = await _api.getAllCategories();
      setState(() {
        _allNews = news;
        _categories = categories;
        _applyCategoryFilterOnly();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка загрузки: $e')),
        );
      }
    }
  }

  void _applyCategoryFilterOnly() {
    setState(() {
      _filteredNews = _allNews.where((news) {
        final matchesCategory = _selectedCategory == null ||
            news.category?.id == _selectedCategory?.id;
        return matchesCategory;
      }).toList();
    });
  }

  Future<void> _runServerSearch() async {
    setState(() => _isLoading = true);
    try {
      final q = _searchQuery.trim();
      final news =
          q.isEmpty ? await _api.getAllNews() : await _api.searchNews(q);
      setState(() {
        _allNews = news;
        _applyCategoryFilterOnly();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка поиска: $e')),
        );
      }
    }
  }

  void _onCategorySelected(Category? category) {
    setState(() => _selectedCategory = category);
    _applyCategoryFilterOnly();
  }

  void _onSearchChanged(String query) {
    setState(() => _searchQuery = query);
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), _runServerSearch);
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.watch<AuthService>().isAdmin;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Новостной портал'),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite),
            tooltip: 'Избранное',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FavoritesScreen()),
              );
            },
          ),
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.admin_panel_settings),
              tooltip: 'Админ панель',
              onPressed: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AdminPanelScreen()),
                );
                _loadData();
              },
            ),
          IconButton(
            icon: const Icon(Icons.account_circle),
            tooltip: 'Профиль',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Поиск новостей...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            if (_categories.isNotEmpty)
              CategoryFilter(
                categories: _categories,
                selectedCategory: _selectedCategory,
                onCategorySelected: _onCategorySelected,
              ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredNews.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.newspaper,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Нет новостей',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredNews.length,
                          itemBuilder: (context, index) {
                            return NewsCard(
                              news: _filteredNews[index],
                              onRefresh: _loadData,
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
