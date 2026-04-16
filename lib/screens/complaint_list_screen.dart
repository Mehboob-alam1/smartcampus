import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/complaint.dart';
import '../services/api_service.dart';

class ComplaintListScreen extends StatefulWidget {
  const ComplaintListScreen({super.key});

  @override
  State<ComplaintListScreen> createState() => _ComplaintListScreenState();
}

class _ComplaintListScreenState extends State<ComplaintListScreen> {
  late Future<List<Complaint>> _future;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _future = context.read<ApiService>().getComplaints(allForAdmin: false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My complaints')),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(_reload);
          await _future;
        },
        child: FutureBuilder<List<Complaint>>(
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
              return  ListView(
                physics: AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(height: 120),
                  Center(child: Text('No complaints yet')),
                ],
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: list.length,
              itemBuilder: (_, i) {
                final c = list[i];
                final dateStr = c.createdAt != null
                    ? DateFormat.yMMMd().add_jm().format(c.createdAt!.toLocal())
                    : '';
                return Card(
                  child: ListTile(
                    title: Text(c.category[0].toUpperCase() + c.category.substring(1)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(c.description),
                        if (dateStr.isNotEmpty) Text(dateStr, style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                    isThreeLine: true,
                    trailing: Chip(label: Text(c.statusLabel)),
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
