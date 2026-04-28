import 'package:flutter/material.dart';
import '../../../events/event_models.dart';
import '../../../widgets/modal_form_scaffold.dart';

class CreateTicketTypeSheet extends StatefulWidget {
  const CreateTicketTypeSheet({
    required this.onSubmit,
    required this.isSubmitting,
    super.key,
  });

  final Future<void> Function(TicketTypeCreateRequest request) onSubmit;
  final bool isSubmitting;

  @override
  State<CreateTicketTypeSheet> createState() => _CreateTicketTypeSheetState();
}

class _CreateTicketTypeSheetState extends State<CreateTicketTypeSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController(text: '0.00');
  final _quantityController = TextEditingController(text: '50');
  DateTime? _saleStartAt;
  DateTime? _saleEndAt;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now().add(const Duration(hours: 1));
    _saleStartAt = now;
    _saleEndAt = now.add(const Duration(days: 7));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime({required bool isStart}) async {
    final initial = isStart ? _saleStartAt! : _saleEndAt!;
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
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
    final next = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    setState(() {
      if (isStart) {
        _saleStartAt = next;
        if (_saleEndAt != null && !_saleEndAt!.isAfter(next)) {
          _saleEndAt = next.add(const Duration(days: 1));
        }
      } else {
        _saleEndAt = next;
      }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    await widget.onSubmit(
      TicketTypeCreateRequest(
        name: _nameController.text.trim(),
        price: _priceController.text.trim(),
        quantity: int.parse(_quantityController.text.trim()),
        saleStartAt: _saleStartAt!,
        saleEndAt: _saleEndAt!,
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
        title: 'Add ticket type',
        subtitle:
            'Set a clear ticket offer with sale window, quantity, and pricing.',
        icon: Icons.confirmation_number_rounded,
        actionLabel: 'Save ticket',
        submittingLabel: 'Saving ticket...',
        isSubmitting: widget.isSubmitting,
        onSubmit: _submit,
        children: [
          const ModalFormInfoCard(
            title: 'Checkout behavior',
            message:
                'Free tickets can be booked immediately. Paid tickets continue into Stripe checkout.',
            icon: Icons.credit_card_rounded,
          ),
          ModalFormSection(
            title: 'Ticket details',
            subtitle: 'Basics for inventory, pricing, and sales timing.',
            icon: Icons.sell_rounded,
            child: Column(
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Ticket name'),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Name is required'
                      : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _priceController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Price'),
                  validator: (value) {
                    final parsed = double.tryParse(value ?? '');
                    if (parsed == null || parsed < 0) {
                      return 'Enter a valid price';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _quantityController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Quantity'),
                  validator: (value) {
                    final parsed = int.tryParse(value ?? '');
                    if (parsed == null || parsed <= 0) {
                      return 'Enter a positive quantity';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                _DateField(
                  label: 'Sale start',
                  value: _saleStartAt!,
                  onTap: () => _pickDateTime(isStart: true),
                ),
                const SizedBox(height: 12),
                _DateField(
                  label: 'Sale end',
                  value: _saleEndAt!,
                  onTap: () => _pickDateTime(isStart: false),
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
  final DateTime value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
        child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: const Icon(Icons.sell_outlined),
        ),
        child: Text(
          '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')} ${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}',
        ),
      ),
    );
  }
}
