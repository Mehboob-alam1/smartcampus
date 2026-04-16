import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/user.dart';
import '../services/api_service.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  late Future<List<User>> _future;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _future = context.read<ApiService>().getUsersAdmin();
  }

  Future<void> _editUser(User u) async {
    final nameCtrl = TextEditingController(text: u.name);
    final emailCtrl = TextEditingController(text: u.email);
    var isAdmin = u.isAdmin;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) {
          return AlertDialog(
            title: Text('Edit user #${u.id}'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name')),
                  const SizedBox(height: 12),
                  TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email')),
                  const SizedBox(height: 12),
                  CheckboxListTile(
                    title: const Text('Admin'),
                    value: isAdmin,
                    onChanged: (v) => setLocal(() => isAdmin = v ?? false),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
              FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
            ],
          );
        },
      ),
    );
    nameCtrl.dispose();
    emailCtrl.dispose();
    if (ok != true || !mounted) return;

    final err = await context.read<ApiService>().adminUpdateUser(
          id: u.id,
          name: nameCtrl.text.trim(),
          email: emailCtrl.text.trim().toLowerCase(),
          isAdmin: isAdmin,
        );
    if (!mounted) return;
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User updated')));
      setState(_reload);
    }
  }

  Future<void> _deleteUser(User u) async {
    final api = context.read<ApiService>();
    if (u.id == api.user?.id) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You cannot delete your own account here')),
      );
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete user?'),
        content: Text('Remove ${u.name} (${u.email})? Their complaints and attendance rows will be deleted.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(ctx).colorScheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final err = await api.deleteUser(u.id);
    if (!mounted) return;
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User deleted')));
      setState(_reload);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Users (admin)')),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(_reload);
          await _future;
        },
        child: FutureBuilder<List<User>>(
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
              return const Center(child: Text('No users'));
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: list.length,
              itemBuilder: (_, i) {
                final u = list[i];
                return Card(
                  child: ListTile(
                    title: Text(u.name),
                    subtitle: Text(u.email),
                    trailing: u.isAdmin ? const Chip(label: Text('Admin')) : null,
                    onTap: () => _editUser(u),
                    onLongPress: () => _deleteUser(u),
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
