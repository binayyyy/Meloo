import 'package:flutter/material.dart';
import '../../../sponsors/sponsor_models.dart';

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
                'Express interest in ${widget.opportunity.title}',
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              Text(
                'Event: ${widget.opportunity.event.title}',
                style: const TextStyle(
                  color: Color(0xFF5F645F),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _messageController,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Message to organizer',
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
                          ? 'Submitting interest...'
                          : 'Submit interest',
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
