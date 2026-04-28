import 'package:flutter/material.dart';
import '../../../events/event_models.dart';
import '../../../sponsors/sponsor_models.dart';
import '../../../widgets/modal_form_scaffold.dart';

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
    return Form(
      key: _formKey,
      child: ModalFormScaffold(
        title: 'Create sponsorship opportunity',
        subtitle:
            'Publish a clean package with audience, budget target, and sponsor value so outreach feels credible.',
        icon: Icons.campaign_rounded,
        actionLabel: 'Create opportunity',
        submittingLabel: 'Creating opportunity...',
        isSubmitting: widget.isSubmitting,
        onSubmit: _submit,
        children: [
          ModalFormSection(
            title: 'Opportunity setup',
            subtitle: 'Anchor the offer to an event and define the target.',
            icon: Icons.event_available_rounded,
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _selectedEventId,
                  decoration: const InputDecoration(labelText: 'Event'),
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
                const SizedBox(height: 14),
                _field(_titleController, 'Opportunity title'),
                const SizedBox(height: 14),
                _field(
                  _requiredAmountController,
                  'Required amount',
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 14),
                _field(_targetAudienceController, 'Target audience'),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: _status,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: const [
                    DropdownMenuItem(value: 'open', child: Text('Open')),
                    DropdownMenuItem(value: 'closed', child: Text('Closed')),
                    DropdownMenuItem(value: 'filled', child: Text('Filled')),
                  ],
                  onChanged: widget.isSubmitting
                      ? null
                      : (value) => setState(() => _status = value ?? 'open'),
                ),
              ],
            ),
          ),
          ModalFormSection(
            title: 'Pitch details',
            subtitle: 'Explain the story, value, and sponsor-facing benefits.',
            icon: Icons.description_rounded,
            child: Column(
              children: [
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 4,
                  decoration: const InputDecoration(labelText: 'Description'),
                  validator: (value) => value == null || value.trim().length < 20
                      ? 'Use at least 20 characters'
                      : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _benefitsController,
                  maxLines: 4,
                  decoration:
                      const InputDecoration(labelText: 'Benefits offered'),
                  validator: (value) => value == null || value.trim().length < 20
                      ? 'Use at least 20 characters'
                      : null,
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
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(labelText: label),
      validator: (value) =>
          value == null || value.trim().isEmpty ? '$label is required' : null,
    );
  }
}
