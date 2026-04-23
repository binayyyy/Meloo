import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../../../vendors/vendor_models.dart';
import '../../../uploads/upload_models.dart';
import '../../../widgets/location_map_field.dart';
import '../../../widgets/upload_field_card.dart';

class VendorProfileSheet extends StatefulWidget {
  const VendorProfileSheet({
    required this.accessToken,
    required this.initialProfile,
    required this.onSubmit,
    required this.isSubmitting,
    super.key,
  });

  final String accessToken;
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
  late final TextEditingController _portfolioImageUrlController;
  late final TextEditingController _verificationDocumentUrlController;
  late bool _allowDirectBooking;
  late bool _allowRequestBooking;
  final _formKey = GlobalKey<FormState>();
  double? _latitude;
  double? _longitude;
  double _travelRadiusKm = 80;

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
    _latitude = profile?.latitude;
    _longitude = profile?.longitude;
    _travelRadiusKm = profile?.travelRadiusKm ?? 80;
    _portfolioImageUrlController = TextEditingController(
      text: profile?.portfolioImageUrl ?? '',
    );
    _verificationDocumentUrlController = TextEditingController(
      text: profile?.verificationDocumentUrl ?? '',
    );
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
    _portfolioImageUrlController.dispose();
    _verificationDocumentUrlController.dispose();
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
        latitude: _latitude,
        longitude: _longitude,
        travelRadiusKm:
            _latitude != null && _longitude != null ? _travelRadiusKm : null,
        portfolioImageUrl: _portfolioImageUrlController.text.trim().isEmpty
            ? null
            : _portfolioImageUrlController.text.trim(),
        verificationDocumentUrl:
            _verificationDocumentUrlController.text.trim().isEmpty
                ? null
                : _verificationDocumentUrlController.text.trim(),
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
              const SizedBox(height: 10),
              const Text(
                'Set your location on the map so Meloo can match you to organizer demand by real distance.',
                style: TextStyle(color: Color(0xFF7A7369), height: 1.5),
              ),
              const SizedBox(height: 20),
              _field(_businessNameController, 'Business name'),
              const SizedBox(height: 16),
              _field(_categoryController, 'Category'),
              const SizedBox(height: 16),
              _field(_serviceAreaController, 'Service area'),
              const SizedBox(height: 16),
              LocationMapField(
                label: 'Vendor base location',
                helper:
                    'Tap the map to set your main operating base. The travel radius slider controls how far you are willing to work.',
                radiusLabel: 'Travel radius',
                initialLatitude: _latitude,
                initialLongitude: _longitude,
                initialRadiusKm: _travelRadiusKm,
                defaultCenter: const LatLng(27.7172, 85.3240),
                onChanged: (selection) {
                  _latitude = selection.latitude;
                  _longitude = selection.longitude;
                  _travelRadiusKm = selection.radiusKm;
                },
              ),
              const SizedBox(height: 16),
              UploadFieldCard(
                label: 'Portfolio image',
                accessToken: widget.accessToken,
                controller: _portfolioImageUrlController,
                kind: UploadAssetKind.image,
                helper:
                    'Show organizers the strongest visual proof of your work.',
              ),
              const SizedBox(height: 16),
              UploadFieldCard(
                label: 'Verification document',
                accessToken: widget.accessToken,
                controller: _verificationDocumentUrlController,
                kind: UploadAssetKind.document,
                helper:
                    'Upload a registration, license, deck, or capability document for review.',
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
