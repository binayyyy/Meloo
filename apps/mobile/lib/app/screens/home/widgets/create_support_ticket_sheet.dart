import 'package:flutter/material.dart';
import '../../../support/support_models.dart';
import '../../../widgets/modal_form_scaffold.dart';

class CreateSupportTicketSheet extends StatefulWidget {
  const CreateSupportTicketSheet({
    required this.isSubmitting,
    required this.onSubmit,
    super.key,
  });

  final bool isSubmitting;
  final Future<void> Function(CreateSupportTicketRequest request) onSubmit;

  @override
  State<CreateSupportTicketSheet> createState() =>
      _CreateSupportTicketSheetState();
}

class _CreateSupportTicketSheetState extends State<CreateSupportTicketSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _subjectController;
  late final TextEditingController _descriptionController;
  String _category = 'general';

  @override
  void initState() {
    super.initState();
    _subjectController = TextEditingController();
    _descriptionController = TextEditingController();
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    await widget.onSubmit(
      CreateSupportTicketRequest(
        category: _category,
        subject: _subjectController.text.trim(),
        description: _descriptionController.text.trim(),
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
        title: 'Create support ticket',
        subtitle:
            'Describe the issue clearly so the assistant can triage it fast and escalate when needed.',
        icon: Icons.support_agent_rounded,
        actionLabel: 'Create ticket',
        submittingLabel: 'Creating ticket...',
        isSubmitting: widget.isSubmitting,
        onSubmit: _submit,
        children: [
          ModalFormSection(
            title: 'Issue details',
            subtitle: 'Choose the right lane and keep the report specific.',
            icon: Icons.report_problem_rounded,
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _category,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: const [
                    DropdownMenuItem(value: 'general', child: Text('General')),
                    DropdownMenuItem(value: 'booking', child: Text('Booking')),
                    DropdownMenuItem(value: 'payment', child: Text('Payment')),
                    DropdownMenuItem(value: 'account', child: Text('Account')),
                    DropdownMenuItem(value: 'technical', child: Text('Technical')),
                    DropdownMenuItem(value: 'harassment', child: Text('Harassment')),
                  ],
                  onChanged: widget.isSubmitting
                      ? null
                      : (value) => setState(() => _category = value ?? 'general'),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _subjectController,
                  decoration: const InputDecoration(labelText: 'Subject'),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Subject is required'
                      : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 5,
                  decoration: const InputDecoration(labelText: 'Description'),
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
}
