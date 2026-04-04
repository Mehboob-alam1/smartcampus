import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../models/complaint.dart';
import '../../services/complaint_service.dart';
import 'admin_complaint_detail_screen.dart';

class AdminComplaintsScreen extends StatefulWidget {
  const AdminComplaintsScreen({super.key});

  @override
  State<AdminComplaintsScreen> createState() => _AdminComplaintsScreenState();
}

class _AdminComplaintsScreenState extends State<AdminComplaintsScreen> {
  ComplaintCategory? _filterCategory;
  ComplaintStatus? _filterStatus;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Complaint management')),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('All'),
                  selected: _filterCategory == null && _filterStatus == null,
                  onSelected: (_) => setState(() {
                    _filterCategory = null;
                    _filterStatus = null;
                  }),
                ),
                ...ComplaintCategory.values.map((c) => FilterChip(
                      label: Text(c.label),
                      selected: _filterCategory == c,
                      onSelected: (v) => setState(() => _filterCategory = v ? c : null),
                    )),
                ...ComplaintStatus.values.map((s) => FilterChip(
                      label: Text(s.label),
                      selected: _filterStatus == s,
                      onSelected: (v) => setState(() => _filterStatus = v ? s : null),
                    )),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Complaint>>(
              stream: context.read<ComplaintService>().streamAllComplaints(
                    category: _filterCategory,
                    status: _filterStatus,
                  ),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final list = snapshot.data!;
                if (list.isEmpty) {
                  return const Center(child: Text('No complaints'));
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: list.length,
                  itemBuilder: (context, i) {
                    final c = list[i];
                    return Card(
                      child: ListTile(
                        title: Text(c.subject),
                        subtitle: Text('${c.userName} · ${c.category.label} · ${c.status.label}'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.push('/admin/complaints/${c.id}'),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
