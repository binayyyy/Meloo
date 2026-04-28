import 'package:flutter/material.dart';
import '../../../sponsors/sponsor_models.dart';
import '../../../uploads/upload_models.dart';
import '../../../widgets/modal_form_scaffold.dart';
import '../../../widgets/upload_field_card.dart';

class SponsorProfileSheet extends StatefulWidget {
  const SponsorProfileSheet({
    required this.accessToken,
    required this.initialProfile,
    required this.onSubmit,
    required this.isSubmitting,
    super.key,
  });

  final String accessToken;
  final SponsorProfileModel? initialProfile;
  final Future<void> Function(SponsorProfileUpsertRequest request) onSubmit;
  final bool isSubmitting;

  @override
  State<SponsorProfileSheet> createState() => _SponsorProfileSheetState();
}

class _SponsorProfileSheetState extends State<SponsorProfileSheet> {
  late final TextEditingController _companyNameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _industriesController;
  late final TextEditingController _logoUrlController;
  late final TextEditingController _websiteUrlController;
  late final TextEditingController _verificationDocumentUrlController;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    final profile = widget.initialProfile;
    _companyNameController =
        TextEditingController(text: profile?.companyName ?? '');
    _descriptionController =
        TextEditingController(text: profile?.description ?? '');
    _industriesController =
        TextEditingController(text: profile?.industries ?? '');
    _logoUrlController = TextEditingController(text: profile?.logoUrl ?? '');
    _websiteUrlController =
        TextEditingController(text: profile?.websiteUrl ?? '');
    _verificationDocumentUrlController = TextEditingController(
      text: profile?.verificationDocumentUrl ?? '',
    );
  }

  @override
  void dispose() {
    _companyNameController.dispose();
    _descriptionController.dispose();
    _industriesController.dispose();
    _logoUrlController.dispose();
    _websiteUrlController.dispose();
    _verificationDocumentUrlController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    await widget.onSubmit(
      SponsorProfileUpsertRequest(
        companyName: _companyNameController.text.trim(),
        description: _descriptionController.text.trim(),
        industries: _industriesController.text.trim(),
        logoUrl: _logoUrlController.text.trim().isEmpty
            ? null
            : _logoUrlController.text.trim(),
        websiteUrl: _websiteUrlController.text.trim().isEmpty
            ? null
            : _websiteUrlController.text.trim(),
        verificationDocumentUrl:
            _verificationDocumentUrlController.text.trim().isEmpty
                ? null
                : _verificationDocumentUrlController.text.trim(),
      ),
    );

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: ModalFormScaffold(
        title: widget.initialProfile == null
            ? 'Create sponsor profile'
            : 'Edit sponsor profile',
        subtitle:
            'Present a sharper brand profile so organizers can assess fit, credibility, and proposal readiness quickly.',
        icon: Icons.apartment_rounded,
        actionLabel: 'Save profile',
        submittingLabel: 'Saving profile...',
        isSubmitting: widget.isSubmitting,
        onSubmit: _submit,
        children: [
          const ModalFormInfoCard(
            title: 'Brand-first presentation',
            message:
                'Keep the profile tight and visual. Organizers should understand category, trust signals, and website in one pass.',
            icon: Icons.workspace_premium_rounded,
          ),
          ModalFormSection(
            title: 'Company profile',
            subtitle: 'Core brand identity and public details.',
            icon: Icons.badge_rounded,
            child: Column(
              children: [
                _field(_companyNameController, 'Company name'),
                const SizedBox(height: 14),
                _field(_industriesController, 'Industries'),
                const SizedBox(height: 14),
                _field(
                  _websiteUrlController,
                  'Website',
                  keyboardType: TextInputType.url,
                  required: false,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 4,
                  decoration: const InputDecoration(labelText: 'Description'),
                  validator: (value) => value == null || value.trim().length < 20
                      ? 'Use at least 20 characters'
                      : null,
                ),
              ],
            ),
          ),
          ModalFormSection(
            title: 'Brand assets',
            subtitle: 'Logo and verification used in proposals and review.',
            icon: Icons.image_rounded,
            child: Column(
              children: [
                UploadFieldCard(
                  label: 'Logo',
                  accessToken: widget.accessToken,
                  controller: _logoUrlController,
                  kind: UploadAssetKind.image,
                  helper:
                      'Upload the sponsor logo used in opportunity review and profile display.',
                ),
                const SizedBox(height: 14),
                UploadFieldCard(
                  label: 'Verification document',
                  accessToken: widget.accessToken,
                  controller: _verificationDocumentUrlController,
                  kind: UploadAssetKind.document,
                  helper:
                      'Attach a company profile, capabilities deck, or registration document.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    TextInputType? keyboardType,
    bool required = true,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(labelText: label),
      validator: (value) {
        if (!required) {
          return null;
        }
        return value == null || value.trim().isEmpty
            ? '$label is required'
            : null;
      },
    );
  }
}
