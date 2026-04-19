import 'package:flutter/material.dart';
import '../../../events/event_models.dart';
import '../../../sponsors/sponsor_models.dart';

class CreateSponsorshipOpportunitySheet extends StatefulWidget {
  const CreateSponsorshipOpportunitySheet({
    required this.events,
    required this.isSubmitting,
    required this.onSubmit,
    super.key,
  });

  final List<EventModel> events;
  final bool isSubmitting;
  final Future<void> Function(SponsorshipOpportunityCreateRequest request)
      onSubmit;

  @override
  State<CreateSponsorshipOpportunitySheet> createState() =>
      _CreateSponsorshipOpportunitySheetState();
}

class _CreateSponsorshipOpportunitySheetState
    extends State<CreateSponsorshipOpportunitySheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _requiredAmountController;
  late final TextEditingController _targetAudienceController;
  late final TextEditingController _benefitsController;
  String? _selectedEventId;
  String _status = 'open';

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
    _requiredAmountController = TextEditingController(text: '0.00');
    _targetAudienceController = TextEditingController();
    _benefitsController = TextEditingController();
    _selectedEventId = widget.events.isEmpty ? null : widget.events.first.id;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _requiredAmountController.dispose();
    _targetAudienceController.dispose();
    _benefitsController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _selectedEventId == null) {
      return;
    }

    await widget.onSubmit(
      SponsorshipOpportunityCreateRequest(
        eventId: _selectedEventId!,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        requiredAmount: _requiredAmountController.text.trim(),
        targetAudience: _targetAudienceController.text.trim(),
        benefitsOffered: _benefitsController.text.trim(),
        status: _status,
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
              const Text(
                'Create sponsorship opportunity',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              const Text(
                'Publish the audience, budget target, and benefits so sponsors can submit interest against a real event.',
                style: TextStyle(color: Color(0xFF5F645F), height: 1.5),
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                initialValue: _selectedEventId,
                decoration: const InputDecoration(
                  labelText: 'Event',
                  border: OutlineInputBorder(),
                ),
                items: widget.events
                    .map(
                      (event) => DropdownMenuItem<String>(
                        value: event.id,
                        child: Text(event.title),
                      ),
                    )
                    .toList(growable: false),
                onChanged: widget.isSubmitting
                    ? null
                    : (value) => setState(() => _selectedEventId = value),
                validator: (value) =>
                    value == null ? 'Choose an event first' : null,
              ),
              const SizedBox(height: 16),
              _field(_titleController, 'Opportunity title'),
              const SizedBox(height: 16),
              _field(
                _requiredAmountController,
                'Required amount',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 16),
              _field(_targetAudienceController, 'Target audience'),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _status,
                decoration: const InputDecoration(
                  labelText: 'Status',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'open', child: Text('Open')),
                  DropdownMenuItem(value: 'closed', child: Text('Closed')),
                  DropdownMenuItem(value: 'filled', child: Text('Filled')),
                ],
                onChanged: widget.isSubmitting
                    ? null
                    : (value) => setState(() => _status = value ?? 'open'),
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
              TextFormField(
                controller: _benefitsController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Benefits offered',
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
                      widget.isSubmitting
                          ? 'Creating opportunity...'
                          : 'Create opportunity',
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
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      validator: (value) =>
          value == null || value.trim().isEmpty ? '$label is required' : null,
    );
  }
}
