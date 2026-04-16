import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/attendance.dart';
import '../services/api_service.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  late Future<List<AttendanceRecord>> _future;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _future = context.read<ApiService>().getAttendance();
  }

  Future<void> _registerFace() async {
    final picker = ImagePicker();
    final x = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
      maxWidth: 800,
      maxHeight: 800,
    );
    if (x == null || !mounted) return;
    setState(() => _busy = true);
    final err = await context.read<ApiService>().registerFace(File(x.path));
    if (!mounted) return;
    setState(() => _busy = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(err ?? 'Face registered — you can mark attendance')),
    );
  }

  Future<void> _markAttendance() async {
    final picker = ImagePicker();
    final x = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
      maxWidth: 800,
      maxHeight: 800,
    );
    if (x == null || !mounted) return;
    setState(() => _busy = true);
    final err = await context.read<ApiService>().markAttendance(File(x.path));
    if (!mounted) return;
    setState(() {
      _busy = false;
      _reload();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(err ?? 'Attendance recorded')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Attendance')),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: () async {
              setState(_reload);
              await _future;
            },
            child: FutureBuilder<List<AttendanceRecord>>(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return  ListView(children: [SizedBox(height: 200), Center(child: CircularProgressIndicator())]);
                }
                if (snap.hasError) {
                  return ListView(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text('Error: ${snap.error}', textAlign: TextAlign.center),
                      ),
                    ],
                  );
                }
                final list = snap.data ?? [];
                if (list.isEmpty) {
                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(24),
                    children: const [
                      SizedBox(height: 48),
                      Text(
                        'No attendance records yet.\nUse the buttons below: register your face once, then mark attendance with a selfie.',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: list.length,
                  itemBuilder: (_, i) {
                    final r = list[i];
                    return Card(
                      child: ListTile(
                        title: Text(DateFormat.yMMMd().format(r.date)),
                        subtitle: Text(r.status),
                        trailing: Icon(
                          r.status == 'present' ? Icons.check_circle : Icons.cancel,
                          color: r.status == 'present' ? Colors.green : Colors.grey,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          if (_busy) const ModalBarrier(dismissible: false, color: Color(0x33000000)),
          if (_busy) const Center(child: CircularProgressIndicator()),
        ],
      ),
      floatingActionButton: _busy
          ? null
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                FloatingActionButton.extended(
                  heroTag: 'reg',
                  onPressed: _registerFace,
                  icon: const Icon(Icons.face),
                  label: const Text('Register face'),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.extended(
                  heroTag: 'mark',
                  onPressed: _markAttendance,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Mark attendance'),
                ),
              ],
            ),
    );
  }
}
