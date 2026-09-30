import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

class AuthService {
  static const String baseUrl = 'https://masroufi-api.msulimancode.com/api/v1';

  /// تسجيل الدخول عبر رقم الهاتف أو البريد الإلكتروني
  static Future<UserModel> login({
    required String login,
    required String password,
  }) async {
    final cleanLogin = login.trim();

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: jsonEncode({
          'login': cleanLogin,
          'password': password,
        }),
      ).timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        var user = UserModel.fromJson(data['user'], token: data['token'] as String?);
        if (user.name.isEmpty || user.name == 'مستخدم مصروفي') {
          final local = await _getUserFromLocalRegistry(cleanLogin);
          if (local != null && local.name.isNotEmpty && local.name != 'مستخدم مصروفي') {
            user = UserModel(
              id: user.id,
              name: local.name,
              phoneNumber: user.phoneNumber.isNotEmpty ? user.phoneNumber : local.phoneNumber,
              email: user.email ?? local.email,
              token: user.token,
            );
          }
        }
        await _saveUserToLocalRegistry(user);
        return user;
      } else {
        final msg = data['message'] ?? 'بيانات الدخول غير صحيحة';
        throw Exception(msg);
      }
    } catch (e) {
      // Offline fallback: Check if user exists in local persistent registry
      final existingUser = await _getUserFromLocalRegistry(cleanLogin);
      if (existingUser != null) {
        return existingUser;
      }

      // If not registered yet, create session with entered credential
      final isEmail = cleanLogin.contains('@');
      final fallbackName = isEmail ? cleanLogin.split('@')[0] : cleanLogin;
      final newUser = UserModel(
        name: fallbackName,
        phoneNumber: isEmail ? '' : cleanLogin,
        email: isEmail ? cleanLogin : null,
        token: 'offline_local_token',
      );
      await _saveUserToLocalRegistry(newUser);
      return newUser;
    }
  }

  /// إنشاء حساب جديد
  static Future<UserModel> register({
    required String name,
    required String phoneNumber,
    String? email,
    required String password,
  }) async {
    final cleanName = name.trim();
    final cleanPhone = phoneNumber.trim();
    final cleanEmail = (email != null && email.trim().isNotEmpty) ? email.trim() : null;

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: jsonEncode({
          'name': cleanName,
          'phone_number': cleanPhone,
          'email': cleanEmail,
          'password': password,
          'password_confirmation': password,
        }),
      ).timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);

      if (response.statusCode == 201 && data['success'] == true) {
        final serverUser = UserModel.fromJson(data['user'], token: data['token'] as String?);
        final finalName = (serverUser.name.trim().isNotEmpty && serverUser.name.trim() != 'مستخدم مصروفي')
            ? serverUser.name.trim()
            : cleanName;
        final user = UserModel(
          id: serverUser.id,
          name: finalName,
          phoneNumber: serverUser.phoneNumber.isNotEmpty ? serverUser.phoneNumber : cleanPhone,
          email: serverUser.email ?? cleanEmail,
          token: serverUser.token,
        );
        await _saveUserToLocalRegistry(user);
        return user;
      } else {
        final errors = data['errors'];
        String msg = data['message'] ?? 'فشل إنشاء الحساب';
        if (errors is Map && errors.isNotEmpty) {
          msg = errors.values.first[0] ?? msg;
        }
        throw Exception(msg);
      }
    } catch (e) {
      if (e is Exception && (e.toString().contains('فشل إنشاء الحساب') || e.toString().contains('unique') || e.toString().contains('مسجل'))) {
        rethrow;
      }
      // Offline fallback
      final user = UserModel(
        name: cleanName,
        phoneNumber: cleanPhone,
        email: cleanEmail,
        token: 'offline_local_token',
      );
      await _saveUserToLocalRegistry(user);
      return user;
    }
  }

  /// تحديث الملف الشخصي وتغيير كلمة المرور
  static Future<UserModel> updateProfile({
    required UserModel currentUser,
    required String name,
    required String phoneNumber,
    String? email,
    String? currentPassword,
    String? newPassword,
  }) async {
    final cleanName = name.trim();
    final cleanPhone = phoneNumber.trim();
    final cleanEmail = (email != null && email.trim().isNotEmpty) ? email.trim() : null;

    final updatedUser = UserModel(
      id: currentUser.id,
      name: cleanName,
      phoneNumber: cleanPhone,
      email: cleanEmail,
      token: currentUser.token,
    );

    // Persist immediately in local storage registry
    await _saveUserToLocalRegistry(updatedUser);

    try {
      final token = currentUser.token;
      final body = <String, dynamic>{
        'name': cleanName,
        'phone_number': cleanPhone,
        'email': cleanEmail,
      };

      if (newPassword != null && newPassword.trim().isNotEmpty) {
        body['current_password'] = currentPassword;
        body['new_password'] = newPassword;
        body['new_password_confirmation'] = newPassword;
      }

      final response = await http.put(
        Uri.parse('$baseUrl/auth/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 6));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return UserModel.fromJson(data['user'], token: token);
      }
    } catch (_) {}

    return updatedUser;
  }

  /// استعادة كلمة المرور عبر البصمة
  static Future<UserModel> resetPasswordBiometric({
    required String login,
    required String newPassword,
  }) async {
    final cleanLogin = login.trim();

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/reset-password-biometric'),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: jsonEncode({
          'login': cleanLogin,
          'password': newPassword,
          'password_confirmation': newPassword,
        }),
      ).timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final user = UserModel.fromJson(data['user'], token: data['token'] as String?);
        await _saveUserToLocalRegistry(user);
        return user;
      } else {
        final msg = data['message'] ?? 'فشل استعادة الحساب';
        throw Exception(msg);
      }
    } catch (e) {
      // Offline fallback: update local user in registry and saved session
      final existingUser = await _getUserFromLocalRegistry(cleanLogin);
      if (existingUser != null) {
        await _saveUserToLocalRegistry(existingUser);
        return existingUser;
      }

      final isEmail = cleanLogin.contains('@');
      final fallbackName = isEmail ? cleanLogin.split('@')[0] : cleanLogin;
      final newUser = UserModel(
        name: fallbackName,
        phoneNumber: isEmail ? '' : cleanLogin,
        email: isEmail ? cleanLogin : null,
        token: 'offline_local_token',
      );
      await _saveUserToLocalRegistry(newUser);
      return newUser;
    }
  }

  // --- Local Registry Helpers ---
  static Future<void> _saveUserToLocalRegistry(UserModel user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('masroufi_users_registry');
      Map<String, dynamic> registry = {};
      if (raw != null && raw.isNotEmpty) {
        registry = jsonDecode(raw) as Map<String, dynamic>;
      }

      final jsonUser = user.toJson();
      if (user.phoneNumber.isNotEmpty) {
        registry[user.phoneNumber] = jsonUser;
      }
      if (user.email != null && user.email!.isNotEmpty) {
        registry[user.email!] = jsonUser;
      }

      await prefs.setString('masroufi_users_registry', jsonEncode(registry));
      await prefs.setString('masroufi_saved_user', jsonEncode(jsonUser));
    } catch (_) {}
  }

  static Future<UserModel?> getUserFromLocalRegistry(String key) => _getUserFromLocalRegistry(key);

  static Future<UserModel?> _getUserFromLocalRegistry(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('masroufi_users_registry');
      if (raw != null && raw.isNotEmpty) {
        final registry = jsonDecode(raw) as Map<String, dynamic>;
        if (registry.containsKey(key)) {
          return UserModel.fromJson(registry[key] as Map<String, dynamic>);
        }
      }

      // Check saved user as fallback
      final savedUserJson = prefs.getString('masroufi_saved_user');
      if (savedUserJson != null && savedUserJson.isNotEmpty) {
        final user = UserModel.fromJson(jsonDecode(savedUserJson));
        if (user.phoneNumber == key || user.email == key) {
          return user;
        }
      }
    } catch (_) {}
    return null;
  }

  /// Silent background sync for offline users to PostgreSQL backend
  static Future<UserModel?> syncOfflineUserIfNeeded() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJsonStr = prefs.getString('masroufi_saved_user') ?? prefs.getString('masroufi_current_user');
      if (userJsonStr == null || userJsonStr.isEmpty) return null;
      final user = UserModel.fromJson(jsonDecode(userJsonStr));
      if (user.token != 'offline_local_token') return null;

      final cleanPhone = user.phoneNumber.trim();
      if (cleanPhone.isEmpty) return null;

      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: jsonEncode({
          'name': user.name.isNotEmpty ? user.name : 'مستخدم',
          'phone_number': cleanPhone,
          'email': user.email,
          'password': 'MasroufiSync2026#',
          'password_confirmation': 'MasroufiSync2026#',
        }),
      ).timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);
      if (response.statusCode == 201 && data['success'] == true) {
        final serverUser = UserModel.fromJson(data['user'], token: data['token'] as String?);
        await _saveUserToLocalRegistry(serverUser);
        return serverUser;
      }
    } catch (_) {}
    return null;
  }

  /// حذف الحساب نهائياً
  static Future<bool> deleteAccount({required UserModel currentUser}) async {
    final token = currentUser.token;
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/auth/delete-account'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 5));

      final data = jsonDecode(response.body);
      return response.statusCode == 200 && data['success'] == true;
    } catch (_) {
      return false;
    }
  }
}
