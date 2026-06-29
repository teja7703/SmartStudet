import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/avatar_image.dart';
import '../../auth/cubit/auth_cubit.dart';
import '../../auth/cubit/auth_state.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController _nameController;
  String _photoUrl = '';
  bool _saving = false;

  /// Whether the user signed in with email/Google (photo is managed there).
  bool _photoLocked = false;

  @override
  void initState() {
    super.initState();
    final state = context.read<AuthCubit>().state;
    final user = state is AuthAuthenticated ? state.user : null;
    _nameController = TextEditingController(text: user?.name ?? '');
    _photoUrl = user?.photoUrl ?? '';
    _photoLocked = (user?.email ?? '').isNotEmpty;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        // Keep it small: stored as a base64 data URI on the backend so the
        // avatar follows the account to any device.
        maxWidth: 400,
        maxHeight: 400,
        imageQuality: 70,
      );
      if (picked == null) return;

      final bytes = await picked.readAsBytes();
      final dataUri = 'data:image/jpeg;base64,${base64Encode(bytes)}';

      setState(() => _photoUrl = dataUri);
    } catch (_) {
      if (mounted) _snack('Could not pick image. Please try again.');
    }
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _snack('Please enter your name');
      return;
    }
    setState(() => _saving = true);
    try {
      await context.read<AuthCubit>().updateProfile(
            name: name,
            photoUrl: _photoUrl,
          );
      if (!mounted) return;
      _snack('Profile updated');
      context.pop();
    } catch (_) {
      if (mounted) _snack('Could not update profile. Please try again.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final provider = avatarProvider(_photoUrl);

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 8),
          Center(
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 56,
                  backgroundColor: AppColors.blueTint,
                  backgroundImage: provider,
                  child: provider == null
                      ? const Icon(Icons.person,
                          size: 56, color: AppColors.primaryBlue)
                      : null,
                ),
                if (!_photoLocked)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: GestureDetector(
                      onTap: _pickPhoto,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: AppColors.primaryBlue,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.camera_alt_rounded,
                            color: Colors.white, size: 18),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              _photoLocked
                  ? 'Photo is managed by your Google account'
                  : 'Tap the camera to change your photo',
              style: AppTextStyles.labelMedium,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 28),
          Text('Full Name', style: AppTextStyles.labelLarge),
          const SizedBox(height: 8),
          TextField(
            controller: _nameController,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              hintText: 'Enter your name',
              prefixIcon: Icon(Icons.person_outline_rounded),
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Save Changes'),
            ),
          ),
        ],
      ),
    );
  }
}
