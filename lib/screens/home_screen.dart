import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../services/api_service.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final api = context.watch<ApiService>();
    final u = api.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Campus'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await api.logout();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (u != null)
            Card(
              child: ListTile(
                title: Text(u.name),
                subtitle: Text(u.email),
                trailing: u.isAdmin ? const Chip(label: Text('Admin')) : null,
              ),
            ),
          const SizedBox(height: 24),
          _Btn(
            icon: Icons.report_problem_outlined,
            label: 'Submit complaint',
            onTap: () => context.push('/complaints/submit'),
          ),
          _Btn(
            icon: Icons.list_alt,
            label: 'View complaints',
            onTap: () => context.push('/complaints/list'),
          ),
          _Btn(
            icon: Icons.event_available,
            label: 'Attendance',
            onTap: () => context.push('/attendance'),
          ),
          _Btn(
            icon: Icons.person_outline,
            label: 'My profile',
            onTap: () => context.push('/profile'),
          ),
          if (u?.isAdmin ?? false) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            _Btn(
              icon: Icons.admin_panel_settings,
              label: 'Admin: manage complaints',
              onTap: () => context.push('/admin/complaints'),
            ),
            _Btn(
              icon: Icons.group_outlined,
              label: 'Admin: users',
              onTap: () => context.push('/admin/users'),
            ),
            _Btn(
              icon: Icons.calendar_month_outlined,
              label: 'Admin: all attendance',
              onTap: () => context.push('/admin/attendance'),
            ),
          ],
        ],
      ),
    );
  }
}

class _Btn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _Btn({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: FilledButton.tonalIcon(
        onPressed: onTap,
        icon: Icon(icon),
        label: Text(label),
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          alignment: Alignment.centerLeft,
        ),
      ),
    );
  }
}
