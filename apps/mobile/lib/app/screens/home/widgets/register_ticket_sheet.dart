import 'package:flutter/material.dart';
import '../../../events/event_models.dart';
import '../../../widgets/modal_form_scaffold.dart';

class RegisterTicketSheet extends StatefulWidget {
  const RegisterTicketSheet({
    required this.ticketType,
    required this.onSubmit,
    required this.isSubmitting,
    super.key,
  });

  final TicketTypeModel ticketType;
  final Future<void> Function(int quantity) onSubmit;
  final bool isSubmitting;

  @override
  State<RegisterTicketSheet> createState() => _RegisterTicketSheetState();
}

class _RegisterTicketSheetState extends State<RegisterTicketSheet> {
  int _quantity = 1;

  @override
  Widget build(BuildContext context) {
    final maxQuantity = widget.ticketType.remaining < 5
        ? widget.ticketType.remaining
        : 5;
    final navigator = Navigator.of(context);

    return ModalFormScaffold(
      title: 'Register for ${widget.ticketType.name}',
      subtitle: widget.ticketType.isFree
          ? 'This is a free ticket, so registration confirms immediately.'
          : 'This ticket continues into Stripe Checkout so payment finishes on a hosted page.',
      icon: Icons.local_activity_rounded,
      actionLabel:
          widget.ticketType.isFree ? 'Confirm registration' : 'Continue to Stripe',
      submittingLabel: 'Submitting...',
      isSubmitting: widget.isSubmitting,
      onSubmit: () async {
        await widget.onSubmit(_quantity);
        if (mounted) {
          navigator.pop();
        }
      },
      children: [
        if (!widget.ticketType.isFree)
          ModalFormInfoCard(
            title: 'Order total',
            message:
                'Current total: ${(double.parse(widget.ticketType.price) * _quantity).toStringAsFixed(2)}',
            icon: Icons.payments_rounded,
            tint: const Color(0xFFEAF5EF),
            iconColor: const Color(0xFF246B4F),
          ),
        ModalFormSection(
          title: 'Quantity',
          subtitle: 'Choose how many tickets to reserve in this order.',
          icon: Icons.pin_rounded,
          child: DropdownButtonFormField<int>(
            initialValue: _quantity,
            items: List.generate(
              maxQuantity,
              (index) => DropdownMenuItem<int>(
                value: index + 1,
                child: Text('${index + 1} ticket${index == 0 ? '' : 's'}'),
              ),
            ),
            onChanged: widget.isSubmitting
                ? null
                : (value) {
                    if (value != null) {
                      setState(() => _quantity = value);
                    }
                  },
            decoration: const InputDecoration(labelText: 'Quantity'),
          ),
        ),
      ],
    );
  }
}
