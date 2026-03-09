import 'package:flutter/material.dart';
import '../../models/mock_user.dart';
import '../../utils/contants.dart';
import '../../widgets/reusable_input.dart';

class EditProfileScreen extends StatefulWidget {
  final UserProfile user;

  const EditProfileScreen({super.key, required this.user});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _bioController;
  late TextEditingController _locationController;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.fullName);
    _bioController = TextEditingController(text: widget.user.bio);
    _locationController = TextEditingController(text: widget.user.location);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    setState(() => _saving = true);

    final updated = widget.user.copyWith(
      fullName: name,
      bio: _bioController.text.trim(),
      location: _locationController.text.trim(),
    );

    try {
      await updated.save();
      if (mounted) Navigator.of(context).pop(updated);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _saving = false);
      }
    }
  }

  void _cancel() => Navigator.of(context).pop();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.white),
          onPressed: _cancel,
        ),
        title: const Text(
          'Edit Profile',
          style: TextStyle(
            color: AppColors.white,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          children: [
            // ── Avatar upload placeholder ──
            _AvatarPicker(avatarUrl: widget.user.avatarUrl),
            const SizedBox(height: 28),

            // ── Form fields ──
            ReusableInput(
              label: 'Full Name',
              hint: 'Enter your full name',
              controller: _nameController,
              prefixIcon: const Icon(Icons.person_outline,
                  color: AppColors.accent, size: 20),
            ),
            const SizedBox(height: 18),

            ReusableInput(
              label: 'Bio',
              hint: 'Tell us about yourself...',
              controller: _bioController,
              maxLines: 3,
              keyboardType: TextInputType.multiline,
            ),
            const SizedBox(height: 18),

            ReusableInput(
              label: 'Location',
              hint: 'e.g. San Francisco, CA',
              controller: _locationController,
              prefixIcon: const Icon(Icons.location_on_outlined,
                  color: AppColors.accent, size: 20),
            ),
            const SizedBox(height: 32),

            // ── Action buttons ──
            Row(
              children: [
                // Cancel (secondary)
                Expanded(
                  child: OutlinedButton(
                    onPressed: _saving ? null : _cancel,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: AppColors.white.withValues(alpha: 0.3),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: AppColors.white.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w500,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                // Save (primary)
                Expanded(
                  child: ElevatedButton(
                    onPressed: _saving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: AppColors.bg,
                      disabledBackgroundColor:
                          AppColors.accent.withValues(alpha: 0.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: _saving
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.bg,
                            ),
                          )
                        : const Text(
                            'Save',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Avatar Picker ──────────────────────────────────────

class _AvatarPicker extends StatelessWidget {
  final String? avatarUrl;
  const _AvatarPicker({this.avatarUrl});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        children: [
          CircleAvatar(
            radius: 52,
            backgroundColor: AppColors.card,
            backgroundImage:
                avatarUrl != null ? NetworkImage(avatarUrl!) : null,
            child: avatarUrl == null
                ? const Icon(Icons.person, size: 52, color: AppColors.white)
                : null,
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(7),
              decoration: const BoxDecoration(
                color: AppColors.accent,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.camera_alt, size: 18, color: AppColors.bg),
            ),
          ),
        ],
      ),
    );
  }
}
