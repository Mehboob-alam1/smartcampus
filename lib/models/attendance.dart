class AttendanceRecord {
  final int id;
  final int userId;
  final DateTime date;
  final String status;

  const AttendanceRecord({
    required this.id,
    required this.userId,
    required this.date,
    required this.status,
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      id: (json['id'] as num).toInt(),
      userId: (json['userId'] as num).toInt(),
      date: DateTime.parse(json['date'].toString()),
      status: json['status'] as String? ?? 'absent',
    );
  }
}
