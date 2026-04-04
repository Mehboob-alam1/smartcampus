import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/attendance_service.dart';

class FaceRegisterScreen extends StatefulWidget {
  const FaceRegisterScreen({super.key});

  @override
  State<FaceRegisterScreen> createState() => _FaceRegisterScreenState();
}

class _FaceRegisterScreenState extends State<FaceRegisterScreen> {
  bool _loading = false;
  File? _image;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final x = await picker.pickImage(source: ImageSource.camera, imageQuality: 85);
    if (x != null) {
      setState(() => _image = File(x.path));
    }
  }

  Future<void> _register() async {
    if (_image == null) return;
    setState(() => _loading = true);
    try {
      final user = await context.read<AuthService>().getCurrentAppUser();
      if (user == null) throw Exception('User not found');
      final ok = await context.read<AttendanceService>().registerFace(
            user.id,
            user.email,
            user.displayName.isNotEmpty ? user.displayName : user.email,
            _image!,
          );
      if (mounted) {
        if (ok) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Face registered')));
          context.pop();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Registration failed. Try again with a clear front-facing photo.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register face')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text(
              'Take a front-facing photo of your face to enable recognition during classes.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (_image != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(_image!, height: 280, width: double.infinity, fit: BoxFit.cover),
              )
            else
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 280,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.camera_alt, size: 64, color: Colors.grey[600]),
                      const SizedBox(height: 8),
                      Text('Tap to take a photo', style: TextStyle(color: Colors.grey[600])),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 24),
            if (_image != null)
              FilledButton(
                onPressed: _loading ? null : _register,
                child: _loading ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Register face'),
              )
            else
              OutlinedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.camera_alt),
                label: const Text('Take photo'),
              ),
          ],
        ),
      ),
    );
  }
}
