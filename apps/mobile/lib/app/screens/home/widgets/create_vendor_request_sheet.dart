import 'package:flutter/material.dart';
import '../../../events/event_models.dart';
import '../../../vendors/vendor_models.dart';

class CreateVendorRequestSheet extends StatefulWidget {
  const CreateVendorRequestSheet({
    required this.vendor,
    required this.events,
    required this.isSubmitting,
    required this.onSubmit,
    super.key,
  });

  final VendorProfileModel vendor;
  final List<EventModel> events;
  final bool isSubmitting;
  final Future<void> Function(VendorRequestCreateRequest request) onSubmit;

  @override
  State<CreateVendorRequestSheet> createState() => _CreateVendorRequestSheetState();
}

class _CreateVendorRequestSheetState extends State<CreateVendorRequestSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _messageController;
  late final TextEditingController _budgetController;
  String? _selectedEventId;
  bool _directBookingPreferred = false;

  @override
  void initState() {
    super.initState();
    _messageController = TextEditingController(
      text:
          'We are interested in your services for this event and would like to discuss fit, deliverables, and schedule.',
    );
    _budgetController = TextEditingController(text: '500.00');
    _selectedEventId = widget.events.isEmpty ? null : widget.events.first.id;
    _directBookingPreferred =
        widget.vendor.bookingPreference?.allowDirectBooking == true;
  }

  @override
  void dispose() {
    _messageController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _selectedEventId == null) {
      return;
    }

    await widget.onSubmit(
      VendorRequestCreateRequest(
        eventId: _selectedEventId!,
        message: _messageController.text.trim(),
        proposedBudget: _budgetController.text.trim(),
        directBookingPreferred: _directBookingPreferred,
      ),
    );

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final canDirectBook = widget.vendor.bookingPreference?.allowDirectBooking == true;
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
                'Contact ${widget.vendor.businessName}',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              Text(
                canDirectBook
                    ? 'This vendor allows direct booking. You can either send a request or book immediately.'
                    : 'This vendor is request-based. Send the event details and a proposed budget to start the conversation.',
                style: const TextStyle(color: Color(0xFF5F645F), height: 1.5),
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
              TextFormField(
                controller: _budgetController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Proposed budget',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value == null || value.trim().isEmpty ? 'Budget is required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _messageController,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Message',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value == null || value.trim().length < 20
                    ? 'Use at least 20 characters'
                    : null,
              ),
              if (canDirectBook) ...[
                const SizedBox(height: 8),
                SwitchListTile(
                  value: _directBookingPreferred,
                  onChanged: widget.isSubmitting
                      ? null
                      : (value) => setState(() => _directBookingPreferred = value),
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Book directly if available'),
                ),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: widget.isSubmitting ? null : _submit,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Text(
                      widget.isSubmitting
                          ? 'Submitting...'
                          : canDirectBook && _directBookingPreferred
                              ? 'Book vendor'
                              : 'Send request',
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
}
