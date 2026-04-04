/// Complaint categories (hostel, transport, cafeteria, other).
enum ComplaintCategory {
  hostel,
  transport,
  cafeteria,
  other;

  String get label {
    switch (this) {
      case ComplaintCategory.hostel:
        return 'Hostel';
      case ComplaintCategory.transport:
        return 'Transport';
      case ComplaintCategory.cafeteria:
        return 'Cafeteria';
      case ComplaintCategory.other:
        return 'Other';
    }
  }

  static ComplaintCategory fromString(String value) {
    return ComplaintCategory.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ComplaintCategory.other,
    );
  }
}

/// Complaint workflow status.
enum ComplaintStatus {
  submitted,
  inProgress,
  resolved,
  closed;

  String get label {
    switch (this) {
      case ComplaintStatus.submitted:
        return 'Submitted';
      case ComplaintStatus.inProgress:
        return 'In progress';
      case ComplaintStatus.resolved:
        return 'Resolved';
      case ComplaintStatus.closed:
        return 'Closed';
    }
  }

  static ComplaintStatus fromString(String value) {
    return ComplaintStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ComplaintStatus.submitted,
    );
  }
}

/// Complaint model.
class Complaint {
  final String id;
  final String userId;
  final String userEmail;
  final String userName;
  final ComplaintCategory category;
  final String subject;
  final String description;
  final ComplaintStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? adminFeedback;
  final String? assignedTo;

  const Complaint({
    required this.id,
    required this.userId,
    required this.userEmail,
    required this.userName,
    required this.category,
    required this.subject,
    required this.description,
    required this.status,
    required this.createdAt,
    this.updatedAt,
    this.adminFeedback,
    this.assignedTo,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'userEmail': userEmail,
      'userName': userName,
      'category': category.name,
      'subject': subject,
      'description': description,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'adminFeedback': adminFeedback,
      'assignedTo': assignedTo,
    };
  }

  factory Complaint.fromMap(Map<String, dynamic> map) {
    return Complaint(
      id: map['id'] as String,
      userId: map['userId'] as String,
      userEmail: map['userEmail'] as String,
      userName: map['userName'] as String,
      category: ComplaintCategory.fromString(map['category'] as String? ?? 'other'),
      subject: map['subject'] as String,
      description: map['description'] as String,
      status: ComplaintStatus.fromString(map['status'] as String? ?? 'submitted'),
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt'] as String) : null,
      adminFeedback: map['adminFeedback'] as String?,
      assignedTo: map['assignedTo'] as String?,
    );
  }

  Complaint copyWith({
    String? id,
    String? userId,
    String? userEmail,
    String? userName,
    ComplaintCategory? category,
    String? subject,
    String? description,
    ComplaintStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? adminFeedback,
    String? assignedTo,
  }) {
    return Complaint(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userEmail: userEmail ?? this.userEmail,
      userName: userName ?? this.userName,
      category: category ?? this.category,
      subject: subject ?? this.subject,
      description: description ?? this.description,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      adminFeedback: adminFeedback ?? this.adminFeedback,
      assignedTo: assignedTo ?? this.assignedTo,
    );
  }
}
