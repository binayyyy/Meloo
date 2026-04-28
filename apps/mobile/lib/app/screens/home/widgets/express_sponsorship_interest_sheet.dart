import 'package:flutter/material.dart';
import '../../../sponsors/sponsor_models.dart';
import '../../../widgets/modal_form_scaffold.dart';

class ExpressSponsorshipInterestSheet extends StatefulWidget {
  const ExpressSponsorshipInterestSheet({
    required this.opportunity,
    required this.onSubmit,
    required this.isSubmitting,
    super.key,
  });

  final SponsorshipOpportunityModel opportunity;
  final Future<void> Function(SponsorshipInterestCreateRequest request) onSubmit;
  final bool isSubmitting;

  @override
  State<ExpressSponsorshipInterestSheet> createState() =>
      _ExpressSponsorshipInterestSheetState();
}

class _ExpressSponsorshipInterestSheetState
    extends State<ExpressSponsorshipInterestSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _messageController;

  @override
  void initState() {
    super.initState();
    _messageController = TextEditingController(
      text:
          'We are interested in supporting ${widget.opportunity.event.title} and would like to discuss fit, deliverables, and next steps.',
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    await widget.onSubmit(
      SponsorshipInterestCreateRequest(
        message: _messageController.text.trim(),
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
        title: 'Express interest',
        subtitle:
            'Send a concise sponsor note for ${widget.opportunity.title} tied to ${widget.opportunity.event.title}.',
        icon: Icons.favorite_border_rounded,
        actionLabel: 'Submit interest',
        submittingLabel: 'Submitting interest...',
        isSubmitting: widget.isSubmitting,
        onSubmit: _submit,
        children: [
          ModalFormInfoCard(
            title: widget.opportunity.event.title,
            message:
                'Use this note to show fit, sponsorship intent, and why your brand belongs in the event mix.',
            icon: Icons.event_rounded,
          ),
          ModalFormSection(
            title: 'Message to organizer',
            subtitle: 'Keep it specific enough to justify a response.',
            icon: Icons.chat_bubble_outline_rounded,
            child: TextFormField(
              controller: _messageController,
              maxLines: 5,
              decoration: const InputDecoration(labelText: 'Message'),
              validator: (value) => value == null || value.trim().length < 20
                  ? 'Use at least 20 characters'
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}
