import 'package:flutter/material.dart';
import '../../../session/auth_api_client.dart';
import '../../../session/auth_models.dart';
import '../../../uploads/upload_models.dart';
import '../../../widgets/upload_field_card.dart';

class EditProfileSheet extends StatefulWidget {
  const EditProfileSheet({
    required this.accessToken,
    required this.user,
    required this.onSubmit,
    this.isSubmitting = false,
    super.key,
  });

  final String accessToken;
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
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _fullNameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _bioController;
  late final TextEditingController _avatarUrlController;
  late bool _notificationsEnabled;
  late bool _marketingEnabled;
  late bool _aiAssistEnabled;
  late String _privacyLevel;
  String? _errorMessage;
  bool _isSaving = false;

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
    _avatarUrlController = TextEditingController(
      text: widget.user.profile?.avatarUrl ?? '',
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
    _avatarUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final navigator = Navigator.of(context);
    final isSubmitting = widget.isSubmitting || _isSaving;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Edit profile',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 20),
              if (_errorMessage != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFCECEA),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFE1B7B2)),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(
                      color: Color(0xFF9F2D20),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              TextFormField(
                controller: _fullNameController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Full name',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                ),
                validator: (value) {
                  final trimmed = value?.trim() ?? '';
                  if (trimmed.length > 120) {
                    return 'Keep the name under 120 characters.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Phone',
                  hintText: '+14155550123',
                  prefixIcon: Icon(Icons.call_outlined),
                ),
                validator: (value) {
                  final trimmed = value?.trim() ?? '';
                  if (trimmed.isEmpty) {
                    return null;
                  }
                  final pattern = RegExp(r'^\+?[1-9]\d{7,14}$');
                  if (!pattern.hasMatch(trimmed)) {
                    return 'Use an international format like +14155550123.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _bioController,
                minLines: 3,
                maxLines: 5,
                textInputAction: TextInputAction.newline,
                decoration: const InputDecoration(
                  labelText: 'Bio',
                  alignLabelWithHint: true,
                  prefixIcon: Icon(Icons.notes_rounded),
                ),
                validator: (value) {
                  final trimmed = value?.trim() ?? '';
                  if (trimmed.length > 500) {
                    return 'Keep the bio under 500 characters.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 18),
              UploadFieldCard(
                label: 'Avatar image',
                accessToken: widget.accessToken,
                controller: _avatarUrlController,
                kind: UploadAssetKind.image,
                previewHeight: 140,
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
                onChanged: isSubmitting
                    ? null
                    : (value) {
                        if (value != null) {
                          setState(() => _privacyLevel = value);
                        }
                      },
              ),
              const SizedBox(height: 12),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text('Notifications'),
                value: _notificationsEnabled,
                onChanged: isSubmitting
                    ? null
                    : (value) =>
                        setState(() => _notificationsEnabled = value),
              ),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text('Marketing'),
                value: _marketingEnabled,
                onChanged: isSubmitting
                    ? null
                    : (value) => setState(() => _marketingEnabled = value),
              ),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text('AI assist'),
                subtitle: const Text(
                  'Enables AI drafting and automatic chat replies for this profile.',
                ),
                value: _aiAssistEnabled,
                onChanged: isSubmitting
                    ? null
                    : (value) => setState(() => _aiAssistEnabled = value),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          FocusScope.of(context).unfocus();
                          final form = _formKey.currentState;
                          if (form == null || !form.validate()) {
                            return;
                          }

                          final avatarUrl = _avatarUrlController.text.trim();
                          if (avatarUrl.isNotEmpty) {
                            final parsed = Uri.tryParse(avatarUrl);
                            final isHttp = parsed != null &&
                                parsed.hasScheme &&
                                (parsed.scheme == 'http' ||
                                    parsed.scheme == 'https');
                            if (!isHttp) {
                              setState(() {
                                _errorMessage =
                                    'Avatar image must use a valid http or https URL.';
                              });
                              return;
                            }
                          }

                          setState(() {
                            _errorMessage = null;
                            _isSaving = true;
                          });

                          try {
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
                                avatarUrl: avatarUrl.isEmpty ? null : avatarUrl,
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
                          } on ApiException catch (error) {
                            if (!mounted) {
                              return;
                            }
                            setState(() => _errorMessage = error.message);
                          } catch (_) {
                            if (!mounted) {
                              return;
                            }
                            setState(() {
                              _errorMessage =
                                  'Profile update failed. Try again.';
                            });
                          } finally {
                            if (mounted) {
                              setState(() => _isSaving = false);
                            }
                          }
                        },
                  child: Text(isSubmitting ? 'Saving...' : 'Save profile'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
