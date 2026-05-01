import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../../../events/event_models.dart';
import '../../../uploads/upload_models.dart';
import '../../../widgets/location_map_field.dart';
import '../../../widgets/modal_form_scaffold.dart';
import '../../../widgets/upload_field_card.dart';

class CreateEventSheet extends StatefulWidget {
  const CreateEventSheet({
    required this.accessToken,
    required this.categories,
    required this.onSubmit,
    required this.isSubmitting,
    super.key,
  });

  final String accessToken;
  final List<EventCategoryModel> categories;
  final Future<void> Function(EventCreateRequest request) onSubmit;
  final bool isSubmitting;

  @override
  State<CreateEventSheet> createState() => _CreateEventSheetState();
}

class _CreateEventSheetState extends State<CreateEventSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _coverImageUrlController = TextEditingController();
  final _venueController = TextEditingController();
  final _cityController = TextEditingController();
  DateTime? _startAt;
  DateTime? _endAt;
  String? _categoryId;
  bool _publishImmediately = true;
  double? _latitude;
  double? _longitude;
  double _vendorMatchRadiusKm = 60;

  @override
  void initState() {
    super.initState();
    if (widget.categories.isNotEmpty) {
      _categoryId = widget.categories.first.id;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _coverImageUrlController.dispose();
    _venueController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime({required bool isStart}) async {
    final now = DateTime.now();
    final initial = isStart
        ? (_startAt ?? now.add(const Duration(days: 1)))
        : (_endAt ?? (_startAt ?? now.add(const Duration(days: 1))).add(const Duration(hours: 2)));

    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365 * 3)),
    );

    if (date == null || !mounted) {
      return;
    }

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );

    if (time == null || !mounted) {
      return;
    }

    final selected = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );

    setState(() {
      if (isStart) {
        _startAt = selected;
        if (_endAt == null || !_endAt!.isAfter(selected)) {
          _endAt = selected.add(const Duration(hours: 2));
        }
      } else {
        _endAt = selected;
      }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_startAt == null || _endAt == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choose both start and end times')),
      );
      return;
    }

    await widget.onSubmit(
      EventCreateRequest(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        categoryId: _categoryId!,
        venue: _venueController.text.trim(),
        city: _cityController.text.trim(),
        latitude: _latitude,
        longitude: _longitude,
        vendorMatchRadiusKm:
            _latitude != null && _longitude != null ? _vendorMatchRadiusKm : null,
        startAt: _startAt!,
        endAt: _endAt!,
        publishImmediately: _publishImmediately,
        coverImageUrl: _coverImageUrlController.text.trim().isEmpty
            ? null
            : _coverImageUrlController.text.trim(),
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
        title: 'Create event',
        subtitle: 'Set the event details, cover image, and location.',
        icon: Icons.event_note_rounded,
        actionLabel: 'Save event',
        submittingLabel: 'Saving event...',
        isSubmitting: widget.isSubmitting,
        onSubmit: _submit,
        children: [
          ModalFormSection(
            title: 'Core details',
            icon: Icons.badge_rounded,
            child: Column(
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: 'Title'),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Title is required'
                      : null,
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: _categoryId,
                  items: widget.categories
                      .map(
                        (category) => DropdownMenuItem<String>(
                          value: category.id,
                          child: Text(category.name),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: widget.isSubmitting
                      ? null
                      : (value) {
                          if (value != null) {
                            setState(() => _categoryId = value);
                          }
                        },
                  decoration: const InputDecoration(labelText: 'Category'),
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
            title: 'Media and venue',
            icon: Icons.image_rounded,
            child: Column(
              children: [
                UploadFieldCard(
                  label: 'Cover image',
                  accessToken: widget.accessToken,
                  controller: _coverImageUrlController,
                  kind: UploadAssetKind.image,
                  helper:
                      'Upload the event banner that should appear across event listings and detail views.',
                  previewHeight: 160,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _venueController,
                  decoration: const InputDecoration(labelText: 'Venue'),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Venue is required'
                      : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _cityController,
                  decoration: const InputDecoration(labelText: 'City'),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'City is required'
                      : null,
                ),
              ],
            ),
          ),
          ModalFormSection(
            title: 'Location and timing',
            icon: Icons.place_rounded,
            child: Column(
              children: [
                LocationMapField(
                  label: 'Event map location',
                  helper:
                      'Tap the map to place the venue area. Meloo uses this point to sort nearby vendors for the event.',
                  radiusLabel: 'Vendor match radius',
                  initialLatitude: _latitude,
                  initialLongitude: _longitude,
                  initialRadiusKm: _vendorMatchRadiusKm,
                  defaultCenter: const LatLng(27.7172, 85.3240),
                  onChanged: (selection) {
                    _latitude = selection.latitude;
                    _longitude = selection.longitude;
                    _vendorMatchRadiusKm = selection.radiusKm;
                  },
                ),
                const SizedBox(height: 14),
                _DateField(
                  label: 'Start',
                  value: _startAt,
                  onTap: () => _pickDateTime(isStart: true),
                ),
                const SizedBox(height: 12),
                _DateField(
                  label: 'End',
                  value: _endAt,
                  onTap: () => _pickDateTime(isStart: false),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  value: _publishImmediately,
                  onChanged: widget.isSubmitting
                      ? null
                      : (value) => setState(() => _publishImmediately = value),
                  title: const Text('Publish immediately'),
                  subtitle: const Text(
                    'Turn this off to save the event as a draft.',
                  ),
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final DateTime? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: const Icon(Icons.calendar_today_outlined),
        ),
        child: Text(
          value == null
              ? 'Choose date and time'
              : '${value!.year}-${value!.month.toString().padLeft(2, '0')}-${value!.day.toString().padLeft(2, '0')} ${value!.hour.toString().padLeft(2, '0')}:${value!.minute.toString().padLeft(2, '0')}',
        ),
      ),
    );
  }
}
