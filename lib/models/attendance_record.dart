/// Single attendance record (one class session).
class AttendanceRecord {
  final String id;
  final String userId;
  final String userEmail;
  final String userName;
  final String? studentId;
  final String sessionId; // e.g. courseId_date
  final String courseName;
  final DateTime markedAt;
  final bool verified; // verified via face recognition

  const AttendanceRecord({
    required this.id,
    required this.userId,
    required this.userEmail,
    required this.userName,
    this.studentId,
    required this.sessionId,
    required this.courseName,
    required this.markedAt,
    this.verified = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'userEmail': userEmail,
      'userName': userName,
      'studentId': studentId,
      'sessionId': sessionId,
      'courseName': courseName,
      'markedAt': markedAt.toIso8601String(),
      'verified': verified,
    };
  }

  factory AttendanceRecord.fromMap(Map<String, dynamic> map) {
    return AttendanceRecord(
      id: map['id'] as String,
      userId: map['userId'] as String,
      userEmail: map['userEmail'] as String,
      userName: map['userName'] as String,
      studentId: map['studentId'] as String?,
      sessionId: map['sessionId'] as String,
      courseName: map['courseName'] as String,
      markedAt: DateTime.parse(map['markedAt'] as String),
      verified: map['verified'] as bool? ?? true,
    );
  }
}

/// Sessione di lezione (per raggruppare le presenze).
class AttendanceSession {
  final String id;
  final String courseName;
  final String courseId;
  final DateTime date;
  final String? conductedBy;

  const AttendanceSession({
    required this.id,
    required this.courseName,
    required this.courseId,
    required this.date,
    this.conductedBy,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'courseName': courseName,
      'courseId': courseId,
      'date': date.toIso8601String(),
      'conductedBy': conductedBy,
    };
  }

  factory AttendanceSession.fromMap(Map<String, dynamic> map) {
    return AttendanceSession(
      id: map['id'] as String,
      courseName: map['courseName'] as String,
      courseId: map['courseId'] as String,
      date: DateTime.parse(map['date'] as String),
      conductedBy: map['conductedBy'] as String?,
    );
  }
}
