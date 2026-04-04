/// App user: student or admin.
class AppUser {
  final String id;
  final String email;
  final String displayName;
  final String? studentId;   // matricola
  final String? department;
  final bool isAdmin;
  final String? fcmToken;

  const AppUser({
    required this.id,
    required this.email,
    this.displayName = '',
    this.studentId,
    this.department,
    this.isAdmin = false,
    this.fcmToken,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'studentId': studentId,
      'department': department,
      'isAdmin': isAdmin,
      'fcmToken': fcmToken,
    };
  }

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      id: map['id'] as String,
      email: map['email'] as String,
      displayName: map['displayName'] as String? ?? '',
      studentId: map['studentId'] as String?,
      department: map['department'] as String?,
      isAdmin: map['isAdmin'] as bool? ?? false,
      fcmToken: map['fcmToken'] as String?,
    );
  }

  AppUser copyWith({
    String? id,
    String? email,
    String? displayName,
    String? studentId,
    String? department,
    bool? isAdmin,
    String? fcmToken,
  }) {
    return AppUser(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      studentId: studentId ?? this.studentId,
      department: department ?? this.department,
      isAdmin: isAdmin ?? this.isAdmin,
      fcmToken: fcmToken ?? this.fcmToken,
    );
  }
}
