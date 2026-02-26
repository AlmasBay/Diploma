import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:jwt_decode/jwt_decode.dart';
import '../models/user.dart';
import '../models/user_profile.dart';
import 'app_config.dart';
import 'storage_service.dart';

class AuthService extends ChangeNotifier {
  static const String apiBaseUrl = AppConfig.apiBaseUrl;
  static const String baseUrl = '$apiBaseUrl/auth';
  static const String profileUrl = '$apiBaseUrl/users/me';

  final StorageService _storage = StorageService();
  bool _isAuthenticated = false;
  String? _userEmail;
  String? _userRole;
  int? _userId;
  String? _username;
  String? _avatarBase64;
  String _themePreference = 'SYSTEM';

  bool get isAuthenticated => _isAuthenticated;
  String? get userEmail => _userEmail;
  String? get userRole => _userRole;
  bool get isAdmin => _userRole == 'ADMIN';
  int? get userId => _userId;
  String? get username => _username;
  String? get avatarBase64 => _avatarBase64;
  String get themePreference => _themePreference;

  Future<Map<String, String>> _authHeaders() async {
    final token = await _storage.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  void _applyProfile(UserProfile profile, {bool notify = true}) {
    _userId = profile.id;
    _userEmail = profile.email;
    _userRole = profile.role;
    _username = profile.username;
    _avatarBase64 = profile.avatarBase64;
    _themePreference = profile.themePreference;
    if (notify) {
      notifyListeners();
    }
  }

  Future<void> _persistCoreUserInfo() async {
    if (_userEmail != null && _userRole != null) {
      await _storage.saveUserInfo(_userEmail!, _userRole!);
    }
    if (_userId != null) {
      await _storage.saveUserId(_userId.toString());
    }
  }

  Future<bool> checkAuth() async {
    final token = await _storage.getToken();
    if (token == null) return false;

    _isAuthenticated = true;
    _userEmail = await _storage.getUserEmail();
    _userRole = await _storage.getUserRole();
    final idString = await _storage.getUserId();
    if (idString != null) _userId = int.tryParse(idString);

    try {
      await getMyProfile(notify: false);
      await _persistCoreUserInfo();
    } catch (_) {
      // Keep local session even if profile endpoint is temporarily unavailable.
    }

    notifyListeners();
    return true;
  }

  String? _getRoleFromToken(String token) {
    try {
      final payload = Jwt.parseJwt(token);
      if (payload.containsKey('role')) return payload['role']?.toString();
      if (payload.containsKey('authorities')) {
        return payload['authorities']?.toString();
      }
      if (payload.containsKey('roles')) return payload['roles']?.toString();
      return 'USER';
    } catch (_) {
      return 'USER';
    }
  }

  int? _getIdFromToken(String token) {
    try {
      final payload = Jwt.parseJwt(token);
      if (!payload.containsKey('id')) return null;
      final v = payload['id'];
      if (v is int) return v;
      return int.tryParse(v.toString());
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>> register(User user) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(user.toJson()),
      );

      final bodyText = utf8.decode(response.bodyBytes);

      if (response.statusCode == 200) {
        final data = json.decode(bodyText);
        final token = data['token'];

        final role = data['role']?.toString() ?? user.role;
        int? id;
        final idRaw = data['id'];
        if (idRaw is int) {
          id = idRaw;
        } else if (idRaw != null) {
          id = int.tryParse(idRaw.toString());
        }

        await _storage.saveToken(token);
        _isAuthenticated = true;
        _userEmail = user.email;
        _userRole = role;
        _userId = id;
        _username = user.username;
        _themePreference = 'SYSTEM';
        await _persistCoreUserInfo();

        try {
          await getMyProfile(notify: false);
          await _persistCoreUserInfo();
        } catch (_) {}

        notifyListeners();
        return {'success': true, 'message': 'Регистрация успешна'};
      }

      if (response.statusCode == 409) {
        return {
          'success': false,
          'message': bodyText.isNotEmpty
              ? bodyText
              : 'Email или имя пользователя уже заняты'
        };
      }

      return {
        'success': false,
        'message': bodyText.isNotEmpty
            ? bodyText
            : 'Ошибка регистрации: ${response.statusCode}'
      };
    } catch (e) {
      return {'success': false, 'message': 'Ошибка: $e'};
    }
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'password': password}),
      ).timeout(const Duration(seconds: 15));

      final bodyText = utf8.decode(response.bodyBytes);

      if (response.statusCode == 200) {
        final data = json.decode(bodyText);
        final token = data['token'];

        final role =
            data['role']?.toString() ?? (_getRoleFromToken(token) ?? 'USER');

        int? id;
        final idRaw = data['id'];
        if (idRaw is int) {
          id = idRaw;
        } else if (idRaw != null) {
          id = int.tryParse(idRaw.toString());
        } else {
          id = _getIdFromToken(token);
        }

        await _storage.saveToken(token);
        _isAuthenticated = true;
        _userEmail = email;
        _userRole = role;
        _userId = id;
        await _persistCoreUserInfo();

        try {
          await getMyProfile(notify: false);
          await _persistCoreUserInfo();
        } catch (_) {}

        notifyListeners();
        return {'success': true, 'message': 'Вход выполнен'};
      }

      return {
        'success': false,
        'message': bodyText.isNotEmpty ? bodyText : 'Неверный email или пароль'
      };
    } catch (e) {
      return {'success': false, 'message': 'Ошибка: $e'};
    }
  }

  Future<Map<String, dynamic>> forgotPassword(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email.trim()}),
      );

      final bodyText = utf8.decode(response.bodyBytes);
      if (response.statusCode == 200) {
        String message =
            'Р•СЃР»Рё Р°РєРєР°СѓРЅС‚ СЃ С‚Р°РєРёРј email СЃСѓС‰РµСЃС‚РІСѓРµС‚, РїРёСЃСЊРјРѕ РѕС‚РїСЂР°РІР»РµРЅРѕ';
        if (bodyText.isNotEmpty) {
          final parsed = json.decode(bodyText);
          if (parsed is Map<String, dynamic> && parsed['message'] != null) {
            message = parsed['message'].toString();
          }
        }
        return {'success': true, 'message': message};
      }

      return {
        'success': false,
        'message': bodyText.isNotEmpty
            ? bodyText
            : 'РћС€РёР±РєР° РІРѕСЃСЃС‚Р°РЅРѕРІР»РµРЅРёСЏ РїР°СЂРѕР»СЏ: ${response.statusCode}'
      };
    } catch (e) {
      return {'success': false, 'message': 'РћС€РёР±РєР°: $e'};
    }
  }

  Future<Map<String, dynamic>> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'token': token.trim(),
          'newPassword': newPassword,
        }),
      );

      final bodyText = utf8.decode(response.bodyBytes);
      if (response.statusCode == 200) {
        String message = 'РџР°СЂРѕР»СЊ СѓСЃРїРµС€РЅРѕ РѕР±РЅРѕРІР»РµРЅ';
        if (bodyText.isNotEmpty) {
          final parsed = json.decode(bodyText);
          if (parsed is Map<String, dynamic> && parsed['message'] != null) {
            message = parsed['message'].toString();
          }
        }
        return {'success': true, 'message': message};
      }

      return {
        'success': false,
        'message': bodyText.isNotEmpty
            ? bodyText
            : 'РћС€РёР±РєР° СЃР±СЂРѕСЃР° РїР°СЂРѕР»СЏ: ${response.statusCode}'
      };
    } catch (e) {
      return {'success': false, 'message': 'РћС€РёР±РєР°: $e'};
    }
  }

  Future<UserProfile?> getMyProfile({bool notify = true}) async {
    try {
      final headers = await _authHeaders();
      if (!headers.containsKey('Authorization')) return null;

      final response = await http.get(
        Uri.parse(profileUrl),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final profile =
            UserProfile.fromJson(json.decode(utf8.decode(response.bodyBytes)));
        _applyProfile(profile, notify: notify);
        return profile;
      }

      throw Exception('Failed to load profile: ${response.statusCode}');
    } catch (e) {
      throw Exception('Error loading profile: $e');
    }
  }

  Future<Map<String, dynamic>> updateMyProfile({
    required String username,
    String? avatarBase64,
    required String themePreference,
  }) async {
    try {
      final headers = await _authHeaders();
      if (!headers.containsKey('Authorization')) {
        return {'success': false, 'message': 'Пользователь не авторизован'};
      }

      final response = await http.put(
        Uri.parse(profileUrl),
        headers: headers,
        body: json.encode({
          'username': username,
          'avatarBase64': avatarBase64,
          'themePreference': themePreference,
        }),
      );

      if (response.statusCode == 200) {
        final profile =
            UserProfile.fromJson(json.decode(utf8.decode(response.bodyBytes)));
        _applyProfile(profile, notify: false);
        await _persistCoreUserInfo();
        notifyListeners();
        return {
          'success': true,
          'message': 'Профиль обновлен',
          'profile': profile
        };
      }

      final bodyText = utf8.decode(response.bodyBytes);
      return {
        'success': false,
        'message': bodyText.isNotEmpty
            ? bodyText
            : 'Ошибка обновления профиля: ${response.statusCode}'
      };
    } catch (e) {
      return {'success': false, 'message': 'Ошибка: $e'};
    }
  }

  Future<int?> getStoredUserId() async {
    final idString = await _storage.getUserId();
    if (idString == null) return _userId;
    return int.tryParse(idString);
  }

  Future<void> logout() async {
    await _storage.clearAll();
    _isAuthenticated = false;
    _userEmail = null;
    _userRole = null;
    _userId = null;
    _username = null;
    _avatarBase64 = null;
    _themePreference = 'SYSTEM';
    notifyListeners();
  }
}
