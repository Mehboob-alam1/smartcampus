import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/attendance_record.dart';
import '../../services/attendance_service.dart';

class AdminAttendanceScreen extends StatelessWidget {
  const AdminAttendanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Attendance reports')),
      body: StreamBuilder<List<AttendanceSession>>(
        stream: context.read<AttendanceService>().streamSessions(),
        builder: (context, sessionSnap) {
          if (sessionSnap.hasError) {
            return Center(child: Text('Error: ${sessionSnap.error}'));
          }
          if (!sessionSnap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final sessions = sessionSnap.data!;
          if (sessions.isEmpty) {
            return const Center(
              child: Text('No attendance sessions yet. Create a session from the backend or the instructor app.'),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sessions.length,
            itemBuilder: (context, i) {
              final s = sessions[i];
              return Card(
                child: ListTile(
                  title: Text(s.courseName),
                  subtitle: Text(DateFormat.yMMMd('en').format(s.date)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _openSessionDetail(context, s.id, s.courseName),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _openSessionDetail(BuildContext context, String sessionId, String courseName) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        expand: false,
        builder: (context, scrollController) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Attendance — $courseName', style: Theme.of(context).textTheme.titleLarge),
              ),
              Expanded(
                child: StreamBuilder<List<AttendanceRecord>>(
                  stream: context.read<AttendanceService>().streamAttendanceBySession(sessionId),
                  builder: (context, snap) {
                    if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                    final list = snap.data!;
                    if (list.isEmpty) return const Center(child: Text('No attendance records'));
                    return ListView.builder(
                      controller: scrollController,
                      itemCount: list.length,
                      itemBuilder: (context, j) {
                        final r = list[j];
                        return ListTile(
                          title: Text(r.userName),
                          subtitle: Text(r.userEmail),
                          trailing: Text(DateFormat('HH:mm').format(r.markedAt)),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
