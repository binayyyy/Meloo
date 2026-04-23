import 'package:flutter/material.dart';
import '../../../sponsors/sponsor_models.dart';
import '../../../uploads/upload_models.dart';
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
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.initialProfile == null
                    ? 'Create sponsor profile'
                    : 'Edit sponsor profile',
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              const Text(
                'This profile helps organizers assess brand fit before they review your interest.',
                style: TextStyle(color: Color(0xFF5F645F), height: 1.5),
              ),
              const SizedBox(height: 20),
              _field(_companyNameController, 'Company name'),
              const SizedBox(height: 16),
              _field(_industriesController, 'Industries'),
              const SizedBox(height: 16),
              _field(
                _websiteUrlController,
                'Website',
                keyboardType: TextInputType.url,
                required: false,
              ),
              const SizedBox(height: 16),
              UploadFieldCard(
                label: 'Logo',
                accessToken: widget.accessToken,
                controller: _logoUrlController,
                kind: UploadAssetKind.image,
                helper:
                    'Upload the sponsor logo used in opportunity review and profile display.',
              ),
              const SizedBox(height: 16),
              UploadFieldCard(
                label: 'Verification document',
                accessToken: widget.accessToken,
                controller: _verificationDocumentUrlController,
                kind: UploadAssetKind.document,
                helper:
                    'Attach a company profile, capabilities deck, or registration document.',
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value == null || value.trim().length < 20
                    ? 'Use at least 20 characters'
                    : null,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: widget.isSubmitting ? null : _submit,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Text(
                      widget.isSubmitting ? 'Saving profile...' : 'Save profile',
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
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
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
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
