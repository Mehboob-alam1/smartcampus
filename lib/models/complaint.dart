class Complaint {
  final int id;
  final int? userId;
  final String category;
  final String description;
  final String status;
  final DateTime? createdAt;
  final String? userName;

  const Complaint({
    required this.id,
    this.userId,
    required this.category,
    required this.description,
    required this.status,
    this.createdAt,
    this.userName,
  });

  String get statusLabel {
    switch (status.toLowerCase()) {
      case 'resolved':
        return 'Resolved';
      default:
        return 'Pending';
    }
  }

  factory Complaint.fromJson(Map<String, dynamic> json) {
    return Complaint(
      id: (json['id'] as num).toInt(),
      userId: json['userId'] != null ? (json['userId'] as num).toInt() : null,
      category: json['category'] as String? ?? '',
      description: json['description'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
      userName: json['userName'] as String?,
    );
  }
}
