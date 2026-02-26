import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/news_portal.dart';
import '../models/category.dart';
import 'app_config.dart';
import 'storage_service.dart';

class ApiService {
  static const String baseUrl = AppConfig.apiBaseUrl;

  final StorageService _storage = StorageService();

  Future<Map<String, String>> _getHeaders() async {
    final token = await _storage.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // =================== NEWS (NewsPortal) ===================

  Future<List<NewsPortal>> getAllNews() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/news-portal/all'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        return data.map((json) => NewsPortal.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load news: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error loading news: $e');
    }
  }

  // ✅ Серверный поиск
  Future<List<NewsPortal>> searchNews(String query) async {
    try {
      final headers = await _getHeaders();

      final url =
          '$baseUrl/news-portal/search?q=${Uri.encodeComponent(query)}';
      // print('SEARCH URL: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        return data.map((json) => NewsPortal.fromJson(json)).toList();
      } else {
        throw Exception('Failed to search news: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error searching news: $e');
    }
  }

  Future<NewsPortal> addNews(NewsPortal news) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/news-portal/add'),
        headers: headers,
        body: json.encode(news.toJson()),
      );

      if (response.statusCode == 200) {
        return NewsPortal.fromJson(json.decode(utf8.decode(response.bodyBytes)));
      } else {
        throw Exception('Failed to add news: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error adding news: $e');
    }
  }

  // ⚠️ Эти 2 метода будут работать ТОЛЬКО если ты добавил на бэке PUT/DELETE /api/news-portal/{id}
  Future<NewsPortal> updateNews(int id, NewsPortal news) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl/news-portal/$id'),
        headers: headers,
        body: json.encode(news.toJson()),
      );

      if (response.statusCode == 200) {
        return NewsPortal.fromJson(json.decode(utf8.decode(response.bodyBytes)));
      } else {
        throw Exception('Failed to update news: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error updating news: $e');
    }
  }

  Future<void> deleteNews(int id) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/news-portal/$id'),
        headers: headers,
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to delete news: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error deleting news: $e');
    }
  }

  // =================== CATEGORIES ===================

  Future<List<Category>> getAllCategories() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/categories'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        return data.map((json) => Category.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load categories: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error loading categories: $e');
    }
  }

  Future<Category> addCategory(Category category) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/categories'),
        headers: headers,
        body: json.encode(category.toJson()),
      );

      if (response.statusCode == 200) {
        return Category.fromJson(json.decode(utf8.decode(response.bodyBytes)));
      } else {
        throw Exception('Failed to add category: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error adding category: $e');
    }
  }

  Future<void> deleteCategory(int id) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/categories/$id'),
        headers: headers,
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to delete category: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error deleting category: $e');
    }
  }

  Future<Category> updateCategory(int id, Category category) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl/categories/$id'),
        headers: headers,
        body: json.encode(category.toJson()),
      );

      if (response.statusCode == 200) {
        return Category.fromJson(json.decode(utf8.decode(response.bodyBytes)));
      } else {
        throw Exception('Failed to update category: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error updating category: $e');
    }
  }

  // =================== FAVORITES ===================

  Future<bool> toggleFavorite(int userId, int newsPortalId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/favorites/$userId/$newsPortalId'),
        headers: headers,
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        final body = utf8.decode(response.bodyBytes).toLowerCase();

        if (body.contains('added') || body.contains('добавлено')) {
          return true;
        } else if (body.contains('removed') || body.contains('удалено')) {
          return false;
        }
        return true;
      } else {
        throw Exception('Ошибка при добавлении/удалении из избранного');
      }
    } catch (e) {
      throw Exception('Ошибка toggleFavorite: $e');
    }
  }

  Future<List<NewsPortal>> getFavorites(int userId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/favorites/$userId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final body = utf8.decode(response.bodyBytes);
        final List<dynamic> data = json.decode(body);

        final validItems = data
            .where((item) =>
        item != null &&
            item is Map<String, dynamic> &&
            item['newsPortal'] != null)
            .toList();

        return validItems
            .map((json) => NewsPortal.fromJson(json['newsPortal']))
            .toList();
      } else {
        throw Exception('Ошибка при загрузке избранного: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Ошибка загрузки избранного: $e');
    }
  }
}
