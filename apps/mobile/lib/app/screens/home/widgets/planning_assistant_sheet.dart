import 'package:flutter/material.dart';
import '../../../events/event_models.dart';

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
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 8, 20, bottomInset + 24),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Planning assistant',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              const Text(
                'Generate a practical event-planning brief with vendor coverage, timeline checkpoints, and budget guidance.',
                style: TextStyle(color: Color(0xFF5F645F), height: 1.5),
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String?>(
                initialValue: _selectedEventId,
                decoration: const InputDecoration(
                  labelText: 'Event',
                  border: OutlineInputBorder(),
                ),
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
              const SizedBox(height: 16),
              TextFormField(
                controller: _attendeesController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Expected attendees',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _budgetController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Working budget (USD)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _goalController,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Planning goal',
                  hintText: 'Example: deliver smoother check-in and secure two sponsor leads',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: widget.isSubmitting ? null : _submit,
                  child: Text(widget.isSubmitting ? 'Generating...' : 'Generate brief'),
                ),
              ),
            ],
          ),
        ),
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
