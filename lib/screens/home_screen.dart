import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../models/app_user.dart';
import '../services/auth_service.dart';

class HomeScreen extends StatelessWidget {
  final AppUser user;

  const HomeScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Campus'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await context.read<AuthService>().signOut();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person)),
              title: Text(user.displayName.isNotEmpty ? user.displayName : user.email),
              subtitle: Text(user.email),
            ),
          ),
          const SizedBox(height: 24),
          if (user.isAdmin) ...[
            _Tile(
              icon: Icons.inbox,
              title: 'Complaint management',
              subtitle: 'View and manage complaints',
              onTap: () => context.push('/admin/complaints'),
            ),
            _Tile(
              icon: Icons.people,
              title: 'Attendance reports',
              subtitle: 'Sessions and attendance by course',
              onTap: () => context.push('/admin/attendance'),
            ),
          ] else ...[
            _Tile(
              icon: Icons.feedback,
              title: 'Complaints',
              subtitle: 'Submit and track your complaints',
              onTap: () => context.push('/complaints'),
            ),
            _Tile(
              icon: Icons.face,
              title: 'Attendance',
              subtitle: 'Register your face and view attendance',
              onTap: () => context.push('/attendance'),
            ),
          ],
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _Tile({required this.icon, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
