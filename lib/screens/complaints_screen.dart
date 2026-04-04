import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../models/complaint.dart';
import '../services/auth_service.dart';
import '../services/complaint_service.dart';
import 'complaint_detail_screen.dart';
import 'complaint_submit_screen.dart';

class ComplaintsScreen extends StatelessWidget {
  const ComplaintsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthService>();
    final userId = auth.currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('My complaints')),
      body: StreamBuilder<List<Complaint>>(
        stream: context.read<ComplaintService>().streamComplaintsByUser(userId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final list = snapshot.data!;
          if (list.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text('No complaints yet', style: TextStyle(color: Colors.grey[600])),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () => context.push('/complaints/submit'),
                    icon: const Icon(Icons.add),
                    label: const Text('Submit complaint'),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            itemBuilder: (context, i) {
              final c = list[i];
              return Card(
                child: ListTile(
                  title: Text(c.subject),
                  subtitle: Text('${c.category.label} · ${c.status.label}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/complaints/${c.id}'),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/complaints/submit'),
        child: const Icon(Icons.add),
      ),
    );
  }
}
