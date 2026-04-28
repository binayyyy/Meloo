import 'package:flutter/material.dart';
import '../../../events/event_models.dart';
import '../../../widgets/modal_form_scaffold.dart';

class PlanningAssistantRequest {
  const PlanningAssistantRequest({
    required this.eventId,
    required this.expectedAttendees,
    required this.budget,
    required this.planningGoal,
  });

  final String? eventId;
  final int? expectedAttendees;
  final String? budget;
  final String? planningGoal;
}

class PlanningAssistantSheet extends StatefulWidget {
  const PlanningAssistantSheet({
    required this.events,
    required this.isSubmitting,
    required this.onSubmit,
    super.key,
  });

  final List<EventModel> events;
  final bool isSubmitting;
  final Future<void> Function(PlanningAssistantRequest request) onSubmit;

  @override
  State<PlanningAssistantSheet> createState() => _PlanningAssistantSheetState();
}

class _PlanningAssistantSheetState extends State<PlanningAssistantSheet> {
  final _formKey = GlobalKey<FormState>();
  final _attendeesController = TextEditingController();
  final _budgetController = TextEditingController();
  final _goalController = TextEditingController();
  String? _selectedEventId;

  @override
  void initState() {
    super.initState();
    _selectedEventId = widget.events.isEmpty ? null : widget.events.first.id;
  }

  @override
  void dispose() {
    _attendeesController.dispose();
    _budgetController.dispose();
    _goalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: ModalFormScaffold(
        title: 'Planning assistant',
        subtitle:
            'Generate a practical brief with vendor coverage, budget guidance, and timeline checkpoints.',
        icon: Icons.auto_awesome_rounded,
        actionLabel: 'Generate brief',
        submittingLabel: 'Generating...',
        isSubmitting: widget.isSubmitting,
        onSubmit: _submit,
        children: [
          const ModalFormInfoCard(
            title: 'AI planning input',
            message:
                'The better the event context, budget, and goal, the stronger the generated plan will be.',
            icon: Icons.psychology_alt_rounded,
          ),
          ModalFormSection(
            title: 'Planning context',
            subtitle: 'Optional details help the assistant tailor the brief.',
            icon: Icons.fact_check_rounded,
            child: Column(
              children: [
                DropdownButtonFormField<String?>(
                  initialValue: _selectedEventId,
                  decoration: const InputDecoration(labelText: 'Event'),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('No linked event'),
                    ),
                    ...widget.events.map(
                      (event) => DropdownMenuItem<String?>(
                        value: event.id,
                        child: Text(event.title),
                      ),
                    ),
                  ],
                  onChanged: widget.isSubmitting
                      ? null
                      : (value) => setState(() => _selectedEventId = value),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _attendeesController,
                  keyboardType: TextInputType.number,
                  decoration:
                      const InputDecoration(labelText: 'Expected attendees'),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _budgetController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration:
                      const InputDecoration(labelText: 'Working budget (USD)'),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _goalController,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Planning goal',
                    hintText:
                        'Example: smoother check-in and two sponsor leads',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final attendees = int.tryParse(_attendeesController.text.trim());
    final budget = _budgetController.text.trim();
    final goal = _goalController.text.trim();

    await widget.onSubmit(
      PlanningAssistantRequest(
        eventId: _selectedEventId,
        expectedAttendees: attendees,
        budget: budget.isEmpty ? null : budget,
        planningGoal: goal.isEmpty ? null : goal,
      ),
    );

    if (mounted) {
      Navigator.of(context).pop();
    }
  }
}
