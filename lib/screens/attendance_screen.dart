import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../models/attendance_record.dart';
import '../services/auth_service.dart';
import '../services/attendance_service.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  bool? _faceRegistered;

  @override
  void initState() {
    super.initState();
    _checkFace();
  }

  Future<void> _checkFace() async {
    final userId = context.read<AuthService>().currentUser?.uid ?? '';
    final reg = await context.read<AttendanceService>().isFaceRegistered(userId);
    if (mounted) setState(() => _faceRegistered = reg);
  }

  @override
  Widget build(BuildContext context) {
    final userId = context.read<AuthService>().currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('My attendance')),
      body: _faceRegistered == null
          ? const Center(child: CircularProgressIndicator())
          : _faceRegistered != true
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.face_retouching_natural, size: 64, color: Colors.grey[600]),
                        const SizedBox(height: 16),
                        const Text(
                          'Register your face to use automatic attendance check-in.',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        FilledButton.icon(
                          onPressed: () => context.push('/attendance/register-face').then((_) => _checkFace()),
                          icon: const Icon(Icons.face),
                          label: const Text('Register face'),
                        ),
                      ],
                    ),
                  ),
                )
              : StreamBuilder<List<AttendanceRecord>>(
                  stream: context.read<AttendanceService>().streamAttendanceByUser(userId),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final list = snapshot.data!;
                    if (list.isEmpty) {
                      return const Center(child: Text('No attendance recorded yet'));
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: list.length,
                      itemBuilder: (context, i) {
                        final r = list[i];
                        return Card(
                          child: ListTile(
                            title: Text(r.courseName),
                            subtitle: Text(DateFormat('MMM d, y • HH:mm', 'en').format(r.markedAt)),
                            trailing: r.verified ? const Icon(Icons.verified, color: Colors.green) : null,
                          ),
                        );
                      },
                    );
                  },
                ),
      floatingActionButton: _faceRegistered == true
          ? null
          : FloatingActionButton(
              onPressed: () => context.push('/attendance/register-face').then((_) => _checkFace()),
              child: const Icon(Icons.face),
            ),
    );
  }
}
