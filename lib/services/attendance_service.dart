import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import '../models/attendance_record.dart';

/// Attendance: Firestore + Python face-recognition backend calls.
class AttendanceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _recordsCollection = 'attendance_records';
  static const String _sessionsCollection = 'attendance_sessions';
  static const String _facesCollection = 'face_embeddings';

  /// Python face-recognition base URL (change for production).
  static String faceServiceBaseUrl = 'http://10.0.2.2:8000'; // Android emulator -> localhost

  /// Register a face image for the user (Python backend saves embedding).
  Future<bool> registerFace(String userId, String userEmail, String userName, File imageFile) async {
    try {
      final uri = Uri.parse('$faceServiceBaseUrl/register');
      final request = http.MultipartRequest('POST', uri);
      request.fields['user_id'] = userId;
      request.fields['user_email'] = userEmail;
      request.fields['user_name'] = userName;
      request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));
      final response = await http.Response.fromStream(await request.send());
      if (response.statusCode != 200) return false;
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (body['success'] != true) return false;
      // Optional Firestore flag: userId -> registered
      await _firestore.collection(_facesCollection).doc(userId).set({
        'userId': userId,
        'registeredAt': DateTime.now().toIso8601String(),
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Whether the user has already registered a face.
  Future<bool> isFaceRegistered(String userId) async {
    final doc = await _firestore.collection(_facesCollection).doc(userId).get();
    return doc.exists;
  }

  /// Record attendance (manual or after face verification).
  Future<void> markAttendance({
    required String userId,
    required String userEmail,
    required String userName,
    String? studentId,
    required String sessionId,
    required String courseName,
    bool verified = true,
  }) async {
    final ref = _firestore.collection(_recordsCollection).doc();
    final record = AttendanceRecord(
      id: ref.id,
      userId: userId,
      userEmail: userEmail,
      userName: userName,
      studentId: studentId,
      sessionId: sessionId,
      courseName: courseName,
      markedAt: DateTime.now(),
      verified: verified,
    );
    await ref.set(record.toMap());
  }

  /// Create a class session (admin / instructor).
  Future<String> createSession({
    required String courseName,
    required String courseId,
    required DateTime date,
    String? conductedBy,
  }) async {
    final ref = _firestore.collection(_sessionsCollection).doc();
    final session = AttendanceSession(
      id: ref.id,
      courseName: courseName,
      courseId: courseId,
      date: date,
      conductedBy: conductedBy,
    );
    await ref.set(session.toMap());
    return ref.id;
  }

  Stream<List<AttendanceRecord>> streamAttendanceByUser(String userId) {
    return _firestore
        .collection(_recordsCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('markedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => AttendanceRecord.fromMap(d.data())).toList());
  }

  Stream<List<AttendanceRecord>> streamAttendanceBySession(String sessionId) {
    return _firestore
        .collection(_recordsCollection)
        .where('sessionId', isEqualTo: sessionId)
        .snapshots()
        .map((snap) => snap.docs.map((d) => AttendanceRecord.fromMap(d.data())).toList());
  }

  Stream<List<AttendanceSession>> streamSessions() {
    return _firestore
        .collection(_sessionsCollection)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => AttendanceSession.fromMap(d.data())).toList());
  }

  /// Verify face from image (Python backend).
  Future<Map<String, dynamic>?> verifyFaceAndMark(File imageFile, String sessionId, String courseName) async {
    try {
      final uri = Uri.parse('$faceServiceBaseUrl/verify');
      final request = http.MultipartRequest('POST', uri);
      request.fields['session_id'] = sessionId;
      request.fields['course_name'] = courseName;
      request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));
      final response = await http.Response.fromStream(await request.send());
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return body;
    } catch (_) {
      return null;
    }
  }
}
