import 'package:flutter/material.dart';
import '../../../session/auth_models.dart';

class EditProfileSheet extends StatefulWidget {
  const EditProfileSheet({
    required this.user,
    required this.onSubmit,
    this.isSubmitting = false,
    super.key,
  });

  final UserModel user;
  final Future<void> Function(
    UserProfileModel profile,
    UserSettingsModel settings,
  ) onSubmit;
  final bool isSubmitting;

  @override
  State<EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<EditProfileSheet> {
  late final TextEditingController _fullNameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _bioController;
  late bool _notificationsEnabled;
  late bool _marketingEnabled;
  late bool _aiAssistEnabled;
  late String _privacyLevel;

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController(
      text: widget.user.profile?.fullName ?? '',
    );
    _phoneController = TextEditingController(
      text: widget.user.profile?.phone ?? '',
    );
    _bioController = TextEditingController(
      text: widget.user.profile?.bio ?? '',
    );
    _notificationsEnabled = widget.user.settings?.notificationsEnabled ?? true;
    _marketingEnabled = widget.user.settings?.marketingEnabled ?? false;
    _aiAssistEnabled = widget.user.settings?.aiAssistEnabled ?? true;
    _privacyLevel = widget.user.settings?.privacyLevel ?? 'community';
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final navigator = Navigator.of(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Edit profile',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 10),
            const Text(
              'Control the way your identity and preferences appear across the platform.',
              style: TextStyle(color: Color(0xFF5F645F), height: 1.5),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _fullNameController,
              decoration: const InputDecoration(
                labelText: 'Full name',
                prefixIcon: Icon(Icons.person_outline_rounded),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone',
                prefixIcon: Icon(Icons.call_outlined),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _bioController,
              minLines: 3,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Bio',
                alignLabelWithHint: true,
                prefixIcon: Icon(Icons.notes_rounded),
              ),
            ),
            const SizedBox(height: 18),
            DropdownButtonFormField<String>(
              initialValue: _privacyLevel,
              decoration: const InputDecoration(
                labelText: 'Privacy level',
                prefixIcon: Icon(Icons.shield_outlined),
              ),
              items: const [
                DropdownMenuItem(value: 'community', child: Text('Community')),
                DropdownMenuItem(
                  value: 'contacts_only',
                  child: Text('Contacts only'),
                ),
                DropdownMenuItem(value: 'private', child: Text('Private')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _privacyLevel = value);
                }
              },
            ),
            const SizedBox(height: 12),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text('Notifications'),
              subtitle: const Text('Booking, support, and marketplace alerts'),
              value: _notificationsEnabled,
              onChanged: (value) => setState(() => _notificationsEnabled = value),
            ),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text('Marketing'),
              subtitle: const Text('Product updates and growth announcements'),
              value: _marketingEnabled,
              onChanged: (value) => setState(() => _marketingEnabled = value),
            ),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text('AI assist'),
              subtitle: const Text('Recommendations and planning support'),
              value: _aiAssistEnabled,
              onChanged: (value) => setState(() => _aiAssistEnabled = value),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: widget.isSubmitting
                    ? null
                    : () async {
                        await widget.onSubmit(
                          UserProfileModel(
                            fullName: _fullNameController.text.trim().isEmpty
                                ? null
                                : _fullNameController.text.trim(),
                            phone: _phoneController.text.trim().isEmpty
                                ? null
                                : _phoneController.text.trim(),
                            bio: _bioController.text.trim().isEmpty
                                ? null
                                : _bioController.text.trim(),
                            avatarUrl: widget.user.profile?.avatarUrl,
                          ),
                          UserSettingsModel(
                            notificationsEnabled: _notificationsEnabled,
                            marketingEnabled: _marketingEnabled,
                            privacyLevel: _privacyLevel,
                            aiAssistEnabled: _aiAssistEnabled,
                          ),
                        );
                        if (mounted) {
                          navigator.pop();
                        }
                      },
                child: Text(
                  widget.isSubmitting ? 'Saving...' : 'Save profile',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
