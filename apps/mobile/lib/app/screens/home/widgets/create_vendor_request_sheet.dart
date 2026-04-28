import 'package:flutter/material.dart';
import '../../../events/event_models.dart';
import '../../../vendors/vendor_models.dart';
import '../../../widgets/modal_form_scaffold.dart';

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
    final canDirectBook =
        widget.vendor.bookingPreference?.allowDirectBooking == true;
    return Form(
      key: _formKey,
      child: ModalFormScaffold(
        title: 'Contact ${widget.vendor.businessName}',
        subtitle: canDirectBook
            ? 'This vendor supports direct booking, so you can move from request to confirmation faster.'
            : 'This vendor uses request review. Share the event context and budget to start the conversation.',
        icon: Icons.handshake_rounded,
        actionLabel:
            canDirectBook && _directBookingPreferred ? 'Book vendor' : 'Send request',
        submittingLabel: 'Submitting...',
        isSubmitting: widget.isSubmitting,
        onSubmit: _submit,
        children: [
          ModalFormSection(
            title: 'Event and budget',
            subtitle: 'Link the right event and set the working spend.',
            icon: Icons.event_rounded,
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
                TextFormField(
                  controller: _budgetController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Proposed budget'),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Budget is required'
                      : null,
                ),
              ],
            ),
          ),
          ModalFormSection(
            title: 'Message',
            subtitle: 'Keep the note specific enough for a confident reply.',
            icon: Icons.chat_bubble_outline_rounded,
            child: Column(
              children: [
                TextFormField(
                  controller: _messageController,
                  maxLines: 5,
                  decoration: const InputDecoration(labelText: 'Message'),
                  validator: (value) => value == null || value.trim().length < 20
                      ? 'Use at least 20 characters'
                      : null,
                ),
                if (canDirectBook) ...[
                  const SizedBox(height: 14),
                  ModalFormToggleTile(
                    title: 'Book directly if available',
                    subtitle:
                        'Use the vendor’s direct-booking path when the offer matches your needs.',
                    value: _directBookingPreferred,
                    onChanged: widget.isSubmitting
                        ? null
                        : (value) =>
                              setState(() => _directBookingPreferred = value),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
