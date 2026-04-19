import 'package:flutter/material.dart';
import '../../../vendors/vendor_models.dart';

class VendorProfileSheet extends StatefulWidget {
  const VendorProfileSheet({
    required this.initialProfile,
    required this.onSubmit,
    required this.isSubmitting,
    super.key,
  });

  final VendorProfileModel? initialProfile;
  final Future<void> Function(VendorProfileUpsertRequest request) onSubmit;
  final bool isSubmitting;

  @override
  State<VendorProfileSheet> createState() => _VendorProfileSheetState();
}

class _VendorProfileSheetState extends State<VendorProfileSheet> {
  late final TextEditingController _businessNameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _categoryController;
  late final TextEditingController _serviceAreaController;
  late bool _allowDirectBooking;
  late bool _allowRequestBooking;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    final profile = widget.initialProfile;
    _businessNameController =
        TextEditingController(text: profile?.businessName ?? '');
    _descriptionController =
        TextEditingController(text: profile?.description ?? '');
    _categoryController = TextEditingController(text: profile?.category ?? '');
    _serviceAreaController =
        TextEditingController(text: profile?.serviceArea ?? '');
    _allowDirectBooking =
        profile?.bookingPreference?.allowDirectBooking ?? false;
    _allowRequestBooking =
        profile?.bookingPreference?.allowRequestBooking ?? true;
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    _serviceAreaController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    await widget.onSubmit(
      VendorProfileUpsertRequest(
        businessName: _businessNameController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _categoryController.text.trim(),
        serviceArea: _serviceAreaController.text.trim(),
        allowDirectBooking: _allowDirectBooking,
        allowRequestBooking: _allowRequestBooking,
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
                    ? 'Create vendor profile'
                    : 'Edit vendor profile',
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              const Text(
                'This profile powers public discovery for organizers looking for vendor support.',
                style: TextStyle(color: Color(0xFF5F645F), height: 1.5),
              ),
              const SizedBox(height: 20),
              _field(_businessNameController, 'Business name'),
              const SizedBox(height: 16),
              _field(_categoryController, 'Category'),
              const SizedBox(height: 16),
              _field(_serviceAreaController, 'Service area'),
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
              const SizedBox(height: 8),
              SwitchListTile(
                value: _allowDirectBooking,
                onChanged: widget.isSubmitting
                    ? null
                    : (value) => setState(() => _allowDirectBooking = value),
                title: const Text('Allow direct booking'),
                contentPadding: EdgeInsets.zero,
              ),
              SwitchListTile(
                value: _allowRequestBooking,
                onChanged: widget.isSubmitting
                    ? null
                    : (value) => setState(() => _allowRequestBooking = value),
                title: const Text('Allow request booking'),
                contentPadding: EdgeInsets.zero,
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

