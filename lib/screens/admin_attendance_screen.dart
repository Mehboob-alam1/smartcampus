import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/attendance.dart';
import '../models/user.dart';
import '../services/api_service.dart';

class AdminAttendanceScreen extends StatefulWidget {
  const AdminAttendanceScreen({super.key});

  @override
  State<AdminAttendanceScreen> createState() => _AdminAttendanceScreenState();
}

class _AdminAttendanceScreenState extends State<AdminAttendanceScreen> {
  List<User> _users = [];
  int? _filterUserId;
  late Future<List<AttendanceRecord>> _future;

  @override
  void initState() {
    super.initState();
    _future = context.read<ApiService>().getAllAttendance();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    try {
      final list = await context.read<ApiService>().getUsersAdmin();
      if (mounted) setState(() => _users = list);
    } catch (_) {}
  }

  void _reload() {
    _future = context.read<ApiService>().getAllAttendance(userId: _filterUserId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance (admin)'),
        actions: [
          PopupMenuButton<int?>(
            tooltip: 'Filter by user',
            onSelected: (id) {
              setState(() {
                _filterUserId = id;
                _reload();
              });
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: null, child: Text('All users')),
              ..._users.map(
                (u) => PopupMenuItem(value: u.id, child: Text('${u.name} (#${u.id})')),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(_reload);
          await _future;
        },
        child: FutureBuilder<List<AttendanceRecord>>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [Center(child: Padding(padding: const EdgeInsets.all(24), child: Text('${snap.error}')))],
              );
            }
            final list = snap.data ?? [];
            if (list.isEmpty) {
              return const Center(child: Text('No attendance records'));
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: list.length,
              itemBuilder: (_, i) {
                final a = list[i];
                final who = a.userName != null ? '${a.userName} (#${a.userId})' : 'User #${a.userId}';
                return Card(
                  child: ListTile(
                    title: Text(who),
                    subtitle: Text('${a.date.toString().split(' ').first} · ${a.status}'),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
