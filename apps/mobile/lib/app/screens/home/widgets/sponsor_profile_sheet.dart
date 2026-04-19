import 'package:flutter/material.dart';
import '../../../sponsors/sponsor_models.dart';

class SponsorProfileSheet extends StatefulWidget {
  const SponsorProfileSheet({
    required this.initialProfile,
    required this.onSubmit,
    required this.isSubmitting,
    super.key,
  });

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
  }

  @override
  void dispose() {
    _companyNameController.dispose();
    _descriptionController.dispose();
    _industriesController.dispose();
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

  Widget _field(TextEditingController controller, String label) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      validator: (value) =>
          value == null || value.trim().isEmpty ? '$label is required' : null,
    );
  }
}
