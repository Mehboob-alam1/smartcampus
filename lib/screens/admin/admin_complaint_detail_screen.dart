import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../models/complaint.dart';
import '../../services/complaint_service.dart';

class AdminComplaintDetailScreen extends StatefulWidget {
  final String complaintId;

  const AdminComplaintDetailScreen({super.key, required this.complaintId});

  @override
  State<AdminComplaintDetailScreen> createState() => _AdminComplaintDetailScreenState();
}

class _AdminComplaintDetailScreenState extends State<AdminComplaintDetailScreen> {
  final _feedbackController = TextEditingController();
  ComplaintStatus _status = ComplaintStatus.submitted;
  Complaint? _complaint;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final c = await context.read<ComplaintService>().getComplaint(widget.complaintId);
    if (mounted && c != null) {
      setState(() {
        _complaint = c;
        _status = c.status;
        _feedbackController.text = c.adminFeedback ?? '';
      });
    }
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  Future<void> _update() async {
    if (_complaint == null) return;
    setState(() => _loading = true);
    try {
      await context.read<ComplaintService>().updateStatus(
            widget.complaintId,
            _status,
            adminFeedback: _feedbackController.text.trim().isEmpty ? null : _feedbackController.text.trim(),
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Updated')));
        context.pop();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_complaint == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final c = _complaint!;
    return Scaffold(
      appBar: AppBar(title: const Text('Complaint')),
      body: SingleChildScrollView(
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
                    Text('From: ${c.userName} (${c.userEmail})'),
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
                    const SizedBox(height: 8),
                    Text('Submitted on ${DateFormat('MMM d, y • HH:mm', 'en').format(c.createdAt)}', style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Status'),
            const SizedBox(height: 8),
            DropdownButtonFormField<ComplaintStatus>(
              value: _status,
              items: ComplaintStatus.values
                  .map((s) => DropdownMenuItem(value: s, child: Text(s.label)))
                  .toList(),
              onChanged: (v) => setState(() => _status = v ?? _status),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _feedbackController,
              decoration: const InputDecoration(labelText: 'Response / feedback'),
              maxLines: 4,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _loading ? null : _update,
              child: _loading ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
