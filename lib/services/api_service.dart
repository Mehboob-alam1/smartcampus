import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';
import '../models/attendance.dart';
import '../models/complaint.dart';
import '../models/user.dart';

/// REST client + JWT session (SharedPreferences).
class ApiService extends ChangeNotifier {
  /// Call once at startup before [runApp] so session restores before routing.
  Future<void> init() => _loadToken();

  static const _keyToken = 'jwt_token';
  static const _keyUser = 'jwt_user_json';

  String? _token;
  User? _user;

  String get baseUrl => AppConfig.apiBaseUrl.replaceAll(RegExp(r'/$'), '');
  String? get token => _token;
  User? get user => _user;
  bool get isLoggedIn => _token != null && _user != null;

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_keyToken);
    final raw = prefs.getString(_keyUser);
    if (raw != null) {
      try {
        _user = User.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      } catch (_) {
        _user = null;
        _token = null;
      }
    }
    notifyListeners();
  }

  Future<void> _saveSession(String token, User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyToken, token);
    await prefs.setString(_keyUser, jsonEncode({
      'id': user.id,
      'name': user.name,
      'email': user.email,
      'isAdmin': user.isAdmin,
    }));
    _token = token;
    _user = user;
    notifyListeners();
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyToken);
    await prefs.remove(_keyUser);
    _token = null;
    _user = null;
    notifyListeners();
  }

  Map<String, String> _headers({bool jsonBody = true}) {
    final h = <String, String>{
      if (jsonBody) 'Content-Type': 'application/json',
      if (_token != null) 'Authorization': 'Bearer $_token',
    };
    return h;
  }

  Future<Map<String, dynamic>> _parse(http.Response r) async {
    try {
      final m = jsonDecode(utf8.decode(r.bodyBytes));
      if (m is Map<String, dynamic>) return m;
      return {};
    } catch (_) {
      return {'error': r.body};
    }
  }

  Future<String?> login(String email, String password) async {
    final uri = Uri.parse('$baseUrl/api/login');
    final r = await http.post(
      uri,
      headers: _headers(),
      body: jsonEncode({'email': email.trim(), 'password': password}),
    );
    final data = await _parse(r);
    if (r.statusCode >= 200 && r.statusCode < 300 && data['token'] != null) {
      final u = User.fromJson(data['user'] as Map<String, dynamic>);
      await _saveSession(data['token'] as String, u);
      return null;
    }
    return data['error']?.toString() ?? 'Login failed';
  }

  Future<String?> register(String name, String email, String password) async {
    final uri = Uri.parse('$baseUrl/api/register');
    final r = await http.post(
      uri,
      headers: _headers(),
      body: jsonEncode({
        'name': name.trim(),
        'email': email.trim(),
        'password': password,
      }),
    );
    final data = await _parse(r);
    if (r.statusCode >= 200 && r.statusCode < 300 && data['token'] != null) {
      final u = User.fromJson(data['user'] as Map<String, dynamic>);
      await _saveSession(data['token'] as String, u);
      return null;
    }
    return data['error']?.toString() ?? 'Registration failed';
  }

  Future<String?> addComplaint(String category, String description) async {
    final uri = Uri.parse('$baseUrl/api/addComplaint');
    final r = await http.post(
      uri,
      headers: _headers(),
      body: jsonEncode({'category': category, 'description': description.trim()}),
    );
    final data = await _parse(r);
    if (r.statusCode >= 200 && r.statusCode < 300) return null;
    return data['error']?.toString() ?? 'Could not submit complaint';
  }

  Future<List<Complaint>> getComplaints({bool allForAdmin = false}) async {
    var uri = Uri.parse('$baseUrl/api/getComplaints');
    if (allForAdmin && (_user?.isAdmin ?? false)) {
      uri = uri.replace(queryParameters: {'all': 'true'});
    }
    final r = await http.get(uri, headers: _headers(jsonBody: false));
    final data = await _parse(r);
    if (r.statusCode >= 200 && r.statusCode < 300) {
      final list = data['complaints'] as List<dynamic>? ?? [];
      return list.map((e) => Complaint.fromJson(e as Map<String, dynamic>)).toList();
    }
    throw Exception(data['error']?.toString() ?? 'Failed to load complaints');
  }

  Future<String?> updateComplaint(int id, String status) async {
    final uri = Uri.parse('$baseUrl/api/updateComplaint');
    final r = await http.post(
      uri,
      headers: _headers(),
      body: jsonEncode({'id': id, 'status': status}),
    );
    final data = await _parse(r);
    if (r.statusCode >= 200 && r.statusCode < 300) return null;
    return data['error']?.toString() ?? 'Update failed';
  }

  Future<List<AttendanceRecord>> getAttendance() async {
    final uri = Uri.parse('$baseUrl/api/getAttendance');
    final r = await http.get(uri, headers: _headers(jsonBody: false));
    final data = await _parse(r);
    if (r.statusCode >= 200 && r.statusCode < 300) {
      final list = data['attendance'] as List<dynamic>? ?? [];
      return list.map((e) => AttendanceRecord.fromJson(e as Map<String, dynamic>)).toList();
    }
    throw Exception(data['error']?.toString() ?? 'Failed to load attendance');
  }

  Future<String?> registerFace(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final b64 = base64Encode(bytes);
    final uri = Uri.parse('$baseUrl/api/registerFace');
    final r = await http.post(
      uri,
      headers: _headers(),
      body: jsonEncode({'imageBase64': b64}),
    );
    final data = await _parse(r);
    if (r.statusCode >= 200 && r.statusCode < 300) return null;
    return data['error']?.toString() ?? 'Face registration failed';
  }

  Future<String?> markAttendance(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final b64 = base64Encode(bytes);
    final uri = Uri.parse('$baseUrl/api/markAttendance');
    final r = await http.post(
      uri,
      headers: _headers(),
      body: jsonEncode({'imageBase64': b64}),
    );
    final data = await _parse(r);
    if (r.statusCode == 201 || r.statusCode == 200) return null;
    return data['error']?.toString() ?? 'Attendance not marked';
  }

  /// Current user profile (read).
  Future<User> getProfile() async {
    final uri = Uri.parse('$baseUrl/api/getProfile');
    final r = await http.get(uri, headers: _headers(jsonBody: false));
    final data = await _parse(r);
    if (r.statusCode >= 200 && r.statusCode < 300 && data['user'] != null) {
      return User.fromJson(data['user'] as Map<String, dynamic>);
    }
    throw Exception(data['error']?.toString() ?? 'Failed to load profile');
  }

  /// Update name and/or password for the logged-in user.
  Future<String?> updateProfile({
    String? name,
    String? currentPassword,
    String? newPassword,
  }) async {
    final uri = Uri.parse('$baseUrl/api/updateProfile');
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name.trim();
    if (newPassword != null && newPassword.isNotEmpty) {
      body['newPassword'] = newPassword;
      body['currentPassword'] = currentPassword ?? '';
    }
    final r = await http.put(uri, headers: _headers(), body: jsonEncode(body));
    final data = await _parse(r);
    if (r.statusCode >= 200 && r.statusCode < 300 && data['user'] != null) {
      final u = User.fromJson(data['user'] as Map<String, dynamic>);
      if (_token != null) await _saveSession(_token!, u);
      return null;
    }
    return data['error']?.toString() ?? 'Profile update failed';
  }

  /// Admin: list all users (no passwords).
  Future<List<User>> getUsersAdmin() async {
    final uri = Uri.parse('$baseUrl/api/getUsers');
    final r = await http.get(uri, headers: _headers(jsonBody: false));
    final data = await _parse(r);
    if (r.statusCode >= 200 && r.statusCode < 300) {
      final list = data['users'] as List<dynamic>? ?? [];
      return list.map((e) => User.fromJson(e as Map<String, dynamic>)).toList();
    }
    throw Exception(data['error']?.toString() ?? 'Failed to load users');
  }

  /// Admin: update a user (name, email, isAdmin). Returns new JWT in [outToken] when editing yourself.
  Future<String?> adminUpdateUser({
    required int id,
    String? name,
    String? email,
    bool? isAdmin,
    void Function(String newToken)? onNewToken,
  }) async {
    final uri = Uri.parse('$baseUrl/api/adminUpdateUser');
    final body = <String, dynamic>{'id': id};
    if (name != null) body['name'] = name.trim();
    if (email != null) body['email'] = email.trim().toLowerCase();
    if (isAdmin != null) body['isAdmin'] = isAdmin;
    final r = await http.post(uri, headers: _headers(), body: jsonEncode(body));
    final data = await _parse(r);
    if (r.statusCode >= 200 && r.statusCode < 300) {
      final tok = data['token'] as String?;
      if (tok != null && data['user'] != null) {
        final u = User.fromJson(data['user'] as Map<String, dynamic>);
        await _saveSession(tok, u);
        onNewToken?.call(tok);
      }
      return null;
    }
    return data['error']?.toString() ?? 'Update failed';
  }

  /// Admin: delete a user (cannot delete yourself).
  Future<String?> deleteUser(int id) async {
    final uri = Uri.parse('$baseUrl/api/deleteUser');
    final r = await http.post(
      uri,
      headers: _headers(),
      body: jsonEncode({'id': id}),
    );
    final data = await _parse(r);
    if (r.statusCode >= 200 && r.statusCode < 300) return null;
    return data['error']?.toString() ?? 'Delete failed';
  }

  /// Admin: delete a complaint by id.
  Future<String?> deleteComplaint(int id) async {
    final uri = Uri.parse('$baseUrl/api/deleteComplaint');
    final r = await http.post(
      uri,
      headers: _headers(),
      body: jsonEncode({'id': id}),
    );
    final data = await _parse(r);
    if (r.statusCode >= 200 && r.statusCode < 300) return null;
    return data['error']?.toString() ?? 'Delete failed';
  }

  /// Admin: all attendance rows (optional filter by [userId]).
  Future<List<AttendanceRecord>> getAllAttendance({int? userId}) async {
    var uri = Uri.parse('$baseUrl/api/getAllAttendance');
    if (userId != null) {
      uri = uri.replace(queryParameters: {'userId': '$userId'});
    }
    final r = await http.get(uri, headers: _headers(jsonBody: false));
    final data = await _parse(r);
    if (r.statusCode >= 200 && r.statusCode < 300) {
      final list = data['attendance'] as List<dynamic>? ?? [];
      return list.map((e) => AttendanceRecord.fromJson(e as Map<String, dynamic>)).toList();
    }
    throw Exception(data['error']?.toString() ?? 'Failed to load attendance');
  }
}
