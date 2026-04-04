import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../models/complaint.dart';
import '../services/complaint_service.dart';

class ComplaintDetailScreen extends StatelessWidget {
  final String complaintId;

  const ComplaintDetailScreen({super.key, required this.complaintId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Complaint details')),
      body: FutureBuilder<Complaint?>(
        future: context.read<ComplaintService>().getComplaint(complaintId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final c = snapshot.data!;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(c.subject, style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Chip(label: Text(c.category.label)),
                            const SizedBox(width: 8),
                            Chip(label: Text(c.status.label)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(c.description),
                        const SizedBox(height: 16),
                        Text('Submitted on ${DateFormat('MMM d, y • HH:mm', 'en').format(c.createdAt)}', style: Theme.of(context).textTheme.bodySmall),
                        if (c.adminFeedback != null) ...[
                          const Divider(),
                          Text('Admin response:', style: Theme.of(context).textTheme.titleSmall),
                          const SizedBox(height: 4),
                          Text(c.adminFeedback!),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
